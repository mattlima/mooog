## Gain

Wraps the GainNode AudioContext object

    class Gain extends Node
      constructor: (@_instance, config = {}) ->
        config.node_type = 'Gain'
        super
        @configure_from(config)
        @insert_node @context.createGain(), 0
        @_nodes[0].gain.value = @_instance.config.default_gain
        @zero_node_setup config

      
