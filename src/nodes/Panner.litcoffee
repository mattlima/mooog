## Panner

Wraps the PannerNode AudioContext object

    class Panner extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        super
      
      before_config: (config)->
        @insert_node @context.createPanner(), 0
      
      after_config: (config)->

      
