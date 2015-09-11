$(document).foundation()

$('[data-slider]').on 'change.fndtn.slider', (e)->
  $t = $(e.target)
  d = $t.data()
  val = $t.attr('data-slider')
  M.node(d.mooogNodeTarget).param(d.mooogParamTarget, val)
