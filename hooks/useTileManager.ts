import { useState, useEffect } from 'react';
import { TileManager } from '../services/TileManager';
import { FileSystemService } from '../services/FileSystem';
import { TileManagerState } from '../types/tiles';

export function useTileManager() {
  const [state, setState] = useState<TileManagerState>({
    isInitialized: false,
    isLoading: true,
    error: null,
  });

  const [tileManager] = useState(() => new TileManager(
    {
      bundleFileName: 'test.drift',
      extractionPath: 'tiles',
      minZoom: 5,
      maxZoom: 10,
    },
    new FileSystemService()
  ));

  useEffect(() => {
    const initializeTiles = async () => {
      try {
        await tileManager.initialize();
        setState({ isInitialized: true, isLoading: false, error: null });
      } catch (error) {
        setState({ isInitialized: false, isLoading: false, error });
      }
    };

    initializeTiles();
  }, []);

  return { tileManager, ...state };
}