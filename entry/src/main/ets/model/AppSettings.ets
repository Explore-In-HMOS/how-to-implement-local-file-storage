import { AppConstants } from '../common/AppConstants';

/**
 * Small UI preferences persisted with PersistenceV2.
 * Rule of thumb for this codelab:
 *  - tiny UI state (flags, sort order)  -> PersistenceV2
 *  - real user content (notes)          -> fileIo in filesDir
 */
@ObservedV2
export class AppSettings {
  @Trace newestFirst: boolean = true;
  @Trace previewBytes: number = AppConstants.PREVIEW_BYTES;
}
