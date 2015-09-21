## Analyser

Wraps the AnalyserNode AudioContext object

    class Analyser extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        super
      
      before_config: (config)->
        @insert_node @context.createAnalyser(), 0
      
      after_config: (config)->

      
