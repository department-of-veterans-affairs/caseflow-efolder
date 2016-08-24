# Caseflow - eFolder Express
[![Build Status](https://travis-ci.org/department-of-veterans-affairs/caseflow-efolder.svg?branch=master)](https://travis-ci.org/department-of-veterans-affairs/caseflow-efolder)

Download all case files with ease!

## First Time Development Setup

Install dependencies

> $ bundle install

Create the database

> $ rake db:migrate

You'll also need to install `redis`. Follow the post-install instructions
to start the redis server.

> $ brew install redis

Now start both the rails server,

> $ rails s

And in a seperate terminal, start a jobs worker

> $ bundle exec sidekiq

If you want to test out the DEMO flow (without VBMS connection), 

Visit [http://localhost:3000](),  
Type in a file number with "DEMO" in it. (ie: "DEMO123")  
Watch it download your fake file.


### Setting up VBMS

TODO: fill this out
You'll need to add all the VBMS info to your `config/secrets.yml`.
