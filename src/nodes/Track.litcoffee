## Track

A convenience function that creates a chain with the specified node(s)
followed by a panner/gain stage. It can also create pre/post sends with their 
own gain. The gain and pan `AudioParams` of those stages can be accessed
via `gain` and `pan` methods exposed on the track object.


    class Track extends MooogAudioNode


      constructor: (@_instance, config = {}) ->
        @_sends = {}
        @debug 'initializing track object'
        config.node_type = 'Track'
        super
        @configure_from config
        
        #todo: make sure we don't need to use insert_node() for this
        @_pan_stage = @_instance.context.createStereoPanner()
        @_gain_stage = @_instance.context.createGain()
        @_gain_stage.gain.value = @_instance.config.default_gain
        @_pan_stage.connect @_gain_stage
        @_gain_stage.connect @_destination
        @_destination = @_pan_stage
        @gain = @_gain_stage.gain
        @pan = @_pan_stage.pan
        
        @zero_node_setup config
      
      
### Track.send
Creates a send to another `Track` object.  
`id`: String ID to assign to this send.  
`destination`: The target `Track` object or ID thereof  
`pre`: Either 'pre' or 'post'. *Defaults to config value in the `Mooog` object.*  
`gain`: Initial gain value for the send. *Defaults to config value in the `Mooog` object.*  
      
      send: (id,
        dest,
        pre = @_instance.config.default_send_type,
        gain = @_instance.config.default_gain) ->
        return @_sends[id] unless dest?
        source = if (pre is 'pre') then @_nodes[@_nodes.length - 1] else @_gain_stage
        return @_sends[id] if @_sends[id]?
        @_sends[id] = new_send = new Gain @_instance, { connect_to_destination: false, gain: gain }
        source.connect @to new_send
        new_send.connect @to dest
        new_send
        
      
      
      

        
      

        


