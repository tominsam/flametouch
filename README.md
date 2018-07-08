Flame is a browser for Bonjour (also known as ZeroConf) network services. It lists the services advertised on your wireless network and you can browse them by server or by service type. When selecting a service, its advertised details are displayed.

If an application on your iPhone or iPod touch can handle any of the advertised services, a command to open it right away is provided.

https://movieos.org/code/flame-iphone/

## Development notes

Check out the project and run `carthage update` to install dependencies, etc.

Bootstrap fastlane:

    brew install imagemagick
    sudo gem update --system
    sudo gem install fastlane -NV -n /usr/local/bin
    sudo gem install bundler -n /usr/local/bin
    bundle install
    bundle binstubs --path=/usr/local/bin xcpretty

Pull signing keys, etc, using 

    fastlane match development --readonly

Build and push to Crashlytics Beta (also increments build number) with 

    fastlane beta



