if (window.location.pathname == "/") {
  document.addEventListener('DOMContentLoaded',function() {
    var form = document.getElementById('newguest');
    var toSave = ["herokai_name", "notify_hipchat", "notify_gchat"];

    form.elements["herokai_name"].value = localStorage.getItem("herokai_name")
    form.elements["notify_gchat"].checked   = (localStorage.getItem("notify_gchat")   === "true")
    form.elements["notify_hipchat"].checked = (localStorage.getItem("notify_hipchat") === "true")

    form.addEventListener("submit", function(e) {
      localStorage.setItem("herokai_name",   form.elements["herokai_name"].value)
      localStorage.setItem("notify_gchat",   form.elements["notify_gchat"].checked)
      localStorage.setItem("notify_hipchat", form.elements["notify_hipchat"].checked)
    }, false);


    var addButtons = document.getElementsByClassName("addGuest")
    for (var i=0; i < addButtons.length; i++) {
      addButtons[i].addEventListener("click", function(e) {
        var newField = this.parentNode.getElementsByClassName('guest-name')[0].outerHTML
        this.insertAdjacentHTML('beforebegin', newField)
        e.preventDefault();
      }, false);
    }

    var removeButtons = document.getElementsByClassName("removeGuest")
    for (var i=0; i < removeButtons.length; i++) {
      removeButtons[i].addEventListener("click", function(e) {
        var elems = this.parentElement.getElementsByClassName('guest-name')
        var idx = elems.length - 1
        if (idx > 0) {
          var elem = elems[idx]
          elem.parentNode.removeChild(elem);
        }
        e.preventDefault();
      }, false);
    }


  });
}
