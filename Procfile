js_server: ruby -run -e httpd app/assets/javascripts/react-app.js -p 3500
rails: JAVASCRIPT_URL=http://localhost:3500 rails s
client: HOT_RAILS_PORT=3500 cd client && yarn run dev:hot
