## Mooog

Wraps the AudioContext object and exposes the Track object. Exposes the API
as the Mooog global


    class Mooog
    
      @LEGAL_NODES:
        'Oscillator': Oscillator
        'StereoPanner': StereoPanner
        'Gain': Gain

      
      constructor: (@initOb) ->
      
Stores the type of constructor used for the AudioContext object
(`AudioContext` or `webkitAudioContext`)

        @_BROWSER_CONSTRUCTOR = false
        @context = @create_context()
        @_destination = @context.destination
        @_nodes = {}
        @_connections = {}
        @_node_id_count = 1





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
        return @_nodes[id] if @_nodes?[id]?
        @_nodes[id] = new Node(this, node_list...)
      
      
      create_connection: (from, to) ->
        @_connections[from]?[to] = true
        
      delete_connection: (from, to) ->
        delete @_connections[from]?[to]
        
      next_node_id: ->
        @_node_id_count += 1
        "_node" + @_node_id_count

        

    window.Mooog = Mooog
