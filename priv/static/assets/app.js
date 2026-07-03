(function () {
  if (window.LiveView && window.Phoenix) {
    var csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
    var liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket, {params: {_csrf_token: csrfToken}})
    liveSocket.connect()
  }
})()
