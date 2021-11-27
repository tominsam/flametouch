Flame is a browser for Bonjour (also known as ZeroConf) network services. It lists the services advertised on your wireless network and you can browse them by server or by service type. When selecting a service, its advertised details are displayed.

If an application on your iPhone or iPod touch can handle any of the advertised services, a command to open it right away is provided.

https://movieos.org/code/flame/

## Development

I use xcodegen to manage my project file. The `start` shell script will generate the project file and restart xcode with it.

To build and run on a physical device you need the `com.apple.developer.networking.multicast` entitlement, which needs to be explicitly requested from Apple - it's not self service, and the app will not be able to discover local services without it.

## TODO

* Some services (eg those broadcast by iOS in sleep mode but charging) seem to disappear and appear. Hosts should have some hysteresis so that the left pane doesn't jitter so much
* When services appear and disappear the selected row in the left pane deselected
* New tab keyboard shortcut on mac, or remove tabbing. Either.

