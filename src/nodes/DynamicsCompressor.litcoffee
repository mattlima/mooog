## DynamicsCompressor

Wraps the DynamicsCompressorNode AudioContext object

    class DynamicsCompressor extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        super
      
      before_config: (config)->
        @insert_node @context.createDynamicsCompressor(), 0
      
      after_config: (config)->
        
      
