Flame is a browser for Bonjour (also known as ZeroConf) network services. It lists the services advertised on your wireless network and you can browse them by server or by service type. When selecting a service, its advertised details are displayed.

If an application on your iPhone or iPod touch can handle any of the advertised services, a command to open it right away is provided.

https://movieos.org/code/flame/

## Development

I use xcodegen to manage my project file. The `start` shell script will generate the project file and restart xcode with it.

To build and run on a physical device you need the `com.apple.developer.networking.multicast` entitlement, which needs to be explicitly requested from Apple - it's not self service, and the app will not be able to discover local services without it.

## TODO

* New tab keyboard shortcut on mac, or remove tabbing. Either.
* Service discovery isn't reliable and refreshing will often find new things. Clearly I can't trust the OS. Periodically drop and restart service discovery, but retain all the old services to prevent jitter, and then have some sort of "still alive" tracking so that removed services will be rendered as such in the UI.
* Long domains and service names are clipping and there's no real way of seeing the full thing.
* Need better way of copying IP and names without relying on users discovering long-press of rows.

