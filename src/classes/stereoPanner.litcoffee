## StereoPanner

Wraps the StereoPannerNode AudioContext object

    class StereoPanner extends Node
      constructor: (@_instance, config = {}) ->
        config.node_type = 'StereoPanner'
        super
        @configure_from(config)
        @insert_node @context.createStereoPanner(), 0
        @zero_node_setup config

      
