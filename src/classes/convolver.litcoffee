## Convolver

Wraps the ConvolverNode AudioContext object

    class Convolver extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        config.node_type = 'Convolver'
        super
        @configure_from config
        
        @insert_node @context.createConvolver(), 0
        @define_buffer_source_properties()
        
        
        @zero_node_setup config
        
        


        
        
