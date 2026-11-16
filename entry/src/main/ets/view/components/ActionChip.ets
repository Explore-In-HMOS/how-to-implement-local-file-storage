@ComponentV2
export struct ActionChip {
  @Param label: string = '';
  @Event onTap: () => void = () => {};

  build() {
    Text(this.label)
      .fontSize(14)
      .fontColor(Color.White)
      .textAlign(TextAlign.Center)
      .width('100%')
      .padding({ top: 12, bottom: 12 })
      .backgroundColor('#333333')
      .borderRadius(24)
      .onClick(() => this.onTap())
  }
}
