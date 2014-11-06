#
# 登录成功后回调处理
# 

jQuery ->
  reduce = (obj, str)->
    pair = str.split("=")
    obj[pair[0]] = pair[1]
    obj

  params = window.location.search.split(/[\?\&]/).splice(1).reduce(reduce, {})

  chrome.storage.sync.set auth_token: params.auth_token, ->

    # 设置auth_token后关闭页面
    chrome.tabs.getCurrent (tab)->
      chrome.tabs.remove(tab.id)
