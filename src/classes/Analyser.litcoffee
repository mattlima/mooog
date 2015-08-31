## Analyser

Wraps the AnalyserNode AudioContext object

    class Analyser extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        config.node_type = 'Analyser'
        super
        @configure_from config
        @insert_node @context.createAnalyser(), 0
        @zero_node_setup config

      
