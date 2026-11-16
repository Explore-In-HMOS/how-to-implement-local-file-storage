import { fileIo } from '@kit.CoreFileKit';

/**
 * Runs on a TaskPool worker thread, so synchronous fileIo APIs are fine here:
 * they block the worker, not the UI thread.
 * Concurrent functions cannot capture outer variables - everything comes in as arguments.
 */
@Concurrent
export function writeSampleNotes(notesDir: string, count: number, startTs: number): number {
  let written: number = 0;
  for (let i = 0; i < count; i++) {
    const path: string = `${notesDir}/note_${startTs + i}.txt`;
    const file: fileIo.File = fileIo.openSync(path,
      fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
    try {
      fileIo.writeSync(file.fd, `Sample note #${i + 1}\nGenerated on a TaskPool worker.`);
      written++;
    } finally {
      fileIo.closeSync(file);
    }
  }
  return written;
}
