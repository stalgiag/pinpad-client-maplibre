export interface TileCoordinates {
  x: number;
  y: number;
  z: number;
}

export interface TileManagerConfig {
  bundleFileName: string;
  extractionPath: string;
  minZoom: number;
  maxZoom: number;
}

export interface TileManagerState {
  isInitialized: boolean;
  isLoading: boolean;
  error: Error | null;
}