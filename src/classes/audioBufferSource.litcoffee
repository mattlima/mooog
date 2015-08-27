## AudioBufferSource
`start()` and `stop()` are patched to work repeatedly on the same node by keeping
manipulating the loop start and end times and muting the output to simulate re-starting
playback from 0


Wraps the AudioBufferSourceNode AudioContext object

    class AudioBufferSource extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        config.node_type = 'AudioBufferSource'
        super
        @configure_from config
        
        @insert_node @context.createBufferSource(), 0
        @define_buffer_source_properties()
        
        @zero_node_setup config
        
        @insert_node new Gain @_instance, {
          gain: 1.0
          connect_to_destination: @config.connect_to_destination
          }
        @_is_started = false
        @_stop_timeout = false
        @_state = 'stopped'
        @define_readonly_property 'state', () =>
          @_state
        @_true_loop = @_nodes[0].loop
        @_nodes[0].loop = true
        @_true_loopStart = @_nodes[0].loopStart
        @_true_loopEnd = @_nodes[0].loopEnd
        
        
        
        Object.defineProperty @, 'loop', {
          get: ->
            @_true_loop
          set: (val) =>
            @_true_loop = val
            if @_state is 'playing'
              if val
                @_nodes[0].loopEnd = @_true_loopEnd
                @_nodes[0].loopStart = @_true_loopStart
              else
                @_true_loopEnd = @_nodes[0].loopEnd
                @_true_loopStart = @_nodes[0].loopStart
          enumerable: true
          configurable: true
        }
        
        Object.defineProperty @, 'loopStart', {
          get: ->
            @_true_loopStart
          set: (val) =>
            @_true_loopStart = val
            if @_true_loop and @_state is 'playing'
              @_nodes[0].loopStart = @_true_loopStart
          enumerable: true
          configurable: true
        }
        
        Object.defineProperty @, 'loopEnd', {
          get: ->
            @_true_loopEnd
          set: (val) =>
            @_true_loopEnd = val
            if @_true_loop and @_state is 'playing'
              @_nodes[0].loopEnd = @_true_loopEnd
          enumerable: true
          configurable: true
        }
        
        

      
      start: () ->
        return if @_state is 'playing'
        @_state = 'playing'
        if @_true_loop
          @_nodes[0].loopEnd = @_true_loopEnd
          @_nodes[0].loopStart = @_true_loopStart
        else
          @_nodes[0].loopEnd = @_nodes[0].buffer.duration
          @_nodes[0].loopStart = 0
          @_stop_timeout = setTimeout @stop.bind(@),
          (Math.round(@_nodes[0].buffer.duration * 1000)) - 19
        if @_is_started
          @_nodes[1].gain.value = 1.0
        else
          @_nodes[0].start()
          @_is_started = true
        @
      
      stop: () ->
        return if @_state is 'stopped'
        @_state = 'stopped'
        clearTimeout @_stop_timeout
        @_nodes[1].gain.value = 0
        @_nodes[0].loopStart = 0
        @_nodes[0].loopEnd = 0.005
        @
      
      
      
      
      
        
      


        
        
