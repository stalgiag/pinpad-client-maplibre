import * as RNFS from '@dr.pogodin/react-native-fs';
import { unzip } from 'react-native-zip-archive';
import { Platform } from 'react-native';

// Note: This is a temporary sketch and these aren't being used currently
// TODO: Replace
export class FileSystemService {
  // TODO: Generalize these methods
  async extractTileBundle(bundleName: string, extractionPath: string): Promise<string> {
    const zipDestination = `${RNFS.DocumentDirectoryPath}/${bundleName}`;

    if (await RNFS.exists(zipDestination)) {
      await RNFS.unlink(zipDestination);
      await RNFS.unlink(extractionPath);
    }

    if (Platform.OS === 'android') {
      await RNFS.copyFileAssets(bundleName, zipDestination);
    } else {
      const assetPath = `${RNFS.MainBundlePath}/${bundleName}`;
      await RNFS.copyFile(assetPath, zipDestination);
    }

    await unzip(zipDestination, extractionPath);
    return `${extractionPath}/tiles`;
  }

  async getTile(tilePath: string): Promise<string> {
    if (!(await RNFS.exists(tilePath))) {
      throw new Error(`Tile not found: ${tilePath}`);
    }
    return tilePath;
  }
}
