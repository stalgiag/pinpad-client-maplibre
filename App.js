import React, { useEffect, useState } from "react";
import { StyleSheet, View, Platform } from "react-native";
import * as RNFS from "@dr.pogodin/react-native-fs";
import { unzip } from "react-native-zip-archive";
import Server, {
  getActiveServerId,
  STATES,
} from "@dr.pogodin/react-native-static-server";
import MapLibreGL from "@maplibre/maplibre-react-native";

MapLibreGL.setAccessToken(null); // Not needed for custom tile servers

const USE_EXTERNAL_SERVER = false;

export default function App() {
  const [serverURL, setServerURL] = useState(null);

  useEffect(() => {

    let staticServer; // set if USE_EXTERNAL_SERVER is false

    const setupTilesInternalServer = async () => {
      try {
        const extractionPath = `${RNFS.DocumentDirectoryPath}/tiles`;
        const zipDestinationPath = `${RNFS.DocumentDirectoryPath}/test.drift`;

        const fileExists = await RNFS.exists(zipDestinationPath);
        if (fileExists) {
          console.log("Deleting existing .drift file and extraction")
          await RNFS.unlink(zipDestinationPath);
          await RNFS.unlink(extractionPath);
        }

        console.log("Copying test.drift to a writable directory...");
        if (Platform.OS === "android") {
          // On Android, use copyFileAssets
          await RNFS.copyFileAssets("test.drift", zipDestinationPath);
        } else {
          // On iOS, use copyFile with MainBundlePath
          const assetPath = `${RNFS.MainBundlePath}/test.drift`;
          await RNFS.copyFile(assetPath, zipDestinationPath);
        }

        console.log("Unzipping...");
        await unzip(zipDestinationPath, extractionPath);
        console.log("Extraction complete");

        // e.g., final extracted path: <DocumentDirectoryPath>/tiles/tiles/*.pbf
        const dataDir = `${extractionPath}/tiles`;

        const activeServerId = await getActiveServerId();
        if (activeServerId) {
          console.log(`active server id is ${activeServerId}`);
          staticServer = new Server({
            fileDir: dataDir,
            port: 8080,
            stopInBackground: true,
            id: activeServerId,
            sate: STATES.ACTIVE,
          });
          setServerURL(staticServer.origin);
        } else {
          // Start the static server on port 8080
          staticServer = new Server({
            fileDir: dataDir,
            port: 8080,
            stopInBackground: true,
          });
          const url = await staticServer.start();
          console.log(`Static server started at ${url}`);

          setServerURL(url);
        }
      } catch (error) {
        console.error("Error setting up tiles:", error);
      }
    };

    const setupTilesExternalServer = async () => {
      if (Platform.OS === "android") {
        setServerURL("http://10.0.2.2:8080");
      } else {
        setServerURL("http://localhost:8080");
      }
      console.log(`Using external server at url: ${serverURL}`);
    };

    const setupTiles = async (externalServer) => {
      if (externalServer) {
        await setupTilesExternalServer();
      } else {
        await setupTilesInternalServer();
      }
    };

    setupTiles(USE_EXTERNAL_SERVER);

    return () => {
      if (staticServer) {
        staticServer.stop();
      }
    };
  }, []);

  if (!serverURL) {
    return null; // or some loading indicator
  }

  return (
    <View style={styles.container}>
      <MapLibreGL.MapView
        style={styles.map}
        styleURL={`${serverURL}/style.json`}
      >
        <MapLibreGL.Camera
          zoomLevel={9}
          centerCoordinate={[-73.72826520392081, 45.584043985983]}
        />
        <MapLibreGL.VectorSource
          id="custom-tiles"
          tileUrlTemplates={[`${serverURL}/data/{z}/{x}/{y}.pbf`]}
          minZoomLevel={5}
          maxZoomLevel={10}
        >
          <MapLibreGL.FillLayer
            id="land"
            sourceID="custom-tiles"
            sourceLayerID="landcover"
            style={{ fillColor: "#00FF00" }}
          />
          <MapLibreGL.LineLayer
            id="transportation"
            sourceID="custom-tiles"
            sourceLayerID="transportation"
            style={{ lineColor: "#FF0000" }}
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
