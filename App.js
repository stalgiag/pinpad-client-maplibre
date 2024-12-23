import React, { useEffect, useState } from "react";
import { StyleSheet, View, Platform } from "react-native";
import * as RNFS from "@dr.pogodin/react-native-fs";
import { unzip } from "react-native-zip-archive";
import Server from "@dr.pogodin/react-native-static-server";
import MapLibreGL from "@maplibre/maplibre-react-native";


MapLibreGL.setAccessToken(null); // Not needed for custom tile servers

export default function App() {
  const [serverURL, setServerURL] = useState(null);

  useEffect(() => {
    const setupTiles = async () => {
      try {
        // Define paths
        const extractionPath = `${RNFS.DocumentDirectoryPath}/tiles`;
        const zipDestinationPath = `${RNFS.DocumentDirectoryPath}/tiles.zip`;

        console.log("Copying tiles.zip to a writable directory...");

        if (Platform.OS === "android") {
          // On Android, use copyFileAssets
          await RNFS.copyFileAssets("tiles.zip", zipDestinationPath);
        } else {
          // On iOS, use copyFile with MainBundlePath
          const assetPath = `${RNFS.MainBundlePath}/tiles.zip`;
          await RNFS.copyFile(assetPath, zipDestinationPath);
        }

        console.log("tiles.zip copied successfully.");

        console.log("Unzipping...");
        await unzip(zipDestinationPath, extractionPath);
        console.log("Extraction complete");

        // e.g., final extracted path: <DocumentDirectoryPath>/tiles/tiles/*.pbf
        const dataDir = `${extractionPath}/tiles`;

        // Start the static server on port 8080
        const staticServer = new Server({
          fileDir: dataDir,
          port: 8080,
        });
        const url = await staticServer.start();
        console.log(`Static server started: ${url}`);

        setServerURL(url);
      } catch (error) {
        console.error("Error setting up tiles:", error);
      }
    };

    setupTiles();

    return () => {
      // Cleanup: Stop the server if needed
      // Example:
      // if (staticServer) {
      //   staticServer.stop();
      // }
    };
  }, []);

  if (!serverURL) {
    return null; // or some loading indicator
  }

  return (
    <View style={styles.container}>
      <MapLibreGL.MapView style={styles.map} styleURL={`${serverURL}/style.json`}>
        <MapLibreGL.Camera
          zoomLevel={14}
          centerCoordinate={[-73.72826520392081, 45.584043985983]}
        />
        <MapLibreGL.VectorSource
          id="custom-tiles"
          tileUrlTemplates={[`${serverURL}/data/{z}/{x}/{y}.pbf`]}
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
  container: { flex: 1 },
  map: { flex: 1 },
});
