# eFolder Express v2 endpoints

When calling API ednpoints using authenticatation token, certain headers are required: CSS_ID and STATION_ID

1. To start downloading manifest asynchronously:

```
# required header: FILE_NUMBER
POST "/api/v2/manifests", to: "manifests#start"
```

2. To check the status of the manifest:

```
# required header: FILE_NUMBER
GET "/api/v2/manifests", to: "manifests#progress"
```

3. To start downloading files to s3 and package them into a zip file asynchronously:

```
POST "/api/v2/manifests/:manifest_id/files_downloads", to: "files_downloads#start"
```

4. To check the status of the files download:

```
GET "/api/v2/manifests/:manifest_id/files_downloads", to: "files_downloads#progress"
```

5. To get document content (version_id cannot contain curly braces):

```
GET /api/v2/records/:version_id, to "records#show"
```

6. To download manifest zip:

```
GET "/api/v2/manifests/:manifest_id/zip", to: "files_downloads#zip"
```

7. To view current user's download history:

```
GET "/api/v2/manifests/history", to: "manifests#history"
```


