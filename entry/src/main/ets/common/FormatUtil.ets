import { AppConstants } from './AppConstants';

export class FormatUtil {
  static bytes(value: number): string {
    const kb: number = 1024;
    const mb: number = kb * 1024;
    const gb: number = mb * 1024;
    if (value < kb) {
      return `${value} B`;
    }
    if (value < mb) {
      return `${(value / kb).toFixed(1)} KB`;
    }
    if (value < gb) {
      return `${(value / mb).toFixed(1)} MB`;
    }
    return `${(value / gb).toFixed(1)} GB`;
  }

  static dateTime(ms: number): string {
    if (ms <= 0) {
      return '-';
    }
    const d: Date = new Date(ms);
    return `${FormatUtil.pad(d.getDate())}.${FormatUtil.pad(d.getMonth() + 1)} ` +
      `${FormatUtil.pad(d.getHours())}:${FormatUtil.pad(d.getMinutes())}`;
  }

  static timestampFromFileName(fileName: string): number {
    const raw: string = fileName.replace(AppConstants.NOTE_PREFIX, '').replace(AppConstants.NOTE_SUFFIX, '');
    const ts: number = Number(raw);
    return Number.isNaN(ts) ? 0 : ts;
  }

  static firstLine(text: string): string {
    const line: string = text.split('\n')[0];
    return line.length > 0 ? line : '(empty)';
  }

  private static pad(n: number): string {
    return n < 10 ? `0${n}` : `${n}`;
  }
}
