# Caseflow - eFolder Express
[![Build Status](https://travis-ci.org/department-of-veterans-affairs/caseflow-efolder.svg?branch=master)](https://travis-ci.org/department-of-veterans-affairs/caseflow-efolder)

## About

FOIA Requests that give veterans access to their own VA files take **way** too long right now. eFolder Express allows VA employees to download all of a veteran's files in a fraction of the time it currently takes. It will also enable attorneys in the appeals process to use best-in-class legal tools to review these documents and so they can provide excellent service to America's veterans.

![](screenshot.png "eFolder Express")

## First Time Development Setup

You'll need Ruby 2.3.0, Postgres, and Redis if you don't have them.

> $ rbenv install 2.3.0

> $ brew install postgresql

> $ brew install redis

You may want to have Redis and Postgres run on startup. Let brew tell you how to do that:

> $ brew info redis

> $ brew info postgresql

Install dependencies

> $ bundle install

Create the database

> $ rake db:create

Load the schema

> $ rake db:schema:load

Now start both the rails server,

> $ rails s

And in a seperate terminal, start a jobs worker

> $ bundle exec sidekiq

If you want to test out the DEMO flow (without VBMS connection),

Visit [http://localhost:3000](),
Type in a file number with "DEMO" in it. (ie: "DEMO123")
Watch it download your fake file.

## Running Migrations

If a pending migration exists, you will need to run them against both the development and test database:

> $ rake db:migrate

> $ RAILS_ENV=test rake db:migrate

## Running Tests

In order to run tests, you will first need to globally install phantomJS

> $ (sudo) npm install -g phantomjs

Then to run the test suite:

> $ rake

## Monitoring
We use NewRelic to monitor the app. By default, it's disabled locally. To enable it, do:

```
NEW_RELIC_LICENSE_KEY='<key as displayed on NewRelic.com>' NEW_RELIC_AGENT_ENABLED=true bundle exec rails s
```

You may wish to do this if you are debugging our NewRelic integration, for instance.


### Run connected to UAT

First, you'll need a VA machine. Next, you'll need the secrets file. These come from the appeals deployment repo. Run [decrypt.sh](https://github.com/department-of-veterans-affairs/appeals-deployment/blob/master/decrypt.sh) and source the appropriate secrets environment.

Then you must setup the staging DB. Run:

> $ RAILS_ENV=staging rake db:create
> $ RAILS_ENV=staging rake db:schema:load

Finally, you can run the server and sidekiq. In one tab you can run:

> $ rails s -e staging

In a separate tab run:

> $ RAILS_ENV=staging bundle exec sidekiq

Now when you go to [localhost:3000](localhost:3000) you'll be prompted with a fake login screen. Use any of these [logins](https://github.com/department-of-veterans-affairs/appeals-qa/blob/master/TestData/LOGINS.md) to impersonate a UAT user.
