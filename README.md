# Caseflow - eFolder Express
[![Build Status](https://travis-ci.org/department-of-veterans-affairs/caseflow-efolder.svg?branch=master)](https://travis-ci.org/department-of-veterans-affairs/caseflow-efolder)

Download all case files with ease!

## First Time Development Setup

### Ruby Setup

Install rbenv, which is a tool that helps install/manage versions of Ruby (Note: make sure and follow the brew's post-install instructions):

> $ brew install rbenv

And follow the initialization instructions for rbenv, provided by brew

> $ rbenv init

Using rbenv install ruby:

> $ rbenv install jruby-9.0.3.0

Install bundle, which will help download/manage Ruby dependencies:

> $ gem install bundler

Then use it to install dependencies:

> $ bundle install

### Development setup

First you'll need to create the database

> $ rake db:migrate

Now start both the rails server,

> $ rails s

And in a seperate terminal, start a jobs worker

> $ rake jobs:work

If you want to test out the DEMO flow (without VBMS connection), 

Visit [http://localhost:3000](),  
Type in a file number with "DEMO" in it. (ie: "DEMO123")  
Watch it download your fake file.


### Setting up VBMS

TODO: fill this out
You'll need to add all the VBMS info to your `config/secrets.yml`.
