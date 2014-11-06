HOST = "http://127.0.0.1:3000"

jQuery ->
  $signin  = jQuery ".popup-4ye .signin"
  $signout = jQuery ".popup-4ye .signout"

  #
  # 事件绑定
  # 
  $signout.on "click", ->
    chrome.tabs.create url: "#{HOST}/sign_out" 

  $signin.on "click", ->
    chrome.tabs.create url: "#{HOST}/sign_in" 

  #
  # 检查登录状态
  #
  deferred = jQuery.ajax "#{HOST}/auth/check"

  deferred.done ->
    $signout.slideDown()
    $signin.hide() 

  deferred.fail (err)->
    $signin.slideDown() 
    $signout.hide() 
