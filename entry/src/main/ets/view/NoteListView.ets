import {
  ArcButton,
  ArcButtonOptions,
  ArcButtonPosition,
  ArcButtonStyleMode,
  ArcList,
  ArcListAttribute,     // Required to import manually up to API 21; harmless on newer versions.
  ArcListItem,
  ArcListItemAttribute, // Same as above.
  LengthMetrics
} from '@kit.ArkUI';
import { NoteFile } from '../model/NoteFile';
import { NotesViewModel } from '../viewmodel/NotesViewModel';
import { NoteListItem } from './components/NoteListItem';
import { ActionChip } from './components/ActionChip';

@ComponentV2
export struct NoteListView {
  @Require @Param vm: NotesViewModel;
  @Event onOpenNote: (fileName: string) => void = () => {};
  @Event onOpenStorage: () => void = () => {};

  @Local addOptions: ArcButtonOptions = new ArcButtonOptions({
    label: '+ Quick note',
    position: ArcButtonPosition.BOTTOM_EDGE,
    styleMode: ArcButtonStyleMode.EMPHASIZED_LIGHT,
    onClick: () => {
      this.vm.addQuickNote();
    }
  });

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      ArcList({ initialIndex: 0 }) {
        // Header: title + count. Tap toggles sort order (persisted via PersistenceV2).
        ArcListItem() {
          Column({ space: 2 }) {
            Text('Notes').fontSize(18).fontWeight(FontWeight.Bold).fontColor(Color.White)
            Text(`${this.vm.notes.length} files · ${this.vm.settings.newestFirst ? 'newest' : 'oldest'} first`)
              .fontSize(12)
              .fontColor('#99FFFFFF')
          }
          .width('100%')
          .padding({ top: 24, bottom: 4 })
          .onClick(() => this.vm.toggleSort())
        }

        if (this.vm.isLoading && this.vm.notes.length === 0) {
          ArcListItem() {
            LoadingProgress().width(32).height(32).color(Color.White)
          }
        }

        if (this.vm.errorMessage.length > 0) {
          ArcListItem() {
            Text(this.vm.errorMessage).fontSize(12).fontColor('#FF5A5A').textAlign(TextAlign.Center).width('100%')
          }
        }

        ForEach(this.vm.sortedNotes, (note: NoteFile) => {
          ArcListItem() {
            NoteListItem({
              note: note,
              onTap: (fileName: string) => this.onOpenNote(fileName)
            })
          }
        }, (note: NoteFile) => note.fileName)

        if (!this.vm.isLoading && this.vm.notes.length === 0) {
          ArcListItem() {
            Text('No notes yet.\nTap the button below.')
              .fontSize(13).fontColor('#99FFFFFF').textAlign(TextAlign.Center).width('100%')
          }
        }

        ArcListItem() {
          ActionChip({ label: 'Storage', onTap: () => this.onOpenStorage() })
        }
      }
      .space(LengthMetrics.vp(8))
      .cachedCount(2)                                     // pre-build only a few off-screen items
      .digitalCrownSensitivity(CrownSensitivity.MEDIUM)   // rotate the crown to scroll
      .focusable(true)                                    // crown events go to the focused component
      .defaultFocus(true)
      .width('100%')
      .height('100%')

      ArcButton({ options: this.addOptions })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black) // pure black saves power on OLED watch screens
  }
}
