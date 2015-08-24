## MooogAudioNode

Base class for all the node wrappers. 

The MooogAudioNode object wraps one or more AudioNode objects. By default it 
exposes the `AudioNode` methods of the first AudioNode in the `_nodes`
array. 

Signatures:

> MooogAudioNode(instance:Mooog , id:string, node_def:mixed)

`_instance`: The parent `Mooog` instance  
`id`: A unique identifier to assign to this Node
`node_def`: Either a string representing the type of Node to initialize
or an object with initialization params (see below) 



> MooogAudioNode(instance:Mooog , node_definition:object [, node_definition...])

`_instance`: The parent `Mooog` instance  
`node_definition`: An object used to create and configure the new Node. 

Required properties:
  - `id`: Unique string identifier
  - `node_type`: String indicating the type of Node (Oscillator, Gain, etc.)
  
Optional properties for all nodes
  - `connect_to_destination`: Boolean indicating whether the last in this node's 
`_nodes` array is automatically connected to the `AudioDestinationNode`. *default: true*

Additional properties  
  - Any additional key-value pairs will be used to set properties of the underlying `AudioNode`
object after initialization. 



    class MooogAudioNode
      constructor: (@_instance, node_list...) ->
        @_destination = @_instance._destination
        @context = @_instance.context
        @_nodes = []
        @config_defaults =
          connect_to_destination: true
        @config = {}
        
Take care of first type signature (ID and string type)

        if @__typeof(node_list[0]) is "string" \
        and @__typeof(node_list[1]) is "string" \
        and Mooog.LEGAL_NODES[node_list[1]]?
          return new Mooog.LEGAL_NODES[node_list[1]] @_instance, { id: node_list[0] }

Otherwise, this is one or more config objects.
        
        if node_list.length is 1
          return unless @constructor.name is "MooogAudioNode"
          if Mooog.LEGAL_NODES[node_list[0].node_type]?
            return new Mooog.LEGAL_NODES[node_list[0].node_type] @_instance, node_list[0]
          else
            throw new Error("Omitted or undefined node type in config options.")
        else
          for i in node_list
            if Mooog.LEGAL_NODES[node_list[i].node_type?]
              @_nodes.push new Mooog.LEGAL_NODES[node_list[i].node_type] @_instance, node_list[i]
            else
              throw new Error("Omitted or undefined node type in config options.")

        

### MooogAudioNode.configure_from
The config object can contain general configuration options or key/value pairs to be set on the
wrapped `AudioNode`. This function merges the config defaults with the supplied options and sets
the `config` property of the node
      
      configure_from: (ob) ->
        @id = if ob.id? then ob.id else @new_id()
        for k, v of @config_defaults
          @config[k] = if (k of ob) then ob[k] else @config_defaults[k]
        @config


### MooogAudioNode.zero_node_settings
XORs the supplied configuration object with the defaults to return an object the properties of which
should be set on the zero node
      
      zero_node_settings: (ob) ->
        zo = {}
        for k, v of ob
          zo[k] = v unless k of @config_defaults or k is 'node_type' or k is 'id'
        zo
        

### MooogAudioNode.zero_node_setup
Runs after the MooogAudioNode constructor by the inheriting classes. Exposes the underlying
`AudioNode` properties and sets any `AudioNode`-specific properties supplied in the 
configuration object.
      
      zero_node_setup: (config) ->
        @expose_methods_of @_nodes[0]
        for k, v of @zero_node_settings(config)
          @debug "zero node settings, #{k} = #{v}"
          @param k, v
        
### MooogAudioNode.toString
Includes the ID in the string representation of the object.      

      toString: () ->
        "#{@.constructor.name}#"+@id



### MooogAudioNode.new_id
Generates a new string identifier for this node.
      
      
      new_id: () ->
        "#{@.constructor.name}_#{Math.round(Math.random()*100000)}"


### MooogAudioNode.__typeof
This is a modified `typeof` to filter AudioContext API-specific object types
      
      
      __typeof: (thing) ->
        return "AudioParam" if thing instanceof AudioParam
        return "AudioNode" if thing instanceof AudioNode
        return "AudioBuffer" if thing instanceof AudioBuffer
        return "PeriodicWave" if thing instanceof PeriodicWave
        return "AudioListener" if thing instanceof AudioListener
        return "MooogAudioNode" if thing instanceof MooogAudioNode
        return typeof(thing)
      
### MooogAudioNode.insert_node


      insert_node: (node, ord) ->
        length = @_nodes.length
        ord = length unless ord?
                
        if ord > length
          throw new Error("Invalid index given to insert_node: " + ord +
          " out of " + length)
        @debug "insert_node of #{@} for", node, ord

        if ord is 0
          @connect_incoming node
          @disconnect_incoming @_nodes[0]

          if length > 1
            node.connect @to @_nodes[0]
            @debug '- node.connect to ', @_nodes[0]

        if ord is length
          @safely_disconnect @_nodes[ord - 1], (@from @_destination) if ord isnt 0
          @debug("- disconnect ", @_nodes[ord - 1], 'from', @_destination) if ord isnt 0
          
          if @config.connect_to_destination
            node.connect @to @_destination
            @debug '- connect', node, 'to', @_destination
          
          @_nodes[ord - 1].connect @to node if ord isnt 0
          @debug '- connect', @_nodes[ord - 1], "to", node if ord isnt 0

        if ord isnt length and ord isnt 0
          @safely_disconnect @_nodes[ord - 1], (@from @_nodes[ord])
          @debug "- disconnect", @_nodes[ord - 1], "from", @_nodes[ord]
          @_nodes[ord - 1].connect @to node
          @debug "- connect", @_nodes[ord - 1], "to", node
          node.connect @to @_nodes[ord]
          @debug "- connect", node, "to", @_nodes[ord]
        
        @_nodes.splice ord, 0, node
        @debug "- spliced:", @_nodes

  
### MooogAudioNode.add
Shortcut for insert_node


      add: (node) ->
        @insert_node(node)
          

      connect_incoming: ->
        #@debug 'do incoming'
        #todo: deal with incoming connections for 0 element

      disconnect_incoming: ->
        #@debug 'undo incoming'
        #todo: deal with incoming connections for 0 element


### MooogAudioNode.connect
`node`: The node object or string ID of the object to which to connect.  
`param`: Optional string name of the `AudioParam` member of `node` to
which to connect.  
`output`: Optional integer representing the output of this Node to use.  
`input`: If `param` is not specified (you are connecting to an `AudioNode`)
then this integer argument can be used to specify the input of the target
to connect to.  



      connect: (node, output = 0, input = 0, return_this = true) ->
        @debug "called connect from #{@} to #{node}, #{output}"
        
        switch @__typeof node
          
          when "AudioParam"
            @_nodes[ @_nodes.length - 1 ].connect node, output
            return this
          when "string"
            node = @_instance.node node
            target = node._nodes[0]
          when "MooogAudioNode"
            target = node._nodes[0]
          when "AudioNode"
            target = node
          else throw new Error "Unknown node type passed to connect"
          
        switch
          when typeof(output) is 'string'
            @_nodes[ @_nodes.length - 1 ].connect target[output], input
          when typeof(output) is 'number'
            @_nodes[ @_nodes.length - 1 ].connect target, output, input
        
        return if return_this then this else node



### MooogAudioNode.chain
Like `MooogAudioNode.connect` with two important differences. First, it returns the 
`MooogAudioNode` you are connecting to. Second, it automatically disconnects the callind
`MooogAudioNode` from the context's `AudioDestinationNode`. To use with `AudioParam`s, 
use the name of the param as the second argument (and the base `MooogAudioNode` as the first).

      chain: (node, output = 0, input = 0) ->
        if @__typeof(node) is "AudioParam" and typeof(output) isnt 'string'
          throw new Error "MooogAudioNode.chain() can only target AudioParams when used with
          the signature .chain(target_node:Node, target_param_name:string)"
        @disconnect @_destination
        @connect node, output, input, false


### MooogAudioNode.to, MooogAudioNode.from
These functions are synonyms and exist to improve code readability.
      
      to: (node) ->
        switch @__typeof node
          when "MooogAudioNode" then return node._nodes[0]
          when "AudioNode" then return node
          else throw new Error "Unknown node type passed to connect"
      
      from: @.prototype.to
      

### MooogAudioNode.expose_methods_of
Exposes the properties of a wrapped `AudioNode` on `this`

      
      expose_methods_of: (node) ->
        @debug "exposing", node
        for key,val of node
          if @[key]? then continue
          #@debug "- checking #{key}: got", @__typeof val
          switch @__typeof val
            when 'function'
              @[key] = val.bind node
            when 'AudioParam'
              @[key] = val
            when "string", "number", "boolean", "object"
              ((o, node, key) ->
                Object.defineProperty o, key, {
                  get: ->
                    node[key]
                  set: (val) ->
                    node[key] = val
                  enumerable: true
                  configurable: true
                })(@, node, key)



### MooogAudioNode.safely_disconnect
Prevents `InvalidAccessError`s from stopping program execution if you try to use disconnect on 
a node that's not already connected.

      safely_disconnect: (node1, node2, output = 0, input = 0) ->
        switch @__typeof node1
          when "MooogAudioNode" then source = node1._nodes[ node1._nodes.length - 1 ]
          when "AudioNode", "AudioParam" then source = node1
          when "string" then source = @_instance.node node1
          else throw new Error "Unknown node type passed to disconnect"
        switch @__typeof node2
          when "MooogAudioNode" then target = node2._nodes[0]
          when "AudioNode", "AudioParam" then target = node2
          when "string" then target = @_instance.node node2
          else throw new Error "Unknown node type passed to disconnect"
        try
          source.disconnect target, output, input
        catch e
          @debug("ignored InvalidAccessError disconnecting #{target} from #{source}")
        @

      
### MooogAudioNode.disconnect
Replace the native `disconnect` function with a safe version, in case it is called directly.

      disconnect: (node, output = 0, input = 0) ->
        @safely_disconnect @, node, output, input



### MooogAudioNode.param
jQuery-style getter/setter that also works on `AudioParam` properties.
  
      param: (key, val) ->
        if @__typeof(key) is 'object'
          @get_set k, v for k, v of key
          return this
        return @get_set key, val



### MooogAudioNode.get_set
Handles the getting/setting for `MooogAudioNode.param`

      get_set: (key, val) ->
        return unless @[key]?
        switch @__typeof @[key]
          when "AudioParam"
            if val?
              @[key].setValueAtTime val, @context.currentTime
              return this
            else
              @[key].value
          else
            if val?
              @[key] = val
              return this
            else @[key]


### MooogAudioNode.define_buffer_source_properties
Sets up useful functions on `MooogAudioNode`s that have a `buffer` property 
      
      define_buffer_source_properties: () ->
        @_buffer_source_file_url = ''
        Object.defineProperty @, 'buffer_source_file', {
          get: ->
            @_buffer_source_file_url
          set: (filename) =>
            request = new XMLHttpRequest()
            request.open('GET', filename, true)
            request.responseType = 'arraybuffer'
            request.onload = () =>
              @debug "loaded #{filename}"
              @_buffer_source_file_url = filename
              @_instance.context.decodeAudioData request.response, (buffer) =>
                @debug "setting buffer",buffer
                @buffer = buffer
              , (error) ->
                throw new Error("Could not decode audio data from #{request.responseURL}
                 - unsupported file format?")
            request.send()
          enumerable: true
          configurable: true
        }
        
### MooogAudioNode.define_readonly_property

        
      define_readonly_property: (prop_name, func) ->
        Object.defineProperty @, prop_name, {
          get: func
          set: () ->
            throw new Error("#{@}.#{prop_name} is read-only")
          enumerable: true
          configurable: false
        }
        
        
### MooogAudioNode.adsr
Applies an ADSR envelope of value changes to an `AudioParam`. 
`param`: An `AudioParam` or a string representing the name of the property, assumed to be on `this`. 
`config`: Object with the following properties (FAKE_ZERO is a very small number 
used in place of actual zero, which will throw errors when passed to 
`exponentialRampToValueAtTime`).
  - base: The value to start and end with. *Defaults to 'zero'*
  - times: An array of time values representing the ending time of each of the 
  ADSR stages. The first is relative to the currentTime, and the others are relative
  to the previous value. The delay stage can be suppressed by passing an array of three 
  elements, in which case the envelope will be an ASR and the `s` value will be ignored
  - a: The final value of the parameter at the end of the attack stage. *Defaults to 1*
  - s: The value of the parameter at the end of the delay stage (or attack stage, 
  if delay is omitted), to be held until the beginning of the release stage. *Defaults to 1*


      adsr: (param, config) ->
        param = @[param] if typeof(param) is "string"
        _0 = @_instance.config.fake_zero
        { base, times, a, s } = config
        base ?= _0
        base = _0 if base is 0
        a ?= 1
        a = _0 if a is 0
        s ?= 1
        s = _0 if s is 0
        t = @context.currentTime
        times[0] ||= _0
        times[1] ||= _0
        times[2] ||= _0
        if(times.length is 3)
          #[a_time, s_time, r_time] = times
          param.cancelScheduledValues t
          param.setValueAtTime base , t
          param.exponentialRampToValueAtTime a, t + times[0]
          param.setValueAtTime a, t + times[0] + times[1]
          param.exponentialRampToValueAtTime base , t + times[0] + times[1] + times[2]
        else
          times[3] ||= _0
          #[a_time, d_time, s_time, r_time] = times
          param.cancelScheduledValues t
          param.setValueAtTime base , t
          param.exponentialRampToValueAtTime a, t + times[0]
          param.exponentialRampToValueAtTime s, t + times[0] + d_time
          param.setValueAtTime s, t + times[0] + d_time + times[2]
          param.exponentialRampToValueAtTime base , t + times[0] + d_time + times[2] + times[3]
      
      



### MooogAudioNode.debug
Logs to the console if the debug config option is on
  
      debug: (a...) ->
        console.log(a...) if @_instance.config.debug
