## Node

Base class for all the node wrappers

    class Node
      constructor: (@_track, params) ->

We track incoming and outgoing connections to the node in these arrays.

        @_incoming = []
        @_outgoing = []
        @_rebinds = {}
        @update_bindings @base_node
      
        
Native Node functions that are not overridden or enhanced by wrappers
are made available via `bind()` or getter/setters via `defineProperty`.
Sometimes we need to swap out the native Node object, in which case we
need to rebind the functions exposed to the new object. Those functions
are tracked in `_rebinds`
      
      update_bindings: (base_node) ->
        for key of base_node
          #console.log "#{key} is a ", @__typeof( base_node[key] )
          if @_rebinds[key] or !@[key]?
            @_rebinds[key] = true
            switch @__typeof( base_node[key] )
              when "function"
                @[key] = base_node[key].bind base_node
              when "string", "number"
                ((o,key) ->
                  Object.defineProperty o, key, {
                    get: ->
                      @base_node[key]
                    set: (val) ->
                      @base_node[key] = val
                    enumerable: true
                    configurable: true
                  })(@, key)
              when "AudioParam"
                @[key] = base_node[key]
        @


This is a modified `typeof` to filter AudioContext API-specific object types
      
      
      __typeof: (thing) ->
        return "AudioParam" if thing instanceof AudioParam
        switch typeof(thing)
          when "string" then "string"
          when "number" then "number"
          when "function" then "function"
          when "object" then "object"
          else
            #console.log thing, typeof(thing)
            throw new Error "__typeof does not pass for " + typeof(thing)
            
            
This function duplicates `AudioNode` objects, ensuring that AudioParams
are copied correctly.
        
      clone_AudioNode: (source, dest) ->
        for key of source
          switch @__typeof( source[key] )
            when "function"
              if @functions_to_copy.indexOf( key ) > -1
                dest[key] = source[key].bind dest
            when "string", "number"
              dest[key] = source[key]
            when "AudioParam"
              dest[key].value = source[key].value
        dest
        

