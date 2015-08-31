## DynamicsCompressor

Wraps the DynamicsCompressorNode AudioContext object

    class DynamicsCompressor extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        config.node_type = 'DynamicsCompressor'
        super
        @configure_from config
        @insert_node @context.createDynamicsCompressor(), 0
        @zero_node_setup config

      
