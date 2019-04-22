js_server: ruby -run -e httpd app/assets/javascripts/react-app.js -p 3501
rails: JAVASCRIPT_URL=http://localhost:3501 bundle exec rails s -p 3001
client: cd client && yarn run dev:watch
shoryuken: bundle exec shoryuken start -q efolder_development_high_priority efolder_development_med_priority efolder_development_low_priority -R
