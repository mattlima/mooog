## Oscillator

Base wraps the OscillatorNode AudioContext object

    class Oscillator extends Node
      constructor: (@type, @context, @initOb) ->
        super
        console.log(@original_node)
