# NextDepartures

Project created as part of Udacity iOS Nanodegree - Final Project

Submitted: 2015-05-26

Project Description:
The app should showcase your iOS skillset. Your app should have a complexity similar to the On The Map app and the Virtual Tourist apps, and should include code from the following areas:

**User Interface:** Your app should demonstrate that you can combine the essential UIKit components in effective ways. 

**Networking:** Your app should incorporate data from a networked source.

**Persistence:** Your app should incorporate data that needs to be persisted between runs of the app.

----------------------

## Next Departures Functionality
Next Departures lets you check the closest public transport service from where you are. The app currently only consumes the data for PTV (Public Transport Victoria) - https://www.data.vic.gov.au/data/dataset/ptv-timetable-api.

The app lets you achieve the following tasks:
- A user is able to retrieve the different public transport services passing nearby. 
- Check the stop nearby in a map
- Get the next available public transport services stopping at a specific stop by just tapping the stop in the map.
- Select a service to see the complete route.
  - When viewing the route of a service, you can tap on a stop and select if you want to be notified when you are close to it (tracking stop).
- Stop tracking
  - When creating a tracking stop, the user is able to select how far away from a stop they want to be notified - 200m, 500m or 1km.
  - Keep tracking of stops.
  - Enable/Disable tracking stops.
  - Remove tracking stops.
- An Apple Watch app has been created for this App.
  - Glances: View the next public transport service.
  - Interface: You'll see all the services shown in the Next Departures iPhone App. If a service is selected, a new view will slide and show the location of the stop (same view displayed for a Glance).
- Two GPXs files have been included in the Project. One to simulate Melbourne CBD location and another one to simulate the route taken by a public transport service (from Melbourne CBD to St. Kilda Rd)  

**Important:** In order to be able to use the app, you'll need to simulate your location to Melbourne, Australia. A GPX file has been included in the Project to simulate the location of Melbourne CBD.
