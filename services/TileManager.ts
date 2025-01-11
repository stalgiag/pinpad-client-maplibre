import { Asset } from 'expo-asset';
import * as FileSystem from '@dr.pogodin/react-native-fs';
import { unzip } from 'react-native-zip-archive';

export class TileManager {
  private initialized = false;
  private dataPath: string | null = null;
  private stylePath: string | null = null;
  private tilesPath: string | null = null;

  async initialize(): Promise<void> {
    if (this.initialized) return;

    try {
      const asset = await Asset.fromModule(require('../assets/test.drift')).downloadAsync();
      const extractionPath = `${FileSystem.DocumentDirectoryPath}`;

      // Currently we are forcing a clean up
      // in real world we would be keeping caches
      if (await FileSystem.exists(extractionPath)) {
        await FileSystem.unlink(extractionPath);
      }
      await FileSystem.mkdir(extractionPath);

      await unzip(asset.localUri!, extractionPath);

      this.dataPath = `${extractionPath}/tiles`;
      this.tilesPath = `${this.dataPath}/data`;
      this.stylePath = `${this.dataPath}/style.json`;

      if (await FileSystem.exists(this.stylePath)) {
        const styleContent = await FileSystem.readFile(this.stylePath);
        const style = JSON.parse(styleContent);

        // This code adds the tiles to the sources definition
        // This approach suggests that we are going to limit the view
        // to the tiles that we have at the point of interaction
        // This may prove to be annoying for us and we may need
        // to somehow intercept the request event
        // but this is fine for now
        // TODO: determine whether this is acceptable once we start
        // using non-streaming approach
        style.sources = {
          "custom-tiles": {
            "type": "vector",
            "tiles": [`file://${this.tilesPath}/{z}/{x}/{y}.pbf`],
            "maxzoom": 14
          }
        };

        await FileSystem.writeFile(this.stylePath, JSON.stringify(style, null, 2));
      }

      this.initialized = true;
    } catch (error: any) {
      console.error('TileManager initialization error:', error);
      throw new Error(`Failed to initialize TileManager: ${error.message}`);
    }
  }

  getStyleUrl(): string {
    if (!this.initialized || !this.stylePath) {
      throw new Error('TileManager not initialized');
    }
    return `file://${this.stylePath}`;
  }

  getTilePath(): string {
    if (!this.initialized || !this.tilesPath) {
      throw new Error('TileManager not initialized');
    }
    return this.tilesPath;
  }
}
