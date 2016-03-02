## Oscillator

Wraps the OscillatorNode AudioContext object

    class Oscillator extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        super
      
      before_config: (config)->
        @insert_node @context.createOscillator(), 0
      
      after_config: (config)->
        @insert_node new Gain( @_instance, { connect_to_destination: @config.connect_to_destination, gain: 1.0 } )
        @_is_started = false
        @_state = 'stopped'
        @_timeout = false
        @define_readonly_property 'state', () =>
          @_state
      
      start: (time = 0) ->
        clearTimeout @_timeout
        return @ if @_state is 'playing'
        if time is 0
          @__start(time)
        else
          @_timeout = setTimeout @__start, time * 1000
        @
      
      stop: (time = 0) ->
        clearTimeout @_timeout
        return @ if @_state is 'stopped'
        if time is 0
          @__stop()
        else
          @_timeout = setTimeout @__stop, time * 1000
        @
      
      __stop: () =>
        @_state = 'stopped'
        @_nodes[1].gain.value = 0
        @
        
      __start: () =>
        @_state = 'playing'
        if @_is_started
          @_nodes[1].gain.value = 1.0
        else
          @_nodes[0].start(0)
          @_is_started = true
        @
        
        
      
