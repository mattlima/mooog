## Oscillator

Wraps the OscillatorNode AudioContext object

    class Oscillator extends Node
      constructor: (@_instance, node_list...) ->
        super
        @insert_node @context.createOscillator(), 0
        #@insert_node @context.createGain(), 1
        @insert_node new Gain( @_instance, 'Gain' )
        @_is_started = false
        @expose_methods_of @_nodes[0]

      
      start: () ->
        if @_is_started
          @_nodes[1].gain.value = 1.0
        else
          @_nodes[0].start()
          @_is_started = true
      
      stop: () ->
        @_nodes[1].gain.value = 0
        
      
