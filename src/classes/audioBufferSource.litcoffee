## AudioBufferSource

Wraps the AudioBufferSourceNode AudioContext object

    class AudioBufferSource extends Node
      constructor: (@_instance, config = {}) ->
        config.node_type = 'AudioBufferSource'
        super
        @configure_from(config)
        
        @insert_node @context.createBufferSource(), 0
        @define_buffer_source_properties()
        
        
        @zero_node_setup config
        
        


        
        
