Flame is a browser for Bonjour (also known as ZeroConf) network services. It lists the services advertised on your wireless network and you can browse them by server or by service type. When selecting a service, its advertised details are displayed.

If an application on your iPhone or iPod touch can handle any of the advertised services, a command to open it right away is provided.

https://movieos.org/code/flame-iphone/

## Development notes

Check out the project and run `carthage update` to install dependencies, etc.

Bootstrap fastlane:

    brew install imagemagick

    brew install rbenv
    rbenv init
    rbenv install
    gem update --system
    gem install bundler
    bundle install

Pull signing keys, etc, using 

    fastlane match development --readonly

Build and push to Crashlytics Beta (also increments build number) with 

    fastlane beta

TODO

* Some services (eg those broadcast my iOS in sleep mode but charging) seem to disappear and appear. Hosts should have some hysteresis so that the left pane doesn't jitter so much
* When services appear and disappear the selected row in the left pane deselected
* Some sort of search / filtering for left pane to only show hosts that match a specific service or name
* New tab keyboard shortcut on mac, or remove tabbing. Either.


