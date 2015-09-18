## ChannelMerger

Wraps the ChannelMergerNode AudioContext object. The `numberOfInputs` argument
of the native constructor can be passed in the configuration object.

    class ChannelMerger extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        config.node_type = 'ChannelMerger'
        numberOfInputs = if config.numberOfInputs? then config.numberOfInputs else 6
        delete config.numberOfInputs
        
        super
        @configure_from config
        
        @insert_node @context.createChannelMerger( numberOfInputs ), 0
        
        @zero_node_setup config

      
