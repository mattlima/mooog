## Oscillator

Wraps the OscillatorNode AudioContext object

    class Oscillator extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        config.node_type = 'Oscillator'
        super
        @configure_from(config)
        @insert_node @context.createOscillator(), 0
        @zero_node_setup config
        
        
        @insert_node new Gain( @_instance, { connect_to_destination: @config.connect_to_destination } )
        @_is_started = false

      
      start: () ->
        if @_is_started
          @_nodes[1].gain.value = 1.0
        else
          @_nodes[0].start()
          @_is_started = true
        @
      
      stop: () ->
        @_nodes[1].gain.value = 0
        @
        
      
