import {
  AppStorageV2,
  ArcButton,
  ArcButtonOptions,
  ArcButtonPosition,
  ArcButtonStyleMode,
  ArcList,
  ArcListAttribute,
  ArcListItem,
  ArcListItemAttribute,
  LengthMetrics
} from '@kit.ArkUI';
import { AppConstants } from '../common/AppConstants';
import { FormatUtil } from '../common/FormatUtil';
import { NotesViewModel } from '../viewmodel/NotesViewModel';
import { ActionChip } from './components/ActionChip';
import { StatRow } from './components/StatRow';
import { StorageGauge } from './components/StorageGauge';

@ComponentV2
export struct StoragePage {
  @Local vm: NotesViewModel =
    AppStorageV2.connect(NotesViewModel, AppConstants.VM_KEY, () => new NotesViewModel())!;

  @Local clearOptions: ArcButtonOptions = new ArcButtonOptions({
    label: 'Clear cache',
    position: ArcButtonPosition.BOTTOM_EDGE,
    styleMode: ArcButtonStyleMode.EMPHASIZED_LIGHT,
    onClick: () => {
      this.vm.clearCache();
    }
  });

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        ArcList({ initialIndex: 0 }) {
          ArcListItem() {
            StorageGauge({
              usedPercent: this.vm.usedPercent,
              freeLabel: `${FormatUtil.bytes(this.vm.storage.freeBytes)} free`,
              warning: this.vm.lowStorage
            })
          }
          .padding({ top: 20 })

          if (this.vm.lowStorage) {
            ArcListItem() {
              Text('Low storage - writes are limited')
                .fontSize(12).fontColor('#FF5A5A').textAlign(TextAlign.Center).width('100%')
            }
          }

          ArcListItem() {
            StatRow({ label: 'App', value: FormatUtil.bytes(this.vm.storage.appBytes) })
          }
          ArcListItem() {
            StatRow({ label: 'Data', value: FormatUtil.bytes(this.vm.storage.dataBytes) })
          }
          ArcListItem() {
            StatRow({ label: 'Cache', value: FormatUtil.bytes(this.vm.storage.cacheBytes) })
          }
          ArcListItem() {
            StatRow({
              label: `Notes (${this.vm.notes.length})`,
              value: FormatUtil.bytes(this.vm.totalNotesBytes)
            })
          }

          ArcListItem() {
            ActionChip({
              label: `Write ${AppConstants.SAMPLE_BATCH_SIZE} samples`,
              onTap: () => this.vm.generateSamples()
            })
          }

          if (this.vm.statusMessage.length > 0) {
            ArcListItem() {
              Text(this.vm.statusMessage)
                .fontSize(12).fontColor('#99FFFFFF').textAlign(TextAlign.Center).width('100%')
            }
          }
        }
        .space(LengthMetrics.vp(6))
        .digitalCrownSensitivity(CrownSensitivity.MEDIUM)
        .focusable(true)
        .defaultFocus(true)
        .width('100%')
        .height('100%')

        ArcButton({ options: this.clearOptions })
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor(Color.Black)
    .onReady(() => {
      this.vm.statusMessage = '';
      this.vm.refreshStorage();
    })
  }
}
