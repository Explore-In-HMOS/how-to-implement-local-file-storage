import { AppStorageV2, ArcButton, ArcButtonOptions, ArcButtonPosition, ArcButtonStyleMode } from '@kit.ArkUI';
import { AppConstants } from '../common/AppConstants';
import { FormatUtil } from '../common/FormatUtil';
import { NotesViewModel } from '../viewmodel/NotesViewModel';

@ComponentV2
export struct NoteDetailPage {
  @Require @Param fileName: string = '';
  @Local vm: NotesViewModel =
    AppStorageV2.connect(NotesViewModel, AppConstants.VM_KEY, () => new NotesViewModel())!;
  private pathStack: NavPathStack | undefined = undefined;

  @Local deleteOptions: ArcButtonOptions = new ArcButtonOptions({
    label: 'Delete',
    position: ArcButtonPosition.BOTTOM_EDGE,
    styleMode: ArcButtonStyleMode.EMPHASIZED_DARK,
    onClick: () => {
      this.onDelete();
    }
  });

  private async onDelete(): Promise<void> {
    await this.vm.deleteNote(this.fileName);
    this.pathStack?.pop();
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Scroll() {
          Column({ space: 8 }) {
            Text(FormatUtil.dateTime(FormatUtil.timestampFromFileName(this.fileName)))
              .fontSize(12)
              .fontColor('#99FFFFFF')
            Text(this.vm.currentContent)
              .fontSize(16)
              .fontColor(Color.White)
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          // Generous padding keeps text inside the round screen's safe area.
          .padding({ top: 48, left: 28, right: 28, bottom: 80 })
        }
        .scrollBar(BarState.Off)
        .width('100%')
        .height('100%')

        ArcButton({ options: this.deleteOptions })
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor(Color.Black)
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
      this.vm.openNote(this.fileName);
    })
  }
}
