import React, { useEffect } from 'react';
import { StyleSheet, View, ActivityIndicator, Text } from 'react-native';
import MapLibreGL from '@maplibre/maplibre-react-native';
import { useTileManager } from './hooks/useTileManager';

export default function App() {
  const { tileManager, isLoading, error } = useTileManager();

  useEffect(() => {
    MapLibreGL.setAccessToken(null);
  }, []);

  if (isLoading) {
    return <ActivityIndicator />;
  }

  if (error) {
    return (
      <View style={styles.errorContainer}>
        <Text style={styles.errorText}>Error: {error.message}</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <MapLibreGL.MapView
        style={styles.map}
        styleURL={tileManager.getStyleUrl()}
        testID="map-view"
      >
        <MapLibreGL.Camera
          zoomLevel={9}
          centerCoordinate={[-73.72826520392081, 45.584043985983]}
          minZoomLevel={5}
          maxZoomLevel={10}
        />
      </MapLibreGL.MapView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  map: { flex: 1 },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  errorText: { 
    color: 'red',
    fontSize: 16,
  },
});