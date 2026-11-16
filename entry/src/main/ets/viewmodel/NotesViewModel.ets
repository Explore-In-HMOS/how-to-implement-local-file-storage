import { common } from '@kit.AbilityKit';
import { PersistenceV2 } from '@kit.ArkUI';
import { taskpool } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppConstants } from '../common/AppConstants';
import { FormatUtil } from '../common/FormatUtil';
import { Logger } from '../common/Logger';
import { AppSettings } from '../model/AppSettings';
import { NoteFile } from '../model/NoteFile';
import { StorageInfo } from '../model/StorageInfo';
import { writeSampleNotes } from '../service/BatchWriter';
import { FileService } from '../service/FileService';
import { StorageService } from '../service/StorageService';

/**
 * Single ViewModel shared by all pages through AppStorageV2.
 * Views read @Trace / @Computed state and call methods; they never touch fileIo.
 */
@ObservedV2
export class NotesViewModel {
  @Trace notes: NoteFile[] = [];
  @Trace isLoading: boolean = false;
  @Trace errorMessage: string = '';
  @Trace statusMessage: string = '';
  @Trace currentContent: string = '';
  @Trace storage: StorageInfo = new StorageInfo();
  @Trace lowStorage: boolean = false;

  // Persisted automatically by PersistenceV2 whenever a @Trace field changes.
  settings: AppSettings = PersistenceV2.connect(AppSettings, AppConstants.SETTINGS_KEY, () => new AppSettings())!;

  private fileService: FileService = new FileService();
  private storageService: StorageService = new StorageService();
  private filesDir: string = '';
  private initialized: boolean = false;

  init(context: common.UIAbilityContext): void {
    if (this.initialized) {
      return;
    }
    const appContext: common.ApplicationContext = context.getApplicationContext();
    this.filesDir = appContext.filesDir;
    this.fileService.init(appContext.filesDir, appContext.cacheDir);
    this.initialized = true;
  }

  // ---------- Derived state ----------

  @Computed
  get sortedNotes(): NoteFile[] {
    const newestFirst: boolean = this.settings.newestFirst;
    const copy: NoteFile[] = this.notes.slice();
    copy.sort((a: NoteFile, b: NoteFile) => newestFirst ? b.modifiedAt - a.modifiedAt : a.modifiedAt - b.modifiedAt);
    return copy;
  }

  @Computed
  get totalNotesBytes(): number {
    let sum: number = 0;
    this.notes.forEach((n: NoteFile) => {
      sum += n.sizeBytes;
    });
    return sum;
  }

  @Computed
  get usedPercent(): number {
    const total: number = this.storage.totalBytes;
    if (total <= 0) {
      return 0;
    }
    return Math.round(((total - this.storage.freeBytes) / total) * 100);
  }

  @Monitor('storage.freeBytes')
  onFreeBytesChanged(monitor: IMonitor): void {
    this.lowStorage = this.storage.freeBytes > 0 && this.storage.freeBytes < AppConstants.LOW_STORAGE_BYTES;
    if (this.lowStorage) {
      Logger.info(`Low storage: ${FormatUtil.bytes(this.storage.freeBytes)} free`);
    }
  }

  // ---------- Actions ----------

  /** Stale-while-revalidate: show the cached index first, then refresh from disk. */
  async load(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      if (this.notes.length === 0) {
        const cached: NoteFile[] = await this.fileService.loadIndexCache();
        if (cached.length > 0) {
          this.notes = cached;
        }
      }
      await this.fileService.ensureNotesDir();
      await this.fileService.cleanupTempFiles();
      const fresh: NoteFile[] = await this.fileService.listNotes(this.settings.previewBytes);
      this.notes = fresh;
      await this.fileService.saveIndexCache(fresh);
    } catch (e) {
      this.errorMessage = this.describe(e);
    } finally {
      this.isLoading = false;
    }
  }

  /** One tap = one note. Updates the list incrementally instead of reloading everything. */
  async addQuickNote(): Promise<void> {
    const templates: string[] = AppConstants.QUICK_TEMPLATES;
    const template: string = templates[this.notes.length % templates.length];
    const content: string = `${template}\n${FormatUtil.dateTime(Date.now())}`;
    try {
      const note: NoteFile = await this.fileService.createNote(content);
      this.notes.push(note);
      await this.fileService.saveIndexCache(this.notes);
    } catch (e) {
      this.errorMessage = this.describe(e);
    }
  }

  async openNote(fileName: string): Promise<void> {
    this.currentContent = '';
    try {
      this.currentContent = await this.fileService.readNote(fileName);
    } catch (e) {
      this.currentContent = this.describe(e);
    }
  }

  async deleteNote(fileName: string): Promise<void> {
    try {
      await this.fileService.deleteNote(fileName);
      this.notes = this.notes.filter((n: NoteFile) => n.fileName !== fileName);
      await this.fileService.saveIndexCache(this.notes);
    } catch (e) {
      this.errorMessage = this.describe(e);
    }
  }

  async refreshStorage(): Promise<void> {
    try {
      this.storage = await this.storageService.getStorageInfo(this.filesDir);
    } catch (e) {
      this.statusMessage = this.describe(e);
    }
  }

  async clearCache(): Promise<void> {
    try {
      const removed: number = await this.fileService.clearCache();
      this.statusMessage = `Cache cleared (${removed} item)`;
      await this.refreshStorage();
    } catch (e) {
      this.statusMessage = this.describe(e);
    }
  }

  /** Heavy batch I/O goes to TaskPool so scrolling stays smooth. */
  async generateSamples(): Promise<void> {
    if (this.lowStorage) {
      this.statusMessage = 'Not enough free space';
      return;
    }
    this.statusMessage = 'Writing on worker...';
    try {
      await this.fileService.ensureNotesDir();
      const task: taskpool.Task = new taskpool.Task(writeSampleNotes,
        this.fileService.getNotesDir(), AppConstants.SAMPLE_BATCH_SIZE, Date.now());
      const written: number = await taskpool.execute(task) as number;
      this.statusMessage = `${written} notes written`;
      await this.load();
      await this.refreshStorage();
    } catch (e) {
      this.statusMessage = this.describe(e);
    }
  }

  toggleSort(): void {
    this.settings.newestFirst = !this.settings.newestFirst;
  }

  private describe(e: Object): string {
    const err: BusinessError = e as BusinessError;
    Logger.error(`File error. Code: ${err.code}, message: ${err.message}`);
    return err.code !== undefined ? `Error ${err.code}: ${err.message}` : `${err.message}`;
  }
}
