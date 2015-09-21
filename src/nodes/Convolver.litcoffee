## Convolver

Wraps the ConvolverNode AudioContext object

    class Convolver extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        super
      
      before_config: (config)->
        @insert_node @context.createConvolver(), 0
        @define_buffer_source_properties()
      
      after_config: (config)->
        
        
