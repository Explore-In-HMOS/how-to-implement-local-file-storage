import { fileIo, ListFileOptions, ReadOptions } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { AppConstants } from '../common/AppConstants';
import { Logger } from '../common/Logger';
import { NoteFile, NoteIndexEntry } from '../model/NoteFile';

/**
 * Repository layer: the ONLY place that touches ohos.file.fs.
 * Every method uses the asynchronous API so the UI thread is never blocked.
 */
export class FileService {
  private notesDir: string = '';
  private cacheDir: string = '';
  private decoder: util.TextDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
  private encoder: util.TextEncoder = new util.TextEncoder();

  /**
   * Paths come from ApplicationContext (app-level directories), not from a HAP-level
   * context, so the data survives if a single HAP is uninstalled/updated.
   *   filesDir -> /data/storage/el2/base/files   (persistent, EL2 by default)
   *   cacheDir -> /data/storage/el2/base/cache   (system may clear it at any time)
   */
  init(filesDir: string, cacheDir: string): void {
    this.notesDir = `${filesDir}/${AppConstants.NOTES_DIR_NAME}`;
    this.cacheDir = cacheDir;
  }

  getNotesDir(): string {
    return this.notesDir;
  }

  async ensureNotesDir(): Promise<void> {
    const exists: boolean = await fileIo.access(this.notesDir);
    if (!exists) {
      await fileIo.mkdir(this.notesDir);
      Logger.info(`Created notes dir: ${this.notesDir}`);
    }
  }

  /** Lists notes using a suffix filter, so half-written .tmp files are never shown. */
  async listNotes(previewBytes: number): Promise<NoteFile[]> {
    const options: ListFileOptions = {
      recursion: false,
      listNum: 0,
      filter: { suffix: [AppConstants.NOTE_SUFFIX] }
    };
    const names: string[] = await fileIo.listFile(this.notesDir, options);
    const tasks: Promise<NoteFile>[] = names.map((name: string) => this.buildNote(name, previewBytes));
    return Promise.all(tasks);
  }

  /** Creates a note with an atomic write and returns its metadata. */
  async createNote(content: string): Promise<NoteFile> {
    const byteLength: number = this.encoder.encodeInto(content).byteLength;
    if (byteLength > AppConstants.MAX_NOTE_BYTES) {
      throw new Error(`Note is ${byteLength} bytes, limit is ${AppConstants.MAX_NOTE_BYTES}`);
    }
    await this.ensureNotesDir();
    const fileName: string = `${AppConstants.NOTE_PREFIX}${Date.now()}${AppConstants.NOTE_SUFFIX}`;
    await this.atomicWrite(this.pathOf(fileName), content);
    return this.buildNote(fileName, AppConstants.PREVIEW_BYTES);
  }

  /** Reads a full note, but never more than MAX_NOTE_BYTES into memory. */
  async readNote(fileName: string): Promise<string> {
    const path: string = this.pathOf(fileName);
    const stat: fileIo.Stat = await fileIo.stat(path);
    return this.readBytes(path, Math.min(stat.size, AppConstants.MAX_NOTE_BYTES));
  }

  async deleteNote(fileName: string): Promise<void> {
    await fileIo.unlink(this.pathOf(fileName));
  }

  /** Removes leftovers of writes that were interrupted (e.g. the watch ran out of battery). */
  async cleanupTempFiles(): Promise<void> {
    const options: ListFileOptions = { filter: { suffix: [AppConstants.TMP_SUFFIX] } };
    const names: string[] = await fileIo.listFile(this.notesDir, options);
    for (const name of names) {
      await fileIo.unlink(this.pathOf(name));
      Logger.info(`Removed orphan temp file: ${name}`);
    }
  }

  // ---------- Index cache (cacheDir) ----------

  /** Stores the list metadata so the next launch can render instantly. */
  async saveIndexCache(notes: NoteFile[]): Promise<void> {
    await this.atomicWrite(this.indexCachePath(), JSON.stringify(notes));
  }

  /** cacheDir may be wiped by the system at any time, so a missing cache is normal. */
  async loadIndexCache(): Promise<NoteFile[]> {
    const path: string = this.indexCachePath();
    const exists: boolean = await fileIo.access(path);
    if (!exists) {
      return [];
    }
    const stat: fileIo.Stat = await fileIo.stat(path);
    const text: string = await this.readBytes(path, stat.size);
    const entries: NoteIndexEntry[] = JSON.parse(text) as NoteIndexEntry[];
    return entries.map((e: NoteIndexEntry) => new NoteFile(e.fileName, e.sizeBytes, e.modifiedAt, e.preview));
  }

  /** Deletes everything inside cacheDir and returns how many entries were removed. */
  async clearCache(): Promise<number> {
    const names: string[] = await fileIo.listFile(this.cacheDir);
    let removed: number = 0;
    for (const name of names) {
      const path: string = `${this.cacheDir}/${name}`;
      const stat: fileIo.Stat = await fileIo.stat(path);
      if (stat.isDirectory()) {
        await fileIo.rmdir(path);
      } else {
        await fileIo.unlink(path);
      }
      removed++;
    }
    return removed;
  }

  // ---------- Internals ----------

  private async buildNote(fileName: string, previewBytes: number): Promise<NoteFile> {
    const path: string = this.pathOf(fileName);
    const stat: fileIo.Stat = await fileIo.stat(path);
    // Partial read: only the bytes the list row actually shows.
    const preview: string = await this.readBytes(path, Math.min(previewBytes, stat.size));
    return new NoteFile(fileName, stat.size, stat.mtime * 1000, preview);
  }

  private async readBytes(path: string, length: number): Promise<string> {
    if (length <= 0) {
      return '';
    }
    let file: fileIo.File | undefined = undefined;
    try {
      file = await fileIo.open(path, fileIo.OpenMode.READ_ONLY);
      const buffer: ArrayBuffer = new ArrayBuffer(length);
      const options: ReadOptions = { offset: 0, length: length };
      const readLen: number = await fileIo.read(file.fd, buffer, options);
      return this.decoder.decodeToString(new Uint8Array(buffer, 0, readLen));
    } finally {
      if (file !== undefined) {
        await fileIo.close(file);
      }
    }
  }

  /**
   * Write to "<target>.tmp", fsync, then rename.
   * rename is atomic on the same file system, so a reader sees either
   * the old file or the complete new file - never a half-written one.
   */
  private async atomicWrite(targetPath: string, content: string): Promise<void> {
    const tmpPath: string = `${targetPath}${AppConstants.TMP_SUFFIX}`;
    const file: fileIo.File = await fileIo.open(tmpPath,
      fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
    try {
      await fileIo.write(file.fd, content);
      await fileIo.fsync(file.fd);
    } finally {
      await fileIo.close(file);
    }
    await fileIo.rename(tmpPath, targetPath);
  }

  private pathOf(fileName: string): string {
    return `${this.notesDir}/${fileName}`;
  }

  private indexCachePath(): string {
    return `${this.cacheDir}/${AppConstants.INDEX_CACHE_FILE}`;
  }
}
