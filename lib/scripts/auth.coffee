HOST = "http://collect.4ye.me"

#
# 登录成功后回调处理
# 
jQuery ->
  host   = "collect.4ye.me"
  reduce = (obj, str)->
    pair = str.split("=")
    obj[pair[0]] = pair[1]
    obj

  params = window.location.search.split(/[\?\&]/).splice(1).reduce(reduce, {})

  chrome.storage.sync.set auth_token: params.auth_token, ->

    window.location.href = HOST
