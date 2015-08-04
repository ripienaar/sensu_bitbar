#!/usr/bin/env ruby

# Plugin for https://github.com/stretchr/bitbar to show sensu
# status in your OS X menu bar
#
# Copy into the BitBar plugin folder, configure the 4 constants
# here and enjoy.  Copy it multiple times with unique names for
# multiple sensu servers

SENSU_NAME="Sensu"                                  # text appearing on the menu in green/red/yello
SENSU_HOST="http://sensu.example.net:4567/"         # your sensu api
DASHBOARD_URL="http://uchiwa.example.net/#/events"  # a link that will open if you click on an event
PROXY="http://10.1.4.1"                             # set to nil to avoid using a proxy
SHOW_EVENTS=5                                       # how many events to show in the drop down

require 'rubygems'
require 'rest-client'
require 'json'

COLORS = {0 => "green", 1 => "orange", 2 => "red", 3 => "gray"}

issues = []

begin
  RestClient.proxy = PROXY if PROXY

  events = RestClient.get('%s/events' % SENSU_HOST.chomp("/"))

  if events.code == 200
    issues = JSON.parse(events.body).map do |event|
      {:client => event["client"]["name"], :check => event["check"]["name"], :status => event["check"]["status"]}
    end

    if issues.empty?
      puts "%s | color=%s href=%s" % [SENSU_NAME, COLORS[0], DASHBOARD_URL]
      puts "---"
      puts "No events found"
    else
      status = Integer(issues.map{|i| i[:status]}.max)

      puts "%s | color=%s" % [SENSU_NAME, COLORS[status]]
      puts "---"

      issues[0..SHOW_EVENTS].each do |issue|
        puts "%s - %s | color=%s href=%s" % [issue[:client], issue[:check], COLORS[issue[:status]], DASHBOARD_URL]
      end
    end
  else
    puts "%s | color=%s" % [SENSU_NAME, COLORS[2]]
    puts "---"
    puts "Could not fetch events: %s" % events.code
  end
rescue
  puts "%s | color=%s" % [SENSU_NAME, COLORS[2]]
  puts "---"
  puts "Could not fetch events: %s: %s" % [$!.class, $!.to_s]
end
