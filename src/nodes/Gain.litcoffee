## Gain

Wraps the GainNode AudioContext object

    class Gain extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        super
      
      before_config: (config)->
        @insert_node @context.createGain(), 0
        @_nodes[0].gain.value = @_instance.config.default_gain
      
      after_config: (config)->


      
