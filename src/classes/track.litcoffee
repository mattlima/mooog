## Track

Wraps the AudioContext object and exposes the Track object

    class Track
      constructor: (@id, @context) ->
        @_nodes = []
        @_panner = @context._AudioContext.createPanner()
        @_gain = @context._AudioContext.createGain()


