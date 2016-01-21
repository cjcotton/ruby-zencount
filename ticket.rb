#!/usr/bin/env ruby
# Written by: Courtney Cotton, 1-19-2016
# Purpose
# This script is designed to get a count of open tickets.
# Resources
# Datadog Ruby API: http://docs.datadoghq.com/api/
# Zendesk Ruby API: http://zendesk.github.io/zendesk_api_client_rb/
# References
# https://github.com/zendesk/zendesk_api_cookbooks/tree/master/Zendesk-API-Client-Examples/ruby
# https://developer.zendesk.com/rest_api/docs/core/views

require 'rubygems'
require 'yaml'
require 'logger'
log = Logger.new(STDOUT)

# Require zendesk_api or dogapi. If one is not installed, return error
# with which API is not installed and abort.
begin
  [ 'zendesk_api', 'dogapi' ].each(&method(:require))
rescue LoadError => e
  log.fatal("You are missing required gem: " + e.message.split[-1]) && abort
end

# Lets keep the keys out of our code. Load in a yaml config file.
# If this is missing, all of the code will break. So abort.
File.exist?('./api.key.yaml') ?
  config = YAML.load_file('./api.key.yaml') :
  log.fatal("Could not locate config file: api.key.yaml") && abort

# Authorization for DataDog
api_key = config['datadog']['api_key']
app_key = config['datadog']['app_key']
dog = Dogapi::Client.new(api_key, app_key)

# Authorization for ZenDesk
client = ZendeskAPI::Client.new do |c|
  c.url = config['zendesk']['url']
  c.username = config['zendesk']['user']
  c.token = config['zendesk']['token']
  c.retry = true
  c.logger = Logger.new(STDOUT)
end

# Run a count on the view "Open Tickets" (provide view ID)
ticket = client.views.find(:id => config['zendesk']['viewid']).tickets.count

# Send the count to datadog.
dog.emit_point('Open Ticket Count', ticket, :host => "ZendeskAPI")
