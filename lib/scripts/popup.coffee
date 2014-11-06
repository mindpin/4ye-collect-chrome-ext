#
# 设置全局ajax请求头
# 

set_global_auth_header = (auth_token)->
  authorization = if auth_token then "Bearer #{auth_token}" else null

  jQuery.ajaxSetup
    headers:
      "Athorization": authorization

chrome.storage.sync.get "auth_token", (item)->
  set_global_auth_header(item.auth_token)

  jQuery ->
    host     = "127.0.0.1:3000"
    $signin  = jQuery ".popup-4ye .signin"
    $signout = jQuery ".popup-4ye .signout"
    $token   = jQuery ".popup-4ye .token"

    #
    # 事件绑定
    # 
    $signout.on "click", ->
      deferred = jQuery.get "http://#{host}/sign_out"

      deferred.done ->
        chrome.storage.sync.remove "auth_token", ->
          $signin.slideDown() 
          $token.text("")
          $signout.hide() 

    $signin.on "click", ->
      url = "http://#{host}/sign_in?callback=chrome-extension://#{chrome.runtime.id}/auth.html"

      chrome.tabs.create url: url

    #
    # 检查登录状态
    #
    deferred = jQuery.ajax "http://#{host}/auth/check"

    deferred.done ->
      if item.auth_token
        $signout.slideDown()
        $token.text(item.auth_token)
        $signin.hide() 
      else
        $signin.slideDown() 
        $token.text("")
        $signout.hide() 

    deferred.fail (err)->
      if err.status == 401
        chrome.storage.sync.remove "auth_token", ->
          $signin.slideDown() 
          $token.text("")
          $signout.hide() 
      else
        console.error(err)
