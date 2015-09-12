$(document).foundation()

$('[data-slider]').on 'change.fndtn.slider', (e)->
  $t = $(e.target)
  d = $t.data()
  val = $t.attr('data-slider')
  switch d.mooogTargetType
    when "send"
      M.track(d.mooogNodeTarget).send(d.mooogParamTarget).param("gain", val)
    else
      M.node(d.mooogNodeTarget).param(d.mooogParamTarget, val)
