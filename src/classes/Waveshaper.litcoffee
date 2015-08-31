## WaveShaper

Wraps the WaveShaperNode AudioContext object

    class WaveShaper extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        config.node_type = 'WaveShaper'
        super
        @configure_from config
        @insert_node @context.createWaveShaper(), 0
        @zero_node_setup config

      
