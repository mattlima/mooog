## ScriptProcessor

Wraps the ChannelMergerNode AudioContext object. The native constructor arguments
`numberOfInputChannels`, `numberOfOutputChannels` and `bufferSize` can be passed in the 
configuration object, as can the callback `onaudioprocess` function.

    class ScriptProcessor extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        @__bufferSize = if config.bufferSize? then config.bufferSize else null
        @__numberOfInputChannels = \
        if config.numberOfInputChannels? then config.numberOfInputChannels else 2
        @__numberOfOuputChannels = \
        if config.numberOfOuputChannels? then config.numberOfOuputChannels else 2
        delete config.bufferSize
        delete config.numberOfInputChannels
        delete config.numberOfOuputChannels
        @debug "ScriptProcessorNode is deprecated and will be replaced by AudioWorker"
        super
        
        
      
      before_config: (config)->
        @insert_node @context.createScriptProcessor(
          @__bufferSize, @__numberOfInputChannels, @__numberOfOuputChannels
        ), 0
      
      after_config: (config)->
        
        
