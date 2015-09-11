(function() {
  $(document).foundation();

  $('[data-slider]').on('change.fndtn.slider', function(e) {
    var $t, d, val;
    $t = $(e.target);
    d = $t.data();
    val = $t.attr('data-slider');
    return M.node(d.mooogNodeTarget).param(d.mooogParamTarget, val);
  });

}).call(this);
