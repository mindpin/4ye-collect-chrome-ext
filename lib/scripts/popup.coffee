HOST = "http://collect.4ye.me"
ANIMATE_DURATION = 200

STRING_AUTH = '正在获取用户信息 …'

STRING_INIT = '正在加载数据 …'
STRING_SAVING = '正在努力保存 …'
STRING_SUCCESS = '✔ 保存好了。'
STRING_FAILURE = '出错了！'
STRING_COLLECTED = '这个网页已经收集过了。'

show_loading_after = ($dom, info)->
  l = new Loading()
  l.show_after $dom, info
  l

# 载入提示
class Loading
  constructor: ->
    @$_el = jQuery('.loading').first().clone()

  # 在指定的 dom 下方显示载入提示
  show_after: ($dom, info)->
    @$_el
      .show()
      .find('.info').text info
    $dom.after @$_el

  remove: ->
    # @$_el.slideUp ANIMATE_DURATION, =>
    #   @$_el.remove()
    @$_el.remove()


# 基本信息
class UrlInfo
  constructor: (@$el)->
    @$icon = @$el.find('.icon')
    @$title = @$el.find('.title')
    @$url = @$el.find('.url')
    @$chrome_tip = @$el.find('.chrome-tip')

  # 从当前的页签中获取网址和icon等信息
  load: (func)->
    chrome.tabs.query
      active: true
      currentWindow: true
      (tabs)=>
        current_tab = tabs[0]
        @_fill_url_info current_tab, func

  _fill_url_info: (current_tab, func)->
    @url = current_tab.url.trim()
    @title = current_tab.title.trim()
    @title = '无标题网页' if @url.indexOf(@title) > -1
    @fav_icon_url = current_tab.favIconUrl

    if @url.indexOf('chrome://') > -1
      @$icon.hide()
      @$title.hide()
      @$url.hide()
      @$chrome_tip.show()
      return

    if not @fav_icon_url?
      @$icon.hide()
    else
      @$icon.css 'background-image', "url(#{@fav_icon_url})"

    @$title.text @title
    @$url.text @url

    func()


# 短网址和二维条码
class ShortUrlInfo
  constructor: (@$el)->
    @$short = @$el.find('.short .url')
    @$qrcode_url = @$el.find('.qrcode .url')
    @$qrcode_img = @$el.find('.qrcode .img')

  load: (url, func)->
    jQuery.ajax
      url: "http://s.4ye.me/parse"
      type: 'POST'
      data:
        long_url: url
    .done (res)=>
      @$short.text res.short_url
      qrcode_url = res.qrcode
      @$qrcode_url.text qrcode_url
      @$qrcode_img.css 'background-image', "url(#{qrcode_url})"

    .fail (res)=>
      # TODO: 短网址和二维条码加载失败
      console.log res

    .always =>
      @$el.fadeIn(ANIMATE_DURATION)
      func()

class Auth
  constructor: (@$el, @popup)->
    @$signin_btn = @$el.find('.signin')

  go: (func)->
    jQuery.ajax "#{HOST}/api/auth_check"
      .done (res)=>
        # 验证通过，显示用户信息
        # console.log res
        avatar = res.avatar
        name = res.name
        jQuery('.user-info .avatar').css 'background-image', "url(#{avatar})"
        jQuery('.user-info .name').text name
        jQuery('.user-info').fadeIn(ANIMATE_DURATION)

        # 显示表单
        @popup.show_form()

      .fail (err)=>
        # 验证未通过，显示登录按钮
        @$el.fadeIn(ANIMATE_DURATION)

      .always =>
        func()

class Form
  constructor: (@$el)->
    @$inputs = @$el.find('.inputs')
    @$buttons = @$el.find('.buttons')
    @$collected = @$el.find('.collected')

    @$title_input = @$inputs.find('input[name=title]')
    @$desc_input = @$inputs.find('textarea[name=desc]')
    @$tags_input = @$inputs.find('input[name=tags]')
    @$image = @$inputs.find('.screenshot')

    @$submit_btn = @$buttons.find('a.submit')

    @bind_events()

  load: (@url_info, func)->
    url = @url_info.url
    title = @url_info.title

    # console.log url
    # 检查网址是否被收藏过
    jQuery.ajax 
      url: "#{HOST}/api/check_url"
      data:
        url: url

    .done (res)=>
      console.log '网址收藏检查结果', res

      if !res.collected
        @show(title)
        return

      @collected(res.data)

    .fail (res)=>
      console.log '网址检查出错', res

    .always =>
      func()

  show: (title)->
    @$inputs.fadeIn(ANIMATE_DURATION)
    @$buttons.fadeIn(ANIMATE_DURATION)
    @$collected.hide()

    @$title_input.val title
    # TODO 获取页面 jQuery('meta[name=description]').attr('content')
    # 需要用到消息机制

    # 获取网页截图
    chrome.tabs.captureVisibleTab null, {
      format: 'png'
    }, (src)=>
      @$image.css 'background-image', "url(#{src})"
      @image_base64_src = src

  collected: (data)->
    # 显示已经收集过了
    @$inputs.hide()
    @$collected.fadeIn(ANIMATE_DURATION)
    @$buttons
      .fadeIn(ANIMATE_DURATION)
      .addClass 'collected'

    @$collected.find('a.siye')
      .attr 'href', data.site_url

    # console.log data
    tags = data.tags
    if tags.length
      # 如果有 tag 则显示
      @$collected.find('.notag').hide()
      for tag in tags
        $tag = jQuery('<span>')
          .addClass 'tag'
          .text "##{tag}"
          .appendTo @$collected.find('.tags')



  bind_events: ->
    @$buttons.delegate 'a.close', 'click', ->
      window.close()

    @$buttons.delegate 'a.submit:not(.disabled)', 'click', =>
      title = @$title_input.val()
      desc = @$desc_input.val()
      tags = @$tags_input.val()

      # 处理 tag 字符串
      # 按照 全角/半角 逗号/空格/句号划分
      # 去重
      tags = tags.split(/\,|\ |\.|\，|\　|\。/).filter (s)-> s.length
      tags = jQuery.unique tags
      tags = tags.join(',')

      @$submit_btn.addClass 'disabled'
      @$inputs.slideUp()

      jQuery.ajax
        url: "#{HOST}/api/collect_url"
        type: 'POST'
        data:
          url: @url_info.url
          title: title
          desc: desc
          tags: tags
          base64: @image_base64_src
        success: (res)=>
          # 收集完毕
          @$collected.find('span.i').text '收集成功！'
          @collected(res)



class Popup
  constructor: ->
    # 流程：
    # 第一个请求：获取短网址信息
    # 第二个请求：验证用户是否登录
    # 如果第二个请求返回用户已登录，则进行第三个请求，检查网址收集情况

    # 当前 tab 对应的页面基本信息
    @url_info = new UrlInfo jQuery('.url-info')
    @url_info.load =>

      # 获取短网址和二维条码
      loading0 = show_loading_after @url_info.$el, '正在获取短网址 …'
      @short_url_info = new ShortUrlInfo jQuery('.short-url-info')
      @short_url_info.load @url_info.url, =>
        loading0.remove()

      # 登录验证书签服务
      loading1 = show_loading_after @short_url_info.$el, '正在验证用户 …'
      @auth = new Auth(jQuery('.auth'), @)
      @auth.go =>
        loading1.remove()

  show_form: ->
    @form = new Form jQuery('.form')
    loading2 = show_loading_after @short_url_info.$el, '正在读取数据 …'
    @form.load @url_info, =>
      loading2.remove()


jQuery ->
  jQuery(document.body).show()
  popup = new Popup