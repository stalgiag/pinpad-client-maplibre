import { FileSystemService } from './FileSystem';
import { TileManagerConfig, TileCoordinates } from '../types/tiles';

export class TileManager {
  private initialized = false;
  private tilesPath: string | null = null;

  constructor(
    private config: TileManagerConfig,
    private fileSystem: FileSystemService
  ) { }

  async initialize(): Promise<void> {
    if (this.initialized) return;

    try {
      this.tilesPath = await this.fileSystem.extractTileBundle(
        this.config.bundleFileName,
        this.config.extractionPath
      );
      this.initialized = true;
    } catch (error) {
      throw new Error(`Failed to initialize TileManager: ${error.message}`);
    }
  }

  async getTilePath({ x, y, z }: TileCoordinates): Promise<string> {
    if (!this.initialized) {
      throw new Error('TileManager not initialized');
    }

    if (z < this.config.minZoom || z > this.config.maxZoom) {
      throw new Error('Zoom level out of bounds');
    }

    const tilePath = `${this.tilesPath}/data/${z}/${x}/${y}.pbf`;
    return this.fileSystem.getTile(tilePath);
  }

  getStyleUrl(): string {
    if (!this.initialized || !this.tilesPath) {
      throw new Error('TileManager not initialized');
    }
    return `file://${this.tilesPath}/style.json`;
  }
}