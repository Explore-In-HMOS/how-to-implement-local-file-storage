@ComponentV2
export struct StatRow {
  @Param label: string = '';
  @Param value: string = '';

  build() {
    Row() {
      Text(this.label).fontSize(14).fontColor('#99FFFFFF')
      Blank()
      Text(this.value).fontSize(14).fontColor(Color.White)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 6, bottom: 6 })
  }
}
