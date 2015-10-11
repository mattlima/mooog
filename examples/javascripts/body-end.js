(function() {
  $(document).foundation();

  if (!Mooog.browser_test().all) {
    $('#not-supported').foundation('reveal', 'open');
  }

  $('[data-slider]').on('change.fndtn.slider', function(e) {
    var $t, d, val;
    $t = $(e.target);
    d = $t.data();
    val = $t.attr('data-slider');
    switch (d.mooogTargetType) {
      case "send":
        return M.track(d.mooogNodeTarget).send(d.mooogParamTarget).param("gain", val);
      default:
        return M.node(d.mooogNodeTarget).param(d.mooogParamTarget, val);
    }
  });

}).call(this);
