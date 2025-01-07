# Drift Pinpad

A Signal extension for private mapping based on [MapLibre](https://github.com/maplibre/maplibre-native).

Current state: [the app](App.js) has two modes determined by the boolean `USE_EXTERNAL_SERVER.` When using an external tile server, the app acts as a simple map viewer. When the boolean is false, the app will unzip a given set of tiles, instantiate a tile server within the device, and act as a viewer for those tiles.

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

## External tile server
When `USE_EXTERNAL_SERVER` is true, the app looks for tiles at a given address. For development purposes, we provide a server that 
can be run on the host machine via `yarn start:tiles`. 

# Test tiles

`We have tiles for testing in assets/. A `.drift` file is a zipping of a directory structured like this, with tiles in z/x/y format:
```
tiles
├── data
│   ├── 10               // z
│   │   ├── 300          // x
│   │   │   ├── 364.pbf  // y
└── style.json
```

**To generate these files for testing, run**
```
yarn generate-test-data
```



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

## Testing

We have two testing frameworks:

- [Jest](https://jestjs.io/) for unit testing.
- [Maestro](https://maestro.mobile.dev/) for UI testing.

We currently only have a single test for the map view using Maestro. To run Maestro, you will need to install it. Instructions can be found [here](https://maestro.mobile.dev/docs/getting-started/installation).

To run the tests, you can use the following commands:

```
yarn test:maestro:ios
yarn test:maestro:android
```

This will boot the simulator and run the tests. Currently, iPhone XR is used by default. You can change this in the shell script file if you want to use a different simulator.


