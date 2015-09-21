## MediaElementSource

Wraps the MediaElementSourceNode AudioContext object. The `HTMLMediaElement` argument
of the native constructor can be passed in the configuration object, either as such or
via a CSS selector.

    class MediaElementSource extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        super
      
      before_config: (config)->
        if !config.mediaElement
          throw new Error("MediaElementSource requires mediaElement config argument")
        if typeof(config.mediaElement) is 'string'
          config.mediaElement = document.querySelector( config.mediaElement )
        @insert_node @context.createMediaElementSource( config.mediaElement ), 0
      
      after_config: (config)->
      
        
        
        
      
