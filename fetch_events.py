# The following code is heavily adapted from the Google Calendar API Python client example.

import json
import datetime
import httplib2
import time

# Parse dates into datetime objects
from dateutil import parser
# Write dates out in the correct format according to RFC3339
from rfc3339 import rfc3339

# Google API
from apiclient.discovery import build
from oauth2client.file import Storage
from oauth2client.client import AccessTokenRefreshError
from oauth2client.client import OAuth2WebServerFlow
from oauth2client.tools import run

# google api keys
client_id = "93879183907.apps.googleusercontent.com"
client_secret = "rA1h_3sK-j2Co6pmK_i5_C0_"

# Run print_cals functions to get ids and put them here to get your data.
enabled_cals = ("timeoraclecs467@gmail.com",)

# The scope URL for read/write access to a user's calendar data
scope = 'https://www.googleapis.com/auth/calendar'

# Create a flow object. This object holds the client_id, client_secret, and
# scope. It assists with OAuth 2.0 steps to get user authorization and
# credentials.
flow = OAuth2WebServerFlow(client_id, client_secret, scope)

def print_cals(service):
    """
    Print out calendar names and their ids. Add the ones you want to enabled cals.
    """
    page_token = None
    while True:
        calendar_list = service.calendarList().list(pageToken=page_token).execute()
        if calendar_list['items']:
            for calendar_list_entry in calendar_list['items']:
                print calendar_list_entry['summary']
                print calendar_list_entry['id']

        page_token = calendar_list.get('nextPageToken')
        if not page_token:
            break

def filter_events(event_list):
    """
    Remove overlapping events from the calendar.
    """
    events = sorted(event_list, key=lambda x: x["start"])
    curr_event = events[0]
    to_delete = []
    for e in events[1:]:
        if e["start"] < curr_event["end"]:
            to_delete.append(e)
        else:
            curr_event = e
    events = [e for e in events if e not in to_delete]
    return events

def insert_free_time(event_list):
    """
    Insert a 'Free Time' event between all other events in the list.
    """
    events = sorted(event_list, key=lambda x: x["start"])
    free_events = []
    if time.time() < events[0]["start"]:
        e = {"summary":"Free Time",
             "start": time.time(),
             "end": events[0]["start"]
        }
        free_events.append(e)
    for i in range(len(events) - 1):
        if events[i]["end"] != events[i + 1]["start"]:
            e = {"summary":"Free Time",
                 "start": events[i]["end"],
                 "end": events[i + 1]["start"]
            }
            free_events.append(e)
    events += free_events
    return sorted(events, key=lambda x: x["start"])




def main():
    # Storage object to hold User credentials between calls.  Only holds one
    # user at a time.
    storage = Storage('credentials.dat')

    # The get() function returns the credentials for the Storage object. If no
    # credentials were found, None is returned.
    credentials = storage.get()

    # If no credentials are found or the credentials are invalid due to
    # expiration, new credentials need to be obtained from the authorization
    # server. The oauth2client.tools.run() function attempts to open an
    # authorization server page in your default web browser. The server
    # asks the user to grant your application access to the user's data.
    # If the user grants access, the run() function returns new credentials.
    # The new credentials are also stored in the supplied Storage object,
    # which updates the credentials.dat file.
    if credentials is None or credentials.invalid:
        credentials = run(flow, storage)

    # Create an httplib2.Http object to handle our HTTP requests, and authorize it
    # using the credentials.authorize() function.
    http = httplib2.Http()
    http = credentials.authorize(http)

    # The apiclient.discovery.build() function returns an instance of an API service
    # object can be used to make API calls. The object is constructed with
    # methods specific to the calendar API. The arguments provided are:
    #   name of the API ('calendar')
    #   version of the API you are using ('v3')
    #   authorized httplib2.Http() object that can be used for API calls
    service = build('calendar', 'v3', http=http)
    print_cals(service)
    try:
        event_list = []
        keys = {"end", "start", "summary"}
        time_min = rfc3339(datetime.datetime.now() - datetime.timedelta(1))
        for cal in enabled_cals:
            request = service.events().list(calendarId=cal,
                                            singleEvents=True,
                                            timeMin=time_min)
            while request != None:
                # Get the next page.
                response = request.execute()
                # Accessing the response like a dict object with an 'items' key
                # returns a list of item objects (events).
                for event in response.get('items', []):
                    if keys.issubset(set(event.keys()))\
                        and "dateTime" in event["start"].keys()\
                        and "dateTime" in event["end"].keys():
                        e = {"summary":event["summary"],
                             "start": int(parser.parse(event["start"]["dateTime"]).strftime("%s")) - 3600,
                             "end": int(parser.parse(event["end"]["dateTime"]).strftime("%s")) - 3600
                        }
                        event_list.append(e)

                # the list_next method.
                request = service.events().list_next(request, response)
        print "\n\ntotal events found: " + str(len(event_list))
        event_list = filter_events(event_list)
        print "total after filtering out overlapping events: " + str(len(event_list))
        event_list = insert_free_time(event_list)
        print "total with free time events inserted: " + str(len(event_list))
        with open("time_oracle/data/event_list.json", "w") as f:
            json.dump(event_list, f, indent=4, separators=(',', ': '))
    except AccessTokenRefreshError:
        # The AccessTokenRefreshError exception is raised if the credentials
        # have been revoked by the user or they have expired.
        print ('The credentials have been revoked or expired, please re-run'
               'the application to re-authorize')

if __name__ == '__main__':
    main()