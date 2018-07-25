# Caseflow - eFolder Express
[![Build Status](https://travis-ci.org/department-of-veterans-affairs/caseflow-efolder.svg?branch=master)](https://travis-ci.org/department-of-veterans-affairs/caseflow-efolder)

## About

FOIA Requests that give veterans access to their own VA files take **way** too long right now. eFolder Express allows VA employees to download all of a veteran's files in a fraction of the time it currently takes. It will also enable attorneys in the appeals process to use best-in-class legal tools to review these documents and so they can provide excellent service to America's veterans.

![](screenshot.png "eFolder Express")

## Start up your docker based environment

We use [docker](https://docs.docker.com/) and [docker-compose](https://docs.docker.com/compose/) to mock a production environment locally.  Prior knowledge of docker is not required, but slowly learning how docker works is encouraged.
Please ask a team member for an overview, and/or slowly review the docs linked.

Your development setup of caseflow currently runs Redis, postgres and OracleDB (VACOLS) in Docker.

Setup your postgres user.  Run this in your CLI, or better yet, add this to your shell configuration `~/.bashrc`

```
export POSTGRES_HOST=localhost
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=postgres
```

**Note: If you previously have had redis and postgres installed via brew and would like to switch to docker, do the following:**
```
brew services stop postgresql
brew services stop redis
```

Start all containers
```
docker-compose up -d
# run without -d to start your environment and view container logging in the foreground

docker-compose ps
# this shows you the status of all of your dependencies
```

Turning off dependencies
```
# this stops all containers
docker-compose down

# this will reset your setup back to scratch. You will need to setup your database schema again if you do this (see below)
docker-compose down -v
```

## First Time Development Setup

You'll need Ruby 2.3.0 if you don't have it.

> $ rbenv install 2.3.0

Install dependencies

> $ bundle install

Create the database

> $ rake db:create

Load the schema

> $ rake db:schema:load

Now start both the rails server,

> $ rails s

In a separate terminal, watch for webpack changes

> $ cd client && yarn run build --watch

And in another separate terminal, start a jobs worker

> $ bundle exec shoryuken start -q efolder_development_high_priority efolder_development_low_priority efolder_development_med_priority -R

If you want to convert TIFF files to PDFs then you also need to run the image converter service. You can
do this by cloning the appeals-deployment repo, navigating to `ansible/utility-roles/imagemagick/files`
and running `docker-compose up`. By default if this is not running, TIFFs will gracefully not convert.

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

Finally, you can run the server and shoryuken. In one tab you can run:

> $ rails s -e staging

In a separate tab run:

> $ RAILS_ENV=staging bundle exec shoryuken start -q efolder_staging_high_priority efolder_staging_low_priority efolder_staging_med_priority -R

Now when you go to [localhost:3000](localhost:3000) you'll be prompted with a fake login screen. Use any of these [logins](https://github.com/department-of-veterans-affairs/appeals-qa/blob/master/TestData/LOGINS.md) to impersonate a UAT user.
