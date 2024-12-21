import React, { useEffect, useState } from "react";
import { StyleSheet, View } from "react-native";
import * as RNFS from '@dr.pogodin/react-native-fs';
import { unzip } from "react-native-zip-archive";
import Server from "@dr.pogodin/react-native-static-server";
import MapLibreGL from "@maplibre/maplibre-react-native";

MapLibreGL.setAccessToken(null); // No token needed for custom tile servers

// Explicitly require style.json and tiles.zip to ensure they're bundled
const styleJSON = require("./assets/map_styles/style.json");
const tilesZip = require("./assets/tiles.zip");

export default function App() {
  const [serverURL, setServerURL] = useState(null);
  const [mapStyle, setMapStyle] = useState(null);

  useEffect(() => {
    const setupTiles = async () => {
      try {
        // Define paths
        const extractionPath = `${RNFS.MainBundlePath}/tiles`;
        const zipDestinationPath = `${RNFS.MainBundlePath}/tiles.zip`;

        console.log(`Extraction Path: ${extractionPath}`);
        console.log(`ZIP Destination Path: ${zipDestinationPath}`);

        // Copy the bundled ZIP file to a writable directory
        const fileExists = await RNFS.exists(zipDestinationPath);
        if (!fileExists) {
          console.log("Copying tiles.zip to writable directory...");
          await RNFS.copyFileAssets(tilesZip, zipDestinationPath);
        } else {
          console.log("tiles.zip already exists in writable directory.");
        }

        const dirExists = await RNFS.exists(extractionPath);
        if (!dirExists) {
          console.log("Extracting ZIP...");
          await unzip(zipDestinationPath, extractionPath);
          console.log("Extraction complete.");
        } else {
          console.log("Extraction skipped. Directory already exists.");
        }

        console.log("Starting static server with options:", {
          fileDir: dataDir,
          port: 8080,
        });

        // Start the static server
        let dataDir = extractionPath + "/tiles/data";
        console.log(`dataDir is ${dataDir}`);
        const staticServer = new Server({ fileDir: dataDir, port: 8080 });
        const url = await staticServer.start();
        console.log(`Static server started at ${url} with fileDir ${staticServer.fileDir} and origin ${staticServer.fileDir}` );
        setServerURL(url);

        // Dynamically update style.json with the tiles path
        const updatedStyle = {
          ...styleJSON,
          sources: {
            ...styleJSON.sources,
            "custom-tiles": {
              type: "vector",
              tiles: [`${serverURL}/{z}/{x}/{y}.pbf`],
              minzoom: 0,
              maxzoom: 14,
            },
          },
        };
        setMapStyle(updatedStyle);
      } catch (error) {
        console.error("Error setting up tiles:", error);
      }
    };

    setupTiles();

    return () => {
      console.log("Cleaning up...");
    };
  }, []); // Empty dependency array ensures this only runs once

  if (!serverURL || !mapStyle) {
    return null; // Render nothing until the server is ready
  }

  return (
    <View style={styles.container}>
      <MapLibreGL.MapView style={styles.map} styleJSON={mapStyle}>
        <MapLibreGL.Camera
          zoomLevel={5}
          centerCoordinate={[-73.72826520392081, 45.584043985983]}
        />
        <MapLibreGL.VectorSource
          id="custom-tiles"
          tileUrlTemplates={[`${serverURL}/{z}/{x}/{y}.pbf`]} // Use dynamic server URL
          minZoomLevel={5}
          maxZoomLevel={14}
        >
          <MapLibreGL.FillLayer
            id="land"
            sourceID="custom-tiles"
            sourceLayerID="landcover"
            style={{ fillColor: "#3388ff" }}
          />
          <MapLibreGL.LineLayer
          id="buildings"
          sourceID="custom-tiles"
          sourceLayerID="building"
          style={{ lineColor: "#198EC8" }}
          />
        </MapLibreGL.VectorSource>
      </MapLibreGL.MapView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  map: {
    flex: 1,
  },
});
