## Mooog

Expose the API as the Moog global


    class Mooog
      constructor: (@initOb) ->

      context: ->
        new Context()

    window.Mooog = Mooog

