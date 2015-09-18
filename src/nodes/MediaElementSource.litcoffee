## MediaElementSource

Wraps the MediaElementSourceNode AudioContext object. The `HTMLMediaElement` argument
of the native constructor can be passed in the configuration object, either as such or
via a CSS selector.

    class MediaElementSource extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        config.node_type = 'MediaElementSource'
        if !config.mediaElement
          throw new Error("MediaElementSource requires mediaElement config argument")
        if typeof(config.mediaElement) is 'string'
          config.mediaElement = document.querySelector( config.mediaElement )
        
        super
        @configure_from config
        
        @insert_node @context.createMediaElementSource( config.mediaElement ), 0
        
        @zero_node_setup config

      
