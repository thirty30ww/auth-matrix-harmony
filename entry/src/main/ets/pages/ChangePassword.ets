import { promptAction, router } from '@kit.ArkUI'
import { ChangePasswordDTO, userApi } from '../services/api/user'

@Entry
@Component
struct ChangePassword {
  @State saving: boolean = false
  @State errorText: string = ''
  @State currentPassword: string = ''
  @State newPassword: string = ''
  @State confirmPassword: string = ''
  private errorTimer: number = -1
  @StorageLink('accessToken') @Watch('onAccessTokenChange') accessToken: string = ''

  aboutToAppear(): void {
    if (!this.accessToken) {
      router.replaceUrl({ url: 'pages/Login' })
    }
  }

  private onAccessTokenChange(): void {
    if (!this.accessToken) {
      router.replaceUrl({ url: 'pages/Login' })
    }
  }

  aboutToDisappear(): void {
    this.clearError()
  }

  private async changePassword(): Promise<void> {
    if (this.saving) {
      return
    }
    if (!this.currentPassword || !this.newPassword || !this.confirmPassword) {
      this.showError('请完整填写密码信息')
      return
    }
    this.saving = true
    this.clearError()
    try {
      const dto: ChangePasswordDTO = {
        currentPassword: this.currentPassword,
        newPassword: this.newPassword,
        confirmPassword: this.confirmPassword
      }
      await userApi.changePassword(dto, false)
      const currentVersion = AppStorage.get('profileRefreshVersion') as number || 0
      AppStorage.setOrCreate('profileRefreshVersion', currentVersion + 1)
      this.saving = false
      promptAction.showToast({ message: '密码修改成功', duration: 1500 })
      router.back()
    } catch (e) {
      const err = e as Error
      this.showError(err.message || '修改密码失败')
      this.saving = false
    }
  }

  private clearError(): void {
    this.errorText = ''
    if (this.errorTimer !== -1) {
      clearTimeout(this.errorTimer)
      this.errorTimer = -1
    }
  }

  private showError(message: string): void {
    this.clearError()
    this.errorText = message
    this.errorTimer = setTimeout(() => {
      this.errorText = ''
      this.errorTimer = -1
    }, 3000)
  }

  @Builder
  private TopBar(): void {
    Row() {
      Button() {
        Image($r('app.media.ic_arrow_left_active'))
          .width(20)
          .height(20)
      }
      .width(42)
      .height(38)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        router.back()
      })

      Text('修改密码')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.app_text_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Blank()
        .width(42)
    }
    .width('100%')
    .height(54)
    .padding({ left: 14, right: 14 })
  }

  @Builder
  private PasswordField(label: string, value: string, onChange: (next: string) => void): void {
    Column({ space: 8 }) {
      TextInput({ text: value, placeholder: label })
        .height(40)
        .padding({ left: 0, right: 0 })
        .fontSize(16)
        .fontColor($r('app.color.app_text_primary'))
        .placeholderColor($r('app.color.app_text_secondary'))
        .backgroundColor(Color.Transparent)
        .borderRadius(0)
        .caretColor($r('app.color.app_primary'))
        .type(InputType.Password)
        .onChange((next: string) => {
          onChange(next)
          this.clearError()
        })

      Stack()
        .height(1)
        .width('100%')
        .backgroundColor($r('app.color.app_border'))
    }
    .width('100%')
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Column() {
        Scroll() {
          Column({ space: 14 }) {
            Text(this.errorText || ' ')
              .height(18)
              .fontSize(12)
              .fontColor($r('app.color.app_danger'))
              .width('100%')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .opacity(this.errorText ? 1 : 0)

            Column({ space: 22 }) {
              this.PasswordField('当前密码', this.currentPassword, (next: string) => {
                this.currentPassword = next
              })
              this.PasswordField('新密码', this.newPassword, (next: string) => {
                this.newPassword = next
              })
              this.PasswordField('确认新密码', this.confirmPassword, (next: string) => {
                this.confirmPassword = next
              })
            }
            .padding(18)
            .backgroundColor($r('app.color.app_card_bg'))
            .borderRadius(16)
            .width('100%')

            Button(this.saving ? '修改中...' : '修改密码')
              .height(48)
              .width('100%')
              .fontSize(16)
              .fontColor(Color.White)
              .backgroundColor($r('app.color.app_primary'))
              .borderRadius(24)
              .enabled(!this.saving)
              .onClick(() => {
                this.changePassword()
              })
          }
          .padding({ left: 14, right: 14, top: 12, bottom: 18 })
          .width('100%')
        }
        .width('100%')
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height('100%')

      Column() {
        this.TopBar()
      }
      .width('100%')
      .padding({ top: 42 })
    }
    .backgroundColor($r('app.color.app_bg'))
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
