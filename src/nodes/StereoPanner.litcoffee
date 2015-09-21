## StereoPanner

Wraps the StereoPannerNode AudioContext object

    class StereoPanner extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        super
      
      before_config: (config)->
        @insert_node @context.createStereoPanner(), 0
      
      after_config: (config)->
      
      
      
      
      

      
