import { promptAction, router } from '@kit.ArkUI'
import { LogOperationDTO, LogOperationVO, logApi, PageQueryDTO } from '../services/api/log'

@Component
export struct OperationLogTab {
  @State logs: LogOperationVO[] = []
  @State keyword: string = ''
  @State pageNum: number = 1
  @State pageSize: number = 10
  @State total: number = 0
  @State pages: number = 0
  @State hasMore: boolean = true
  @State loading: boolean = false
  @State errorText: string = ''
  @State detailVisible: boolean = false
  @State detailLoading: boolean = false
  @State detail: LogOperationVO | null = null
  @StorageLink('accessToken') @Watch('onAccessTokenChange') accessToken: string = ''

  aboutToAppear(): void {
    if (!this.accessToken) {
      router.replaceUrl({ url: 'pages/Login' })
      return
    }
    this.loadLogs()
  }

  private onAccessTokenChange(): void {
    if (!this.accessToken) {
      router.replaceUrl({ url: 'pages/Login' })
    }
  }

  private async loadLogs(resetPage?: boolean, targetPage?: number): Promise<void> {
    if (this.loading) {
      return
    }
    if (!resetPage && !this.hasMore && this.logs.length > 0) {
      return
    }
    const nextPage = resetPage ? 1 : (targetPage || this.pageNum)
    if (resetPage) {
      this.pageNum = 1
      this.logs = []
      this.hasMore = true
    }
    this.loading = true
    this.errorText = ''
    try {
      const params: LogOperationDTO = {
        name: this.keyword || undefined,
        description: this.keyword || undefined,
        sort: {
          field: 'createTime',
          direction: 'desc'
        }
      }
      const request: PageQueryDTO<LogOperationDTO> = {
        pageNum: nextPage,
        pageSize: this.pageSize,
        params
      }
      const response = await logApi.getLogOperationList(request)
      const records = response.records || []
      this.logs = nextPage === 1 ? records : this.logs.concat(records)
      this.pageNum = response.current
      this.pageSize = response.size
      this.total = response.total
      this.pages = response.pages
      this.hasMore = this.pageNum < this.pages
    } catch (e) {
      const err = e as Error
      this.errorText = err.message || '获取操作日志失败'
      promptAction.showToast({ message: this.errorText })
    } finally {
      this.loading = false
    }
  }

  private loadMore(): void {
    if (!this.hasMore || this.loading) {
      return
    }
    this.loadLogs(false, this.pageNum + 1)
  }

  private async openDetail(log: LogOperationVO): Promise<void> {
    this.detail = null
    this.detailVisible = true
    this.detailLoading = true
    try {
      this.detail = await logApi.getLogOperation(log.id)
    } catch (e) {
      const err = e as Error
      promptAction.showToast({ message: err.message || '获取操作日志详情失败' })
      this.closeDetail()
      return
    } finally {
      this.detailLoading = false
    }
  }

  private closeDetail(): void {
    this.detailVisible = false
    this.detail = null
    this.detailLoading = false
  }

  private statusColor(code: number): ResourceColor {
    if (code >= 200 && code < 300) {
      return '#23A55A'
    }
    if (code >= 400) {
      return $r('app.color.app_danger')
    }
    return $r('app.color.app_primary')
  }

  private statusIcon(code: number): Resource {
    if (code >= 200 && code < 300) {
      return $r('app.media.ic_status_success')
    }
    if (code >= 400) {
      return $r('app.media.ic_status_danger')
    }
    return $r('app.media.ic_status')
  }

  @Builder
  private Meta(icon: Resource, label: string, value: string): void {
    Row({ space: 8 }) {
      Image(icon)
        .width(15)
        .height(15)

      Text(label)
        .width(58)
        .fontSize(12)
        .fontColor($r('app.color.app_text_secondary'))

      Text(value || '-')
        .layoutWeight(1)
        .fontSize(13)
        .fontColor($r('app.color.app_text_primary'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
  }

  @Builder
  private LogCard(log: LogOperationVO): void {
    Column({ space: 9 }) {
      Row({ space: 8 }) {
        Text(log.module || '-')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.app_text_primary'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 4 }) {
          Image(this.statusIcon(log.code))
            .width(14)
            .height(14)

          Text(String(log.code))
            .fontSize(12)
            .fontColor(this.statusColor(log.code))
        }
      }
      .width('100%')

      Text(log.description || '-')
        .fontSize(14)
        .fontColor($r('app.color.app_text_primary'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Row({ space: 8 }) {
        Image($r('app.media.ic_terminal_active'))
          .width(14)
          .height(14)

        Text(log.type || '-')
          .fontSize(12)
          .fontColor($r('app.color.app_primary'))

        Image($r('app.media.ic_server_active'))
          .width(14)
          .height(14)

        Text(log.method || '-')
          .fontSize(12)
          .fontColor($r('app.color.app_text_secondary'))
      }
      .width('100%')

      this.Meta($r('app.media.ic_user_active'), '操作人', log.name || '-')
      this.Meta($r('app.media.ic_route_active'), '请求路径', log.url || '-')
      this.Meta($r('app.media.ic_network_active'), 'IP', log.ip || '-')
      this.Meta($r('app.media.ic_timer_active'), '耗时', `${log.operateTime}ms`)
      this.Meta($r('app.media.ic_calendar'), '时间', log.createTime || '-')

      if (log.errorMessage) {
        Text(log.errorMessage)
          .fontSize(12)
          .fontColor($r('app.color.app_danger'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }

      Row() {
        Text('详情')
          .fontSize(13)
          .fontColor($r('app.color.app_primary'))
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .padding(16)
    .backgroundColor($r('app.color.app_card_bg'))
    .borderRadius(12)
    .width('100%')
    .onClick(() => {
      this.openDetail(log)
    })
  }

  @Builder
  private SectionTitle(icon: Resource, title: string): void {
    Row({ space: 8 }) {
      Image(icon)
        .width(16)
        .height(16)

      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.app_text_primary'))
    }
    .width('100%')
    .margin({ top: 12, bottom: 2 })
  }

  @Builder
  private DetailRow(label: string, value: string, color?: ResourceColor): void {
    Row() {
      Text(label)
        .width(82)
        .fontSize(12)
        .fontColor($r('app.color.app_text_secondary'))

      Text(value || '-')
        .layoutWeight(1)
        .fontSize(13)
        .fontColor(color || $r('app.color.app_text_primary'))
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ top: 7, bottom: 7 })
  }

  @Builder
  private ParamBlock(title: string, value: string, danger?: boolean): void {
    Column({ space: 8 }) {
      this.SectionTitle(danger ? $r('app.media.ic_file_text_danger') : $r('app.media.ic_file_text_active'), title)

      Text(value || '-')
        .fontSize(12)
        .fontColor(danger ? $r('app.color.app_danger') : $r('app.color.app_text_primary'))
        .width('100%')
        .maxLines(100)
        .padding(10)
        .backgroundColor($r('app.color.app_bg'))
        .borderRadius(8)
    }
    .width('100%')
  }

  @Builder
  private DetailPanel(log: LogOperationVO): void {
    Column() {
      Row() {
        Text('操作日志详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.app_text_primary'))
          .layoutWeight(1)

        Button('关闭')
          .height(34)
          .fontSize(13)
          .fontColor($r('app.color.app_primary'))
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.closeDetail()
          })
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 16, bottom: 10 })

      Scroll() {
        Column({ space: 8 }) {
          if (this.detailLoading) {
            Text('刷新详情中...')
              .fontSize(12)
              .fontColor($r('app.color.app_text_secondary'))
              .width('100%')
          }

          this.SectionTitle($r('app.media.ic_file_text_active'), '基本信息')
          this.DetailRow('日志ID', String(log.id))
          this.DetailRow('操作人', log.name || '未知')
          this.DetailRow('模块', log.module || '-')
          this.DetailRow('操作描述', log.description || '无描述')

          this.SectionTitle($r('app.media.ic_terminal_active'), '请求信息')
          this.DetailRow('操作类型', log.type || '-', $r('app.color.app_primary'))
          this.DetailRow('请求方法', log.method || '-', $r('app.color.app_primary'))
          this.DetailRow('状态码', String(log.code), this.statusColor(log.code))
          this.DetailRow('IP地址', log.ip || '-')
          this.DetailRow('请求路径', log.url || '-')

          this.SectionTitle($r('app.media.ic_timer_active'), '时间信息')
          this.DetailRow('操作时间', `${log.operateTime}ms`)
          this.DetailRow('创建时间', log.createTime || '-')

          if (log.requestParam) {
            this.ParamBlock('请求参数', log.requestParam)
          }

          if (log.responseParam) {
            this.ParamBlock('响应参数', log.responseParam)
          }

          if (log.errorMessage) {
            this.ParamBlock('错误信息', log.errorMessage, true)
          }
        }
        .padding({ left: 18, right: 18, bottom: 24 })
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('82%')
    .backgroundColor($r('app.color.app_card_bg'))
    .borderRadius({ topLeft: 24, topRight: 24 })
  }

  @Builder
  private DetailOverlay(): void {
    Stack({ alignContent: Alignment.Bottom }) {
      Stack() {
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#66000000')
      .onClick(() => {
        this.closeDetail()
      })

      if (this.detail !== null) {
        this.DetailPanel(this.detail)
      }
    }
    .width('100%')
    .height('100%')
  }

  build() {
    Stack() {
      Column() {
        Column() {
          Row({ space: 10 }) {
            TextInput({ text: this.keyword, placeholder: '搜索操作人或操作描述' })
              .layoutWeight(1)
              .height(40)
              .fontSize(14)
              .backgroundColor($r('app.color.app_bg'))
              .fontColor($r('app.color.app_text_primary'))
              .placeholderColor($r('app.color.app_text_secondary'))
              .caretColor($r('app.color.app_primary'))
              .borderRadius(20)
              .onChange((next: string) => {
                this.keyword = next
              })

            Button() {
              Image($r('app.media.ic_search_light'))
                .width(18)
                .height(18)
            }
              .width(46)
              .height(40)
              .backgroundColor($r('app.color.app_primary'))
              .borderRadius(20)
              .onClick(() => {
                this.loadLogs(true)
              })

          }
      .width('100%')
      .padding({ left: 14, right: 14, top: 44, bottom: 8 })
    }
    .width('100%')
    .backgroundColor($r('app.color.app_card_bg'))
    .borderRadius({ bottomLeft: 24, bottomRight: 24 })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

          Column({ space: 12 }) {
            if (this.errorText) {
              Text(this.errorText)
                .fontSize(12)
                .fontColor($r('app.color.app_danger'))
                .width('100%')
                .padding({ left: 14, right: 14 })
            }

            Scroll() {
              Column({ space: 16 }) {
                if (this.loading && this.logs.length === 0) {
                  Text('加载操作日志中...')
                    .fontSize(14)
                    .fontColor($r('app.color.app_text_secondary'))
                    .width('100%')
                    .padding(18)
                } else if (this.logs.length === 0) {
                  Text('暂无操作日志')
                    .fontSize(14)
                    .fontColor($r('app.color.app_text_secondary'))
                    .width('100%')
                    .padding(18)
                } else {
                  ForEach(this.logs, (log: LogOperationVO) => {
                    this.LogCard(log)
                  }, (log: LogOperationVO) => String(log.id))

                  if (this.loading) {
                    Text('继续加载操作日志中...')
                      .fontSize(12)
                      .fontColor($r('app.color.app_text_secondary'))
                      .textAlign(TextAlign.Center)
                      .width('100%')
                      .padding({ top: 8, bottom: 10 })
                  } else if (!this.hasMore) {
                    Text(`已加载全部 ${this.total} 条操作日志`)
                      .fontSize(12)
                      .fontColor($r('app.color.app_text_secondary'))
                      .textAlign(TextAlign.Center)
                      .width('100%')
                      .padding({ top: 8, bottom: 10 })
                  }
                }
              }
              .padding({ left: 14, right: 14, top: 12, bottom: 8 })
              .width('100%')
            }
            .onReachEnd(() => {
              this.loadMore()
            })
            .layoutWeight(1)
          }
          .layoutWeight(1)
          .backgroundColor($r('app.color.app_bg'))
      }
      .backgroundColor($r('app.color.app_bg'))
      .width('100%')
      .height('100%')

      if (this.detailVisible) {
        this.DetailOverlay()
      }
    }
    .backgroundColor($r('app.color.app_bg'))
    .width('100%')
    .height('100%')
  }
}
