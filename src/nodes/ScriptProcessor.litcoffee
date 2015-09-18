## ScriptProcessor

Wraps the ChannelMergerNode AudioContext object. The native constructor arguments
`numberOfInputChannels`, `numberOfOutputChannels` and `bufferSize` can be passed in the 
configuration object, as can the callback `onaudioprocess` function.

    class ScriptProcessor extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        config.node_type = 'ScriptProcessor'
        
        bufferSize = if config.bufferSize? then config.bufferSize else null
        numberOfInputChannels = \
        if config.numberOfInputChannels? then config.numberOfInputChannels else 2
        numberOfOuputChannels = \
        if config.numberOfOuputChannels? then config.numberOfOuputChannels else 2
        delete config.bufferSize
        delete config.numberOfInputChannels
        delete config.numberOfOuputChannels
        

        @debug "ScriptProcessorNode is deprecated and will be replaced by AudioWorker"
        
        super
        @configure_from config
        
        @insert_node @context.createScriptProcessor(
          bufferSize, numberOfInputChannels, numberOfOuputChannels
        ), 0
        
        @zero_node_setup config

      
