## BiquadFilter

Wraps the BiquadFilterNode AudioContext object

    class BiquadFilter extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        super
      
      before_config: (config)->
        @insert_node @context.createBiquadFilter(), 0
      
      after_config: (config)->

      
