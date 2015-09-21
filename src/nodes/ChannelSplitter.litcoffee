## ChannelSplitter

Wraps the ChannelSplitterNode AudioContext object. The `numberOfOutputs` argument
of the native constructor can be passed in the configuration object.

    class ChannelSplitter extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        @__numberOfOutputs = if config.numberOfOutputs? then config.numberOfOutputs else 6
        delete config.numberOfOutputs
        super
      
      before_config: (config)->
        @insert_node @context.createChannelSplitter( @__numberOfOutputs ), 0
        
      after_config: (config)->
