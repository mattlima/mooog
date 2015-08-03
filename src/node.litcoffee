## Node

> Base class for all the node wrappers. 

The Mooog Node object wraps one or more AudioNode objects. By default it 
exposes the `AudioNode` methods of the first AudioNode in the `_nodes`
array. 


`_instance`: The parent `Mooog` instance  
`node_list`: An array of which each element is either
  * A string representing a Node typeof
  * An `AudioNode`
  * A `Node`
  * An object (TBD)


    class Node
      constructor: (@_instance, node_list...) ->
        @_destination = @_instance._destination
        @context = @_instance.context

We track incoming and outgoing connections to the node in these arrays.


        @_incoming = []
        @_outgoing = []
        @_nodes = []
        
        node_list = [node_list] unless node_list instanceof Array
        if node_list.length is 1
          for i in node_list
            t = @__typeof(i)
            if t == "AudioNode"
              @_nodes.push i
            if t == "string"
              return new Mooog.LEGAL_NODES[i] @_instance
            if t == "Node"
              return i
        else
          for i in node_list
            t = @__typeof(i)
            if t == "AudioNode"
              todo = i.constructor.name.replace(/Node/,'')
              @_nodes.push new Mooog.LEGAL_NODES[todo] @_instance
            if t == "string"
              @_insert_node new Mooog.LEGAL_NODES[i]( @_instance ), 0
            if t == "Node"
              @_nodes.push i
        




        

      
        



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
          else
            #console.log thing, typeof(thing)
            throw new Error "__typeof does not pass for " + typeof(thing)
            
            

      
### Node.insert_node


      insert_node: (node, ord) ->
        length = @_nodes.length
        ord = length unless ord?
                
        if ord > length
          throw new Error("Invalid index given to insert_node: " + ord +
          " out of " + length)
        console.log 'called insert on', node, ord

        if ord is 0
         
          @connect_incoming node
          @disconnect_incoming @_nodes[0]

          if length > 1
            node.connect @to @_nodes[0]
            console.log 'node.connect to ', @_nodes[0]

        if ord is length
          @_nodes[ord - 1].disconnect @from @_destination if ord isnt 0
          console.log(@_nodes[ord - 1], 'disconnect', @_destination) if ord isnt 0
          node.connect @to @_destination
          console.log node, 'connect', @_destination
          @_nodes[ord - 1].connect @to node if ord isnt 0
          console.log @_nodes[ord - 1], "connect", node if ord isnt 0

        if ord isnt length and ord isnt 0
          console.log @_nodes[ord - 1], "disconnect", @_nodes[ord]
          @_nodes[ord - 1].disconnect @from @_nodes[ord]
          console.log @_nodes[ord - 1], "connect", node
          @_nodes[ord - 1].connect @to node
          console.log node, "connect", @_nodes[ord]
          node.connect @to @_nodes[ord]
        
        @_nodes.splice ord, 0, node
        console.log "spliced:", @_nodes

  
        
          

      connect_incoming: ->
        console.log 'do incoming'
        #todo: deal with incoming connections for 0 element

      disconnect_incoming: ->
        console.log 'undo incoming'
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



      connect: (node, param, output, input) ->
        console.log "called connect on ", @, node
        @_nodes[ @_nodes.length - 1 ].connect node
        #todo: deal with params
        #@_outgoing.push [node, param, output, input]
        #node.receive_connect @, param, output, input if node.receive_connect?
        #@connect_base_node node, param, output, input
      
      
      to: (node) ->
        switch @__typeof node
          when "Node" then return node._nodes[0]
          when "AudioNode" then return node
          else throw New Error "Unknown node type passed to connect"
      
      from: @.prototype.to
      
      
      expose_methods_of: (node) ->
        console.log "exposing", node
        for key,val of node
          if @[key]? then continue
          console.log "- checking", @__typeof val
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

