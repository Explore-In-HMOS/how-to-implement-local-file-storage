export class AppConstants {
  // Storage keys (AppStorageV2 / PersistenceV2)
  static readonly VM_KEY: string = 'notesViewModel';
  static readonly SETTINGS_KEY: string = 'appSettings';

  // Navigation routes
  static readonly ROUTE_DETAIL: string = 'detail';
  static readonly ROUTE_STORAGE: string = 'storage';

  // File layout inside the sandbox
  static readonly NOTES_DIR_NAME: string = 'notes';
  static readonly NOTE_PREFIX: string = 'note_';
  static readonly NOTE_SUFFIX: string = '.txt';
  static readonly TMP_SUFFIX: string = '.tmp';
  static readonly INDEX_CACHE_FILE: string = 'notes_index.json';

  // Wearable-friendly limits
  static readonly MAX_NOTE_BYTES: number = 4 * 1024;            // hard cap per note
  static readonly PREVIEW_BYTES: number = 48;                   // partial read for list rows
  static readonly LOW_STORAGE_BYTES: number = 50 * 1024 * 1024; // warn below 50 MB
  static readonly SAMPLE_BATCH_SIZE: number = 20;

  // Typing on a watch is hard: notes are created from one-tap templates.
  static readonly QUICK_TEMPLATES: string[] = [
    'Water: 250 ml',
    'Workout started',
    'Workout finished',
    'Heart rate checked',
    'Short walk done',
    'Meditation: 5 min'
  ];
}
