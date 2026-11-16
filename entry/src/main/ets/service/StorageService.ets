import { statfs, storageStatistics } from '@kit.CoreFileKit';
import { StorageInfo } from '../model/StorageInfo';

/**
 * Wraps the space statistics APIs.
 * Watches have little storage, so the app checks free space before heavy writes.
 */
export class StorageService {
  async getStorageInfo(path: string): Promise<StorageInfo> {
    // Start all three requests at once, then await them.
    const bundlePromise: Promise<storageStatistics.BundleStats> = storageStatistics.getCurrentBundleStats();
    const freePromise: Promise<number> = statfs.getFreeSize(path);
    const totalPromise: Promise<number> = statfs.getTotalSize(path);

    const bundle: storageStatistics.BundleStats = await bundlePromise;
    const info: StorageInfo = new StorageInfo();
    info.appBytes = bundle.appSize;
    info.cacheBytes = bundle.cacheSize;
    info.dataBytes = bundle.dataSize;
    info.freeBytes = await freePromise;
    info.totalBytes = await totalPromise;
    return info;
  }
}
