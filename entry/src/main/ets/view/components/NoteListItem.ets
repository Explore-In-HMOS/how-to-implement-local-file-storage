import { FormatUtil } from '../../common/FormatUtil';
import { NoteFile } from '../../model/NoteFile';

@ComponentV2
export struct NoteListItem {
  @Require @Param note: NoteFile;
  @Event onTap: (fileName: string) => void = () => {};

  build() {
    Column({ space: 2 }) {
      Text(FormatUtil.firstLine(this.note.preview))
        .fontSize(15)
        .fontColor(Color.White)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(`${FormatUtil.dateTime(this.note.modifiedAt)} · ${FormatUtil.bytes(this.note.sizeBytes)}`)
        .fontSize(12)
        .fontColor('#99FFFFFF')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .backgroundColor('#262626')
    .borderRadius(24)
    .onClick(() => this.onTap(this.note.fileName))
  }
}
