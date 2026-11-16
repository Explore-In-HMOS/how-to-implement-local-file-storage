/**
 * Snapshot of app and file-system space.
 * @ObservedV2 + @Trace so that @Monitor('storage.freeBytes') works in the ViewModel.
 */
@ObservedV2
export class StorageInfo {
  @Trace appBytes: number = 0;   // installation files (bundle)
  @Trace cacheBytes: number = 0; // base/cache directories
  @Trace dataBytes: number = 0;  // files + database + distributedfiles
  @Trace freeBytes: number = 0;  // free space of the /data file system
  @Trace totalBytes: number = 0; // total space of the /data file system
}
