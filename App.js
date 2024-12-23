import React, { useEffect, useState } from "react";
import { StyleSheet, View } from "react-native";
import * as RNFS from '@dr.pogodin/react-native-fs';
import { unzip } from "react-native-zip-archive";
import Server from "@dr.pogodin/react-native-static-server";
import MapLibreGL from "@maplibre/maplibre-react-native";

MapLibreGL.setAccessToken(null); // No token needed for custom tile servers

// Explicitly require style.json and tiles.zip to ensure they're bundled
const tilesZip = "./assets/tiles.zip";

export default function App() {
  const [serverURL, setServerURL] = useState(null);

  useEffect(() => {
    const setupTiles = async () => {
      try {
        // Define paths
        const extractionPath = `${RNFS.DocumentDirectoryPath}/tiles`;
        const zipDestinationPath = `${RNFS.DocumentDirectoryPath}/tiles.zip`;

        console.log(`Extraction Path: ${extractionPath}`);
        console.log(`ZIP Destination Path: ${zipDestinationPath}`);

          console.log("Copying tiles.zip to writable directory...");
          await RNFS.copyFileAssets("tiles.zip", zipDestinationPath);

          console.log("Extracting ZIP...");
          await unzip(zipDestinationPath, extractionPath);
          console.log("Extraction complete.");

        // Start the static server
        let dataDir = extractionPath + "/tiles";
        const staticServer = new Server({ fileDir: dataDir, port: 8080 });
        console.log(`dataDir contains ${await RNFS.readdir(dataDir)}`);
        const url = await staticServer.start();
        console.log(
          `Static server started at ${url} with fileDir ${staticServer.fileDir} and origin ${staticServer.fileDir}`
        );
        setServerURL(url);

      } catch (error) {
        console.error("Error setting up tiles:", error.stack);
      }
    };

    setupTiles();

    return () => {
      console.log("Cleaning up...");
    };
  }, []); // Empty dependency array ensures this only runs once

  if (!serverURL) {
    return null; // Render nothing until the server is ready
  }

  return (
    <View style={styles.container}>
      <MapLibreGL.MapView style={styles.map} styleURL="http://10.0.2.2:8080/style.json">
        <MapLibreGL.Camera
          zoomLevel={14}
          centerCoordinate={[-73.72826520392081, 45.584043985983]}
        />
        <MapLibreGL.VectorSource
          id="custom-tiles"
          tileUrlTemplates={[`http://10.0.2.2:8080/data/{z}/{x}/{y}.pbf`]} // Use dynamic server URL
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
