## AudioBufferSource
`start()` and `stop()` are patched to work repeatedly on the same node by regenerating
the underlying `AudioBufferSourceNode` 


Wraps the AudioBufferSourceNode AudioContext object

    class AudioBufferSource extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        super
        
      before_config: (config)->
        @insert_node @context.createBufferSource(), 0
        @define_buffer_source_properties()
      
      after_config: (config)->
        @insert_node new Gain @_instance, {
          gain: 1.0
          connect_to_destination: @config.connect_to_destination
          }
        @_state = 'stopped'
        @define_readonly_property 'state', () =>
          @_state
        

      
      start: () ->
        return @ if @_state is 'playing'
        @_state = 'playing'
        @_nodes[1].param('gain', 1)
        @_nodes[0].start()
        
      stop: () ->
        return @ if @_state is 'stopped'
        @_state = 'stopped'
        @_nodes[1].param('gain',0)
        new_source = @context.createBufferSource()
        @clone_AudioNode_properties @_nodes[0], new_source
        @delete_node 0
        @insert_node new_source, 0
        @expose_properties_of @_nodes[0]
        @
      
      
      clone_AudioNode_properties: (source, dest) ->
        for k, v of source
          switch @__typeof source[k]
            when 'AudioBuffer', 'boolean', 'number', 'string'
              dest[k] = v
            when 'AudioParam' then dest[k].value = v.value

      
      
      
      
        
      


        
        
