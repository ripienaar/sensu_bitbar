#!/usr/bin/env ruby

# Plugin for https://github.com/stretchr/bitbar to show sensu
# status in your OS X menu bar
#
# Copy into the BitBar plugin folder, configure the 4 constants
# here and enjoy.  Copy it multiple times with unique names for
# multiple sensu servers

SENSU_NAME="Sensu"
SENSU_HOST="http://sensu.example.net:4567/"
DASHBOARD_URL="http://uchiwa.example.net/#/events"
PROXY="http://10.1.4.1" # set to nil to avoid using a proxy

require 'rubygems'
require 'rest-client'
require 'json'

COLORS = {0 => "green", 1 => "yellow", 2 => "red", 3 => "gray"}

issues = []

begin
  RestClient.proxy = PROXY if PROXY

  events = RestClient.get('%s/events' % SENSU_HOST.chomp("/"))

  if events.code == 200
    issues = JSON.parse(events.body).map do |event|
      {:client => event["client"]["name"], :check => event["check"]["name"], :status => event["check"]["status"]}
    end

    if issues.empty?
      puts "%s | color=green" % SENSU_NAME
      puts "---"
      puts "No events found"
    else
      status = Integer(issues.map{|i| i[:status]}.max)

      puts "%s | color=%s" % [SENSU_NAME, COLORS[status]]
      puts "---"

      issues[0..5].each do |issue|
        puts "%s - %s | href=%s" % [issue[:client], issue[:check], DASHBOARD_URL]
      end
    end
  else
    puts "%s | color=red" % SENSU_NAME
    puts "---"
    puts "Could not fetch events: %s" % events.code
  end
rescue
  puts "%s | color=red" % SENSU_NAME
  puts "---"
  puts "Could not fetch events: %s: %s" % [$!.class, $!.to_s]
end
