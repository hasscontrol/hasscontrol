## HassControl

A garmin widget to interact with [Home Assistant](https://www.home-assistant.io/).


<img src="resources/screenshots/tactix_delta_1.png" height="250" />


The widget aims to be simplistic but still provide the most basic functionality, such as triggering scenes or toggling lights and switches.

Due to limitations by both Garmin and Apple/Android some setup steps will be more cumbersome than what I would have preferred.

Please read through the instructions below, I will try to guide you through the steps :)

- [HassControl](#hasscontrol)
  - [Prerequisites](#prerequisites)
  - [Supported entity types table](#supported-entity-types)
  - [Installation](#installation)
  - [Configuration](#configuration)
  - [Logging in](#logging-in)
  - [Group sync](#group-sync)
  - [FAQ](#faq)


### Prerequisites
In order to use this widget you need to have an Home Assistant instance accessible over https.

As all communication from Garmin watches go thru the mobile device, you also need to have a paired mobile phone, and the Garmin Connect app needs to be running on that phone.

As soon as you get out of range from the phone or closes the app the widget will stop functioning.


### Supported entity types
Currently only following Home Assistant entities are supported:

Entity type | Note
--- | ---
binary_sensor | Only displays basic boolean state, device class is not supported.
input_boolean | Toggling of its state is supported.
light | Only turning on/off is supported, the rest like colour, brightness, etc. are not supported.
lock | Both locking and unlocking are supported.
cover | Both closing and opening the cover is supported.
switch | Only turning on/off, energy consumption and standby mode are not supported.
automation* | Can be turned on/off.
scene* | Execution
script* | Execution


\* marked are not entities in the true sense of the word, but why have two tables

### Installation
The easiest way to install the app is to download and install the [ConnectIQ app](https://support.garmin.com/en-US/?faq=mmm2rz2WBI3zbdFQYdiwX8) from Garmin on your smartphone.

Once you have the app installed on your paired phone you can browse for widget and find the app by name, [HassControl](https://apps.garmin.com/en-US/apps/47f64742-cf59-4d54-b368-841a347f7c6d).

### Configuration
Open the widget settings in the ConnectIQ app.
[How to Access the Settings of a Connect IQ App Using the Garmin Connect App](https://support.garmin.com/en-US/?faq=SPo0TFvhQO04O36Y5TYRh5)

**Host**: This should be the url to the Home Assistant instance you would like to control. Remember only https url is supported by Garmin.

**Long-Lived access token**: If you prefer generating an access token in Home Assistant instead of login in thru the garmin app you can paste your token here.

**Scenes**: Since scene names aren't that configurable in Home Assistant you can override the names in this box. Multiple overrides can be specified by separating them with a comma (,).

So for example; If you have the scene `scene.good_bye` and `scene.movie` the configuration string could look like this: `good_bye=Good Bye, movie=Movie`, or `good_bye, movie`.

You can also use this field to "import" scenes if you don't want to create a group in Home Assistant as described below.

**Group**: In this box you can write a single group from Home Assistant, this group can then be used from within the widget to import all entities contained in that group.

I will describe this procedure in more detail below.

***Note:*** *The default start view is filtered to scenes and will not show light, switches etc., the start view can be changed in the widget settings in your Garmin device.*

### Logging in
Once you have configured all settings in the ConnectIQ app, the next step will be to login.

***Note:*** *If you've setup the `Long-Lived access token` you should be logged in automatically and can skip to the next section.*

Since the watch doesn't have an suited interface for logging in to web pages, the login will be performed with the help of your paired smartphone.

Before you get started, make sure that you have installed and paired your watch in the [Garmin Connect](https://connect.garmin.com/start/) app.

If you don't have push notifications turned on, make sure the app is running before proceeding.

To login, simply open the widget and trigger any scene. Shortly after, you will see a sign in request on your smartphone. Complete the sign in process on your phone and return to the watch.

You should now be able to trigger your scenes.

If you don't have any scenes, you can login by hold the menu button on your watch and logging in from them widget menu.

If you don't see any login request on your phone. Restart the widget after you have opened the garmin Connect app and the watch has been connected.

If you are having problems logging in or if the widget is logged out frequently, you can also generate a `Long-Lived access token` for your user in Home Assistant and paste it to the Connect IQ settings. This will bypass the normal login flow and use that token to communicate with Home Assistant.


### Group sync
Due to the limitations of the watch, there is no really good way of listing and adding entities directly from the watch.
But the easiest way to add your entities is by [creating a new group](https://www.home-assistant.io/integrations/group/) in Home Assistant, and add all your entities there.

Your group configuration can look like this:
```
# Example configuration.yaml entry
group:
  garmin:
    name: Garmin
    entities:
      - light.bathroom
      - switch.tv
      - script.turn_lights_for_10_min
```
***Note***: *Remember after changing the configuration, you have to either reload the groups or restart the Home Assitant.*

Then write the id of the group you have just created (in our case `group.garmin`) into the ConnectIQ app widget settings as described [above](#configuration).

Once you have added the group into ConnectIQ app widget settings, open the widget on your Garmin device and access the menu (on watches with touchscreen using the Press and Hold gesture). Then go into `Settings` and select `Refresh entities`.
Once that is done, all entities added to that group in Home Assistant and supported by HassControl will be imported and available on the watch.

If you done some modification to the group in Home Assistant, you can at any time repeat this procedure to add, update or remove entities from your watch.

### FAQ

#### Error message: "Check settings, invalid url"
Check if you are using correct url with `https` prefix, because only secure HTTPS communication is allowed. This limitation comes from Garmin. 

#### Some entities from my group are missing in my Garmin device
Not all Home Assistant entity types are currently supported by HassControl, you should take a look at [supported entity types table](#supported-entity-types).

#### Changed entity state doesn't show immediately in HassControl
There is a rare occasion when someone changes state of an entity (for example turns the light on), while you are actively using this widget. In this case its state in your Garmin device will not correspond to its actual one. It has to be synced again. There are three option how to sync it. You either toggle it's state, select `Refresh entities` in `Settings` or reopen the widget (the state of all your entities is automatically received from Home Assistant every time you start the widget).

***Note***: *Because after predefined timeout period every widget is automatically closed, you should never experience this type of data discrepancy.*

