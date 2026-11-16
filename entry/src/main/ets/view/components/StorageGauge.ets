/**
 * Ring gauge: a circular indicator fits a round watch face better than a bar.
 */
@ComponentV2
export struct StorageGauge {
  @Param usedPercent: number = 0;
  @Param freeLabel: string = '';
  @Param warning: boolean = false;

  build() {
    Stack() {
      Progress({ value: this.usedPercent, total: 100, type: ProgressType.Ring })
        .width(96)
        .height(96)
        .color(this.warning ? '#FF5A5A' : '#3AA0FF')
        .style({ strokeWidth: 8 })
      Column() {
        Text(`${this.usedPercent}%`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
        Text(this.freeLabel)
          .fontSize(11)
          .fontColor('#99FFFFFF')
      }
    }
    .width('100%')
  }
}
