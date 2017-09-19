Flame is a browser for Bonjour (also known as ZeroConf) network services. It lists the services advertised on your wireless network and you can browse them by server or by service type. When selecting a service, its advertised details are displayed.

If an application on your iPhone or iPod touch can handle any of the advertised services, a command to open it right away is provided.

https://movieos.org/code/flame-iphone/

## Development notes

Check out the project and run `carthage update` to install dependencies, etc.

Bootstrap fastlane:

    brew cask reinstall fastlane
    sudo gem install bundler
    bundle install

Pull signing keys, etc, using 

    fastlane match development --readonly

Build and push to Crashlytics Beta (also increments build number) with 

    fastlane beta



