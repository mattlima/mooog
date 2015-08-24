## Mooog

Wraps the AudioContext object and exposes the Track object. Exposes the API
as the Mooog global.  
Config options:
  - debug: Output debugging messages to the console. *Default: false*
  - default_gain: `Gain` objects that are initiated will have their gain
automatically set to this value. *Default: 0.5*


    class Mooog
    
      @LEGAL_NODES:
        'Oscillator': Oscillator
        'StereoPanner': StereoPanner
        'Gain': Gain
        'AudioBufferSource': AudioBufferSource
        'Convolver': Convolver
        'BiquadFilter': BiquadFilter

      
      constructor: (@initConfig = {}) ->
      
`_BROWSER_CONSTRUCTOR` Stores the type of constructor used for the AudioContext 
object (`AudioContext` or `webkitAudioContext`)

        @_BROWSER_CONSTRUCTOR = false
        @context = @create_context()
        @_destination = @context.destination
        @config =
          debug: false
          default_gain: 0.5
        
        @init(@initConfig)

        @_nodes = {}
        #@_connections = {}



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
        return new MooogAudioNode(this) unless arguments.length
        if typeof id is 'string'
          if node_list.length
            @_nodes[id] = new MooogAudioNode(this, id, node_list...)
          else if @_nodes?[id]?
            return @_nodes[id]
          else throw new Error("No MooogAudioNode found with id #{id}")
        else
          node = new MooogAudioNode(this, [id].concat(node_list...)...)
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

      @freq: (n) ->
        440 * Math.pow(2,((n-69)/12))



    window.Mooog = Mooog
