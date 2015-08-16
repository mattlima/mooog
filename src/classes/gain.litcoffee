## Gain

Wraps the GainNode AudioContext object

    class Gain extends Node
      constructor: (@_instance, config = {}) ->
        config.node_type = 'Gain'
        super
        @configure_from(config)
        @insert_node @context.createGain(), 0
        @expose_methods_of @_nodes[0]

      
