# Description:
#  Search what food trucks are at which offthegrid location for the current day.
#
# Dependencies:
#   None
#
# Configuration:
#   FACEBOOK_ACCESS_TOKEN
#
# Commands:
#   hubot (offthegrid|otg)
#
# Author:
#   aoiwelle
otg_id = '129511477069092'
ROW_STRING = '\n' + ('=' for x in [1..40]).join('') + '\n'
TITLE_SEPARATOR =  ('-' for x in [1..40]).join('')
class TruckEvent
  constructor: (eventListing, msg, callback) ->
    @name = eventListing.name
    @start = new Date(eventListing.start_time)
    @id = eventListing.id
    url = "https://graph.facebook.com/#{@id}"
    msg.http(url)
    .query(access_token: process.env.FACEBOOK_ACCESS_TOKEN)
    .get() (err, res, body) =>
      @description = JSON.parse(body).description unless err
      callback()
  start:
    @start
  description:
    @description
module.exports = (robot) ->
  robot.respond /(offthegrid|otg)/i, (msg) ->
    d = new Date()
    msg.http("https://graph.facebook.com/#{otg_id}/events")
    .query(access_token: process.env.FACEBOOK_ACCESS_TOKEN)
    .get() (err, res, body) ->
      return msg.send "Sorry, Facebook or OTG don't like you. ERROR:#{err}" if err
      return msg.send "Unable to get list of events: #{res.statusCode + ':\n' + body}" if res.statusCode != 200
      graph_data = JSON.parse(body)
      outstandingCallbacks = 0
      this.testme = {}
      callback = () ->
        outstandingCallbacks -= 1
        if outstandingCallbacks == 0
          items = testme[d.toDateString()]
          return msg.send 'No Trucks today' if typeof items == 'undefined' || items.length == 0
          descriptionString = ([item.name, TITLE_SEPARATOR, item.description.replace(/^\s*/g,'')].join('\n') for item in items)
          descriptionString = descriptionString.join('\n'+ROW_STRING+'\n')
          msg.send "Today:\n#{descriptionString}"
      for event_data in graph_data.data
        outstandingCallbacks += 1
        event = new TruckEvent(event_data, msg, callback)
        continue if event.start.toTimeString() > '15' || event.start.toTimeString() < '10'
        unless testme[event.start.toDateString()]
          testme[event.start.toDateString()] = []
        testme[event.start.toDateString()].push event
