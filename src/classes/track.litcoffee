## Track

Wraps the AudioContext object and exposes the Track object

    class Track







`id`: String identifier, used to refer to this track after creation.    
`_instance`: The parent `Mooog` instance    
`type`: Optional string indicating the type of the first node in the track
chain. Equivalent to the part of the node name before "Node", ex. "Oscillator"  
`params`: An optional object of initialization parameters to pass to the Node

      constructor: (@id, @_instance, type, params) ->
        @_nodes = []
        @_panner = @_instance._context.createPanner()
        @_gain = @_instance._context.createGain()
        @add_node(type, 0, params) if type?

      add_node: (type, ord, params) ->
        switch type
          when "Oscillator" then @_nodes.splice ord, 0, new Oscillator(this, params)
          else throw new Error "Unknown AudioNode type: #{type}"


