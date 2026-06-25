import { router } from '@kit.ArkUI'
import { fileApi } from '../services/api/system'
import { UpdateUserDTO, userApi, UserVO } from '../services/api/user'

@Entry
@Component
struct EditProfile {
  @State user: UserVO | null = null
  @State loading: boolean = false
  @State saving: boolean = false
  @State uploading: boolean = false
  @State errorText: string = ''
  @State name: string = ''
  @State sex: string = '未知'
  @State signature: string = ''
  @State avatarUrl: string = ''
  private errorTimer: number = -1
  @StorageLink('accessToken') @Watch('onAccessTokenChange') accessToken: string = ''

  aboutToAppear(): void {
    if (!this.accessToken) {
      router.replaceUrl({ url: 'pages/Login' })
      return
    }
    this.loadUser()
  }

  private onAccessTokenChange(): void {
    if (!this.accessToken) {
      router.replaceUrl({ url: 'pages/Login' })
    }
  }

  aboutToDisappear(): void {
    this.clearError()
  }

  private async loadUser(): Promise<void> {
    this.loading = true
    this.clearError()
    try {
      const user = await userApi.getUser()
      this.user = user
      this.name = user.name || ''
      this.sex = user.sex || '未知'
      this.signature = user.signature || ''
      this.avatarUrl = user.avatarUrl || ''
    } catch (e) {
      const err = e as Error
      this.showError(err.message || '获取用户信息失败')
    } finally {
      this.loading = false
    }
  }

  private async saveInfo(): Promise<void> {
    if (this.user === null || this.saving) {
      return
    }
    this.saving = true
    this.clearError()
    try {
      const dto: UpdateUserDTO = {
        id: this.user.id,
        name: this.name,
        avatarUrl: this.avatarUrl,
        sex: this.sex,
        signature: this.signature
      }
      await userApi.updateUser(dto, false)
      const currentVersion = AppStorage.get('profileRefreshVersion') as number || 0
      AppStorage.setOrCreate('profileRefreshVersion', currentVersion + 1)
      this.saving = false
      router.replaceUrl({
        url: 'pages/Profile',
        params: {
          toastMessage: '个人信息修改成功',
          toastKey: new Date().getTime().toString()
        }
      })
    } catch (e) {
      const err = e as Error
      this.showError(err.message || '保存失败')
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

  private getAvatarText(): string {
    let text = this.name
    if (!text && this.user !== null) {
      text = this.user.username
    }
    if (!text) {
      text = 'U'
    }
    return text.substring(0, 1)
  }

  private chooseAvatar(): void {
    if (this.user === null || this.uploading) {
      return
    }
    this.showError('预览器暂不支持选择头像，真机接入后会上传到 /file/upload/image')
  }

  private async uploadAvatar(fileUri: string): Promise<void> {
    if (this.user === null) {
      return
    }

    this.uploading = true
    try {
      const imageUrl = await fileApi.uploadImage(fileUri)
      if (!imageUrl) {
        throw new Error('上传失败')
      }

      this.avatarUrl = imageUrl
      await userApi.updateUser({
        id: this.user.id,
        avatarUrl: imageUrl
      }, false)
    } catch (e) {
      const err = e as Error
      this.showError(err.message || '头像上传失败')
    } finally {
      this.uploading = false
    }
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

      Text('编辑个人信息')
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
  private AvatarEditor(): void {
    Column({ space: 10 }) {
      Stack({ alignContent: Alignment.BottomEnd }) {
        if (this.avatarUrl) {
          Image(this.avatarUrl)
            .width(92)
            .height(92)
            .borderRadius(46)
            .objectFit(ImageFit.Cover)
        } else {
          Stack() {
            Text(this.getAvatarText())
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.app_primary'))
          }
          .width(92)
          .height(92)
          .borderRadius(46)
          .backgroundColor('#F3EEFF')
        }

        Stack() {
          Image($r('app.media.ic_camera_active'))
            .width(18)
            .height(18)
        }
        .width(32)
        .height(32)
        .borderRadius(16)
        .backgroundColor(Color.White)
        .border({ width: 1, color: $r('app.color.app_border') })
      }
      .width(98)
      .height(98)
      .onClick(() => {
        this.chooseAvatar()
      })

      Text(this.uploading ? '上传中...' : '点击修改头像')
        .fontSize(12)
        .fontColor($r('app.color.app_primary'))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private NameField(): void {
    Column({ space: 8 }) {
      Row({ space: 10 }) {
        Image($r('app.media.ic_user_active'))
          .width(18)
          .height(18)

        TextInput({ text: $$this.name, placeholder: '请输入姓名' })
          .height(40)
          .padding({ left: 0, right: 0 })
          .fontSize(16)
          .fontColor($r('app.color.app_text_primary'))
          .placeholderColor($r('app.color.app_text_secondary'))
          .backgroundColor(Color.Transparent)
          .borderRadius(0)
          .caretColor($r('app.color.app_primary'))
          .layoutWeight(1)
          .onChange(() => {
            this.clearError()
          })
      }

      Stack()
        .height(1)
        .width('100%')
        .backgroundColor($r('app.color.app_border'))
    }
    .width('100%')
  }

  @Builder
  private SexField(): void {
    Column({ space: 8 }) {
      Row({ space: 10 }) {
        Image($r('app.media.ic_gender'))
          .width(18)
          .height(18)

        Row({ space: 8 }) {
          this.SexOption('男')
          this.SexOption('女')
          this.SexOption('未知')
        }
        .layoutWeight(1)
      }
      .width('100%')

      Stack()
        .height(1)
        .width('100%')
        .backgroundColor($r('app.color.app_border'))
    }
    .width('100%')
  }

  @Builder
  private SexOption(value: string): void {
    Button(value)
      .height(32)
      .padding({ left: 16, right: 16 })
      .fontSize(14)
      .fontColor(this.sex === value ? Color.White : $r('app.color.app_text_secondary'))
      .backgroundColor(this.sex === value ? $r('app.color.app_primary') : '#F4F1FA')
      .borderRadius(16)
      .onClick(() => {
        this.sex = value
        this.clearError()
      })
  }

  @Builder
  private SignatureField(): void {
    Column({ space: 8 }) {
      Row({ space: 10 }) {
        Image($r('app.media.ic_edit'))
          .width(18)
          .height(18)

        TextArea({ text: $$this.signature, placeholder: '请输入个性签名' })
          .height(74)
          .padding({ left: 0, right: 0 })
          .fontSize(16)
          .fontColor($r('app.color.app_text_primary'))
          .placeholderColor($r('app.color.app_text_secondary'))
          .backgroundColor(Color.Transparent)
          .borderRadius(0)
          .caretColor($r('app.color.app_primary'))
          .layoutWeight(1)
          .onChange(() => {
            this.clearError()
          })
      }

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

            Column({ space: 20 }) {
              this.AvatarEditor()

              this.NameField()
              this.SexField()
              this.SignatureField()
            }
            .padding(18)
            .backgroundColor($r('app.color.app_card_bg'))
            .borderRadius(16)
            .width('100%')

            Button() {
              Row({ space: 8 }) {
                Image($r('app.media.ic_save_light'))
                  .width(18)
                  .height(18)
                Text(this.saving ? '保存中...' : '保存修改')
                  .fontSize(16)
                  .fontColor(Color.White)
              }
              .justifyContent(FlexAlign.Center)
            }
            .height(48)
            .width('100%')
            .backgroundColor($r('app.color.app_primary'))
            .borderRadius(24)
            .enabled(!this.loading && !this.saving && !this.uploading && this.user !== null)
            .onClick(() => {
              this.saveInfo()
            })
          }
          .width('100%')
          .padding({ left: 14, right: 14, top: 12, bottom: 18 })
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
