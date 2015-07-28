## Oscillator

Wraps the OscillatorNode AudioContext object

    class Oscillator extends Node
      constructor: (@_track, params...) ->

When cloning this Node, only event handlers need to be copied;
they are listed here.

        @functions_to_copy = ["onended"]
        @base_node = @_track._instance._context.createOscillator()
        @base_node.connect @_track._instance._destination, 0
        super

      


The OscillatorNode can only be turned on once, which is inconvenient,
so we replace the stop function with a function that regenerates the
underlying base node.
      
      stop: ->
        @base_node.stop()
        new_base = @_track._instance._context.createOscillator()

        
        @base_node = @clone_AudioNode @base_node, new_base
        #@base_node = new_base
        @base_node.connect @_track._instance._destination, 0
        @update_bindings @base_node
        this
