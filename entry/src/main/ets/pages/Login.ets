import { promptAction, router } from '@kit.ArkUI'
import { AuthStore } from '../stores/authStore'

const authStore = AuthStore.getInstance()

@Entry
@Preview
@Component
struct Index {
  @State username: string = ''
  @State password: string = ''
  @State loading: boolean = false
  @State errorText: string = ''

  @StorageLink('accessToken') @Watch('onAccessTokenChange') accessToken: string = ''
  @StorageLink('refreshToken') refreshToken: string = ''
  @StorageLink('username') loggedUsername: string = ''

  aboutToAppear(): void {
    this.goProfileIfLoggedIn()
  }

  private onAccessTokenChange(): void {
    this.goProfileIfLoggedIn()
  }

  private goProfileIfLoggedIn(): void {
    if (!this.accessToken) {
      return
    }
    router.replaceUrl({ url: 'pages/Profile' })
  }

  private canSubmit(): boolean {
    return !!this.username.trim() && !!this.password && !this.loading
  }

  private async onLogin(): Promise<void> {
    this.errorText = ''

    if (!this.username.trim() || !this.password) {
      this.errorText = '请输入用户名和密码'
      return
    }

    if (this.loading) {
      return
    }

    this.loading = true
    try {
      await authStore.login(this.username.trim(), this.password)
      promptAction.showToast({ message: '登录成功' })
      router.replaceUrl({ url: 'pages/Profile' })
    } catch (e) {
      const err = e as Error
      const msg = err.message || '登录失败'
      this.errorText = msg
      promptAction.showToast({ message: msg })
    } finally {
      this.loading = false
    }
  }

  private async onLogout(): Promise<void> {
    try {
      await authStore.logout()
    } catch (e) {
      void e
    }
    this.password = ''
    this.errorText = ''
    promptAction.showToast({ message: '已退出登录' })
  }

  @Builder
  private InputField(placeholder: string, value: string, onValueChange: (next: string) => void, isPassword?: boolean): void {
    Column({ space: 8 }) {
      TextInput({ placeholder, text: value })
        .height(40)
        .padding({ left: 0, right: 0 })
        .fontSize(16)
        .fontColor($r('app.color.app_text_primary'))
        .placeholderColor($r('app.color.app_text_secondary'))
        .backgroundColor(Color.Transparent)
        .borderRadius(0)
        .caretColor($r('app.color.app_primary'))
        .type(isPassword ? InputType.Password : InputType.Normal)
        .onChange((next: string) => {
          onValueChange(next)
        })

      Stack() {
      }
      .height(1)
      .width('100%')
      .backgroundColor($r('app.color.app_border'))
    }
    .width('100%')
  }

  @Builder
  private LoginView(): void {
    Column({ space: 28 }) {
      Column({ space: 8 }) {
        Text('Auth Matrix')
          .fontSize(34)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.app_text_primary'))

        Text('欢迎回来')
          .fontSize(14)
          .fontColor($r('app.color.app_text_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Column({ space: 16 }) {
        this.InputField('请输入用户名', this.username, (next: string) => {
          this.username = next
          this.errorText = ''
        })

        Column({ space: 6 }) {
          this.InputField('请输入密码', this.password, (next: string) => {
            this.password = next
            this.errorText = ''
          }, true)

          Text(this.errorText || ' ')
            .height(16)
            .width('100%')
            .fontSize(12)
            .fontColor($r('app.color.app_danger'))
            .opacity(this.errorText ? 1 : 0)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')

        Button(this.loading ? '登录中...' : '登录')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.app_primary'))
          .borderRadius(24)
          .enabled(this.canSubmit())
          .onClick(() => {
            this.onLogin()
          })
      }
      .width('100%')

      Text('登录即代表你同意服务条款与隐私政策')
        .fontSize(12)
        .fontColor($r('app.color.app_text_secondary'))
        .opacity(0.8)
      .width('100%')
    }
    .width('100%')
    .padding({ left: 20, right: 20 })
    .constraintSize({ maxWidth: 420 })
  }

  build() {
    Column() {
      if (this.accessToken) {
        Text('正在进入...')
          .fontSize(14)
          .fontColor($r('app.color.app_text_secondary'))
      } else {
        this.LoginView()
      }
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 14, right: 14 })
    .backgroundColor($r('app.color.app_bg'))
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
