## Node

Base class for all the node wrappers. 

The Mooog Node object wraps one or more AudioNode objects. By default it 
exposes the `AudioNode` methods of the first AudioNode in the `_nodes`
array. 

Signatures:

> Node(instance:Mooog , id:string, node_def:mixed)

`_instance`: The parent `Mooog` instance  
`id`: A unique identifier to assign to this Node
`node_def`: Either a string representing the type of Node to initialize
or an object with initialization params (see below) 



> Node(instance:Mooog , node_definition:object [, node_definition...])

`_instance`: The parent `Mooog` instance  
`node_definition`: An object used to create and configure the new Node. 

Required properties:
  - `id`: Unique string identifier
  - `node_type`: String indicating the type of Node (Oscillator, Gain, etc.)
  
Optional properties
  - `connect_to_destination`: Boolean indicating whether the last in this node's 
`_nodes` array is automatically connected to the `AudioDestinationNode`. *default: true*




    class Node
      constructor: (@_instance, node_list...) ->
        @_destination = @_instance._destination
        @context = @_instance.context
        @_nodes = []
        @config_defaults =
          connect_to_destination: true
        @debug "node_list:", node_list
        @debug "constr:", @constructor.name
        
Take care of first type signature (ID and string type)

        if @__typeof(node_list[0]) is "string" \
        and @__typeof(node_list[1]) is "string" \
        and Mooog.LEGAL_NODES[node_list[1]]?
          return new Mooog.LEGAL_NODES[node_list[1]] @_instance, { id: node_list[0] }

Otherwise, this is one or more config objects.
        
        if node_list.length is 1
          return unless @constructor.name is "Node"
          #if @__typeof node_list[0] is "AudioNode"
          #  return
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

Enforce the required config properties here, and set others as necessary.
      
      configure_from: (ob) ->
        @debug "config from", ob
        @id = if ob.id? then ob.id else @new_id()
        @debug @id
        for k, v of @config_defaults
          ob[k] ?= @config_defaults[k]
        @config = ob

        
### Node.toString
Includes the ID in the string representation of the object.      

      toString: () ->
        "#{@.constructor.name}#"+@id



### Node.new_id
Generates a new string identifier for this node.
      
      
      new_id: () ->
        "#{@.constructor.name}_#{Math.round(Math.random()*100000)}"
  





      
        



### Node.__typeof
This is a modified `typeof` to filter AudioContext API-specific object types
      
      
      __typeof: (thing) ->
        return "AudioParam" if thing instanceof AudioParam
        return "AudioNode" if thing instanceof AudioNode
        return "Node" if thing instanceof Node
        switch typeof(thing)
          when "string" then "string"
          when "number" then "number"
          when "function" then "function"
          when "object" then "object"
          when "undefined" then "undefined"
          else
            throw new Error "__typeof does not pass for " + typeof(thing)
            
            

      
### Node.insert_node


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

  
        
          

      connect_incoming: ->
        #@debug 'do incoming'
        #todo: deal with incoming connections for 0 element

      disconnect_incoming: ->
        #@debug 'undo incoming'
        #todo: deal with incoming connections for 0 element


### Node.connect
We track all connections to and from the underlying `@base_node` by exposing
modified connect and disconnect methods. 
`node`: The node object or string ID of the object to which to connect.
`param`: Optional string name of the `AudioParam` member of `node`to
which to connect.
`output`: Optional integer representing the output of this Node to use.
`input`: If `param` is not specified (you are connecting to an `AudioNode`)
then this integer argument can be used to specify the input of the target
to connect to.
      #todo: Figure out how/whether to deal with params 


      connect: (node, output = 0, input = 0) ->
        @debug "called connect from #{@} to #{node}"
        
        switch @__typeof node
          when "Node"
            target = node._nodes[0]
            @_nodes[ @_nodes.length - 1 ].connect target, output, input
          when "AudioNode"
            target = node
            @_nodes[ @_nodes.length - 1 ].connect target, output, input
          when "AudioParam"
            target = node
            @_nodes[ @_nodes.length - 1 ].connect target, output
          else throw new Error "Unknown node type passed to connect"

        #todo: deal with params
        #@_outgoing.push [node, param, output, input]
        #node.receive_connect @, param, output, input if node.receive_connect?
        #@connect_base_node node, param, output, input
      
      
      to: (node) ->
        switch @__typeof node
          when "Node" then return node._nodes[0]
          when "AudioNode" then return node
          else throw new Error "Unknown node type passed to connect"
      
      from: @.prototype.to
      
      
      expose_methods_of: (node) ->
        @debug "exposing", node
        for key,val of node
          if @[key]? then continue
          #@debug "- checking", @__typeof val
          switch @__typeof val
            when 'function'
              @[key] = val.bind node
            when 'AudioParam'
              @[key] = val
            when "string", "number"
              ((o, node, key) ->
                Object.defineProperty o, key, {
                  get: ->
                    node[key]
                  set: (val) ->
                    node[key] = val
                  enumerable: true
                  configurable: true
                })(@, node, key)


### Node.safely_disconnect
Prevents `InvalidAccessError`s from stopping program execution if you try to use disconnect on 
a node that's not already connected.

      safely_disconnect: (node1, node2, output = 0, input = 0) ->
        switch @__typeof node1
          when "Node" then source = node1._nodes[ source._nodes.length - 1 ]
          when "AudioNode", "AudioParam" then source = node1
          else throw new Error "Unknown node type passed to connect"
        switch @__typeof node2
          when "Node" then target = node2._nodes[0]
          when "AudioNode", "AudioParam" then target = node2
          else throw new Error "Unknown node type passed to connect"
        try
          source.disconnect target, output, input
        catch e
          @debug("ignored InvalidAccessError disconnecting #{target} from #{source}")
      
### Node.disconnect
Replace the native `disconnect` function with a safe version, in case it is called directly.

      disconnect: (node, output = 0, input = 0) ->
        @safely_disconnect @, node, output, input



### Node.debug
Logs to the console if the debug config option is on
  
      debug: (a...) ->
        console.log(a...) if @_instance.config.debug
