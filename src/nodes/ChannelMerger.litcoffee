## ChannelMerger

Wraps the ChannelMergerNode AudioContext object. The `numberOfInputs` argument
of the native constructor can be passed in the configuration object.

    class ChannelMerger extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        @__numberOfInputs = if config.numberOfInputs? then config.numberOfInputs else 6
        delete config.numberOfInputs
        super
        
      before_config: (config)->
        @insert_node @context.createChannelMerger( @__numberOfInputs ), 0
        

      after_config: (config)->
      
