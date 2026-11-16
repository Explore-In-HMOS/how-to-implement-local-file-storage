/**
 * Shape used when the note index is serialized to / parsed from the JSON cache.
 */
export interface NoteIndexEntry {
  fileName: string;
  sizeBytes: number;
  modifiedAt: number;
  preview: string;
}

/**
 * Metadata of a note file. The full content is NOT kept here:
 * on a wearable we only hold what the list actually displays.
 */
export class NoteFile implements NoteIndexEntry {
  fileName: string;
  sizeBytes: number;
  modifiedAt: number; // epoch milliseconds
  preview: string;    // first few bytes only

  constructor(fileName: string, sizeBytes: number, modifiedAt: number, preview: string) {
    this.fileName = fileName;
    this.sizeBytes = sizeBytes;
    this.modifiedAt = modifiedAt;
    this.preview = preview;
  }
}
