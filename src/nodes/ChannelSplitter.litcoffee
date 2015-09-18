## ChannelSplitter

Wraps the ChannelSplitterNode AudioContext object. The `numberOfOutputs` argument
of the native constructor can be passed in the configuration object.

    class ChannelSplitter extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        config.node_type = 'ChannelSplitter'
        numberOfOutputs = if config.numberOfOutputs? then config.numberOfOutputs else 6
        delete config.numberOfOutputs
        
        super
        @configure_from config
        
        @insert_node @context.createChannelSplitter( numberOfOutputs ), 0
        
        @zero_node_setup config

      
