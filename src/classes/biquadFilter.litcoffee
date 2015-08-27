## BiquadFilter

Wraps the BiquadFilterNode AudioContext object

    class BiquadFilter extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        config.node_type = 'BiquadFilter'
        super
        @configure_from config
        @insert_node @context.createBiquadFilter(), 0
        @zero_node_setup config

      
