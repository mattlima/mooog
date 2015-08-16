## Mooog

Wraps the AudioContext object and exposes the Track object. Exposes the API
as the Mooog global


    class Mooog
    
      @LEGAL_NODES:
        'Oscillator': Oscillator
        'StereoPanner': StereoPanner
        'Gain': Gain

      
      constructor: (@initConfig = {}) ->
      
`_BROWSER_CONSTRUCTOR` Stores the type of constructor used for the AudioContext 
object (`AudioContext` or `webkitAudioContext`)

        @_BROWSER_CONSTRUCTOR = false
        @context = @create_context()
        @_destination = @context.destination
        @config =
          debug: false
        
        @init(@initConfig)

        @_nodes = {}
        #@_connections = {}
        #@_node_id_count = 1


      init: (initConfig) ->
        for key, val of @config
          if initConfig[key]?
            @config[key] = initConfig[key]


      create_context: () ->
        if(window.AudioContext?)
          @_BROWSER_CONSTRUCTOR = 'AudioContext'
          return new AudioContext()
        if(window.webkitAudioContext?)
          @_BROWSER_CONSTRUCTOR = 'webkitAudioContext'
          return new webkitAudioContext()
        throw new Error("This browser does not yet support the AudioContext API")

The track object holds a chain of AudioNodes. By default it includes panner
and gain stages.

      #track: (id, params) ->
      #  return @_tracks[id] if @_tracks?[id]?
      #  @_tracks[id] = new Track(id, this, params)


        
      node: (id, node_list...) ->
        if typeof id is 'string'
          if node_list.length
            @_nodes[id] = new Node(this, id, node_list...)
          else if @_nodes?[id]?
            return @_nodes[id]
          else throw new Error("No node found with id #{id}")
        else
          node = new Node(this, [id].concat(node_list...)...)
          @_nodes[node.id] = node
      
      
      #create_connection: (from, to) ->
      #  @_connections[from]?[to] = true
      #
      #delete_connection: (from, to) ->
      #  delete @_connections[from]?[to]
      #
      #next_node_id: ->
      #  @_node_id_count += 1
      #  "_node" + @_node_id_count

        

    window.Mooog = Mooog
