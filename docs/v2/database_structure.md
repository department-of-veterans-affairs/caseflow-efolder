# Context

When working on the eFolder Express integration we uncovered several architectural decisions that made future extensibility difficult. The main obstacle was that the Download and Document tables both contained data from VBMS/VVA as well as maintained values that were specific to each instance of a user interacting with the system. When a user searches for a veteran id we look for a download record from the last three days. If such a record doesn't exist, then a new one is created. Each download object has its own document objects associated with it. This means that downloads done outside of the three days are recreated in the DB, and downloads of the same veteran id but by different users are held in different records. This means that all of the data about the download and documents from VBMS are duplicated as we try to keep track of all the fields that are specific to an individual interaction with the app such as the time it took to download and whether or not those downloads were successful.


# Overview

We propose separating these two functions in the database. The Download table will contain exactly one entry for each veteran id. The Document table will contain exactly one entry for each document in the veteran's file. Then separate tables will maintain the specific information about every user interaction with the system.

We think this structure has three main advantages:

1) StaleObjectErrors: eFolder has had a number of StaleObjectErrors in Sentry. This is partly due to having a complex architecture with several threads all trying to access DB entries at once. However, if we separate the actual data of the entry from the audit functions, we should be able to reduce these. It's the audit side of the tables that are usually in conflict, but if we aren't limited to one Download row and instead have several audit rows then we can create new audit entries for each user's download and avoid trying to write to them at the same time.

1) Store Less Data: We are needlessly duplicating data in our DB. It seems that where possible we should reduce the number of rows in our tables.

1) Better Caching: Now that we have implemented the API endpoints we've increased the instances when two people are going to be looking at the same Download around the same time. If attorney A and judge B want to both view the same case it would be ideal for them to be able to share the same download object so that fetching the data can avoid a call to VBMS.

1) Easier Reasoning About Data: With this model we can impose uniqueness constraints on our tables. No two downloads can have the same veteran id. No two documents can have the same document id. These constraints allow us to replace fuzzier `wheres` with concrete `finds`.


# Things to consider:

1) We will start with the simplest solution possible.
2) We will deprecate eX stats page so we will not worry about it at this point. We will work with Chris Given to determine the value of the stats page and we will work with Alan Ning to find tools that can accoplish the same task.
3) Table names are different from the previous version. This will make it easier to create new models/DB tables without conflicts.
4) We will deprecate `searches` table.
5) We don't need to expire `manifests`. We will have `user_manifests` and `records` tables that will have all the necessary information to answer questions such as "this user downloaded XYZ documents on XXX date".


# Tables

```
  create_table "manifests" |t|
    t.string   "file_number"
    t.string   "veteran_last_name"
    t.string   "veteran_first_name"
    t.string   "veteran_last_four_ssn"
    t.zipfile_size,                 # The value will be updated based on the changes to the documents
    t.datetime "created_at",
    t.datetime "updated_at",
  end
```

```
  # Having this separately will allow us to start fetching manifests in parallel
  create_table "manifest_statuses" |t|
    t.integer  "manifest_id"
    t.integer  "status",            # Values: success, failed, pending
    t.string "source"               # "VBMS" or "VVA"
    t.datetime "fetched_at"         # We will use this field to determine if manifest has expired
    t.datetime "created_at",
    t.datetime "updated_at",
  end
```

```
# For audit purposes, both the API and the UI will use this table.
  create_table "user_manifests" |t|
    t.integer  "manifest_id"
    t.integer  "user_id"
    t.integer  "status",         # UI specific statuses: fetching_manifest, no_documents, etc
    t.datetime "created_at",     # We can use this field to display user's history in the UI
    t.datetime "updated_at",
  end
```

```
 create_table "records" do |t|
    t.integer  "manifest_id"
    t.integer  "status",  default: 0
    t.string   "external_document_id"
    t.string   "mime_type"
    t.datetime "received_at"          # VBMS and VVA timestamp
    t.string   "type_description"
    t.string   "type_id"              # It will be deprecated when we move to the VBMS new eFolder API
    t.integer  "size"                 # This field is used to keep track of document sizes
    t.string   "vva_jro"              # VVA metadata to download document content
    t.string   "vva_source"           # VVA metadata to download document content
    t.datetime "created_at",
    t.datetime "updated_at",
  end
```

# Implementation Steps

1) Create our new DB structure with associated models
2) Point the API to this new code
3) Eventually deprecate the UI and point whatever rises from the ashes to the API
4) Leave the old DB tables, but don’t try to migrate them
