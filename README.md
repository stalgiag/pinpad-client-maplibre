# Drift Pinpad

A Signal extension for private mapping based on [MapLibre](https://github.com/maplibre/maplibre-native).

# Development
This is an [Expo](https://expo.dev) project created with [`create-expo-app`](https://www.npmjs.com/package/create-expo-app).

We use [yarn](https://yarnpkg.com/) for dependency management and building. We don't have a container working yet, and I don't know what I'm doing, so for now I'll just record some commands for setup for total newbies that I'd hope would be good enough to run the code.

I have been developing on a Mac and running against iOS and Android simulators. More on that later.

## Basics
You will need to have node installed. I have been using version 22.11.0. You can set this with `nvm`, which you will also have to install. You will need to have `yarn` installed. Then the command
```
yarn
```
will install all needed dependencies in a folder `node_modules`.

As always, the file `package.json` defines some aliases for our most commonly used commands.

## Expo
Expo is most useful when you can use some of its built in modules that ensure a smooth cross-platform experience. Then you can easily develop using Expo Go to, e.g., test on real devices. Unfortunately, this currently does not allow for mapping apps with custom tile servers, so we have to do more manual and platform specific things. Expo is still a convenient uniform wrapper around build commands.

The commands `yarn expo prebuild` does some platform-specific stuff. I think it's not necessary to run it now (it'll just prettify some of the platform-specific config files?).


## iOS
To builds for iOS, you need to be on a Mac. You need to have Xcode installed. This in particular allows you to install a simulator. To access these, go to **Xcode > Open Developer Tool > Simulator**. Here you can make add a simulator under **File > New Simulator**. For this to work you'll have to an iOS version available to install on the simulator. This can be achieved through Xcode via **Settings > Components (tab)**.

With all of this set up, the command 
```
yarn ios
```
should build the softare, launch your simulator, install it and run it.


## Android
This is pretty similar to the iOS flow. There is a dedicated IDE [Android Studio](https://developer.android.com/studio) that is quite similar to Xcode at a high level. You need to install that. To set up a simulator, look under **Tools > Device Manager**.

For Android you need to launch a simulator first. Then 
```
yarn android
``` 
should detect it and run your code there.

# Test tiles

We have tiles for testing in tiles.zip. It is a zipping of a directory structured like this, with tiles in z/x/y format:
```
tiles
├── data
│   ├── 10               // z
│   │   ├── 300          // x
│   │   │   ├── 364.pbf  // y
└── style.json
```

I may have had to manually drop this file in place via Xcode to get things working for iOS, but I don't think that's necessary in our current setup.