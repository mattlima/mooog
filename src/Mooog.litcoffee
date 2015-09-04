## Mooog

Wraps the AudioContext object and exposes the Track object. Exposes the API
as the Mooog global.  


    class Mooog
    
      @LEGAL_NODES:
        'Oscillator': Oscillator
        'StereoPanner': StereoPanner
        'Gain': Gain
        'AudioBufferSource': AudioBufferSource
        'Convolver': Convolver
        'BiquadFilter': BiquadFilter
        'Analyser': Analyser
        'DynamicsCompressor': DynamicsCompressor
        'Delay': Delay
        'WaveShaper': WaveShaper

      
      constructor: (@initConfig = {}) ->
      
`_BROWSER_CONSTRUCTOR` Stores the type of constructor used for the AudioContext 
object (`AudioContext` or `webkitAudioContext`)

        @_BROWSER_CONSTRUCTOR = false
        @context = @create_context()
        @_destination = @context.destination
        @config =
          debug: false
          default_gain: 0.5
          default_ramp_type: 'exponential'
          default_send_type: 'post'
          periodic_wave_length: 2048
          curve_length: 65536
          fake_zero: 1/65536
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


### Mooog.track

Creates a Track object holds a chain of AudioNodes. By default it includes panner
and gain stages.

`id`: A unique identifier to assign to this Track
`node_list`: One or more config objects or `MooogAudioNode` objects to add to the `Track`


      track: (id, node_list...) ->
        return new Track(this) unless arguments.length
        if typeof id is 'string'
          if node_list.length
            throw new Error("#{id} is already assigned to #{@_nodes[id]}") if @_nodes[id]?
            @_nodes[id] = new Track(this, { id:id })
            @_nodes[id].add node_list
            return @_nodes[id]
          else if @_nodes?[id]?
            return @_nodes[id]
          else throw new Error("No Track found with id #{id}")
        else
          throw new Error("Track id must be a string")
          


        
      node: (id, node_list...) ->
        return new MooogAudioNode(this) unless arguments.length
        if typeof id is 'string'
          if node_list.length
            throw new Error("#{id} is already assigned to #{@_nodes[id]}") if @_nodes[id]?
            @_nodes[id] = new MooogAudioNode(this, id, node_list...)
          else if @_nodes?[id]?
            return @_nodes[id]
          else throw new Error("No MooogAudioNode found with id #{id}")
        else
          node = new MooogAudioNode(this, [id].concat(node_list...)...)
          @_nodes[node.id] = node
      
      
### Mooog.freq
Convenience function for converting MIDI notes to equal temperament Hz


      @freq: (n) ->
        440 * Math.pow(2,((n-69)/12))

      
      sawtoothPeriodicWave: (harms) ->
        harms ?= @config.periodic_wave_length
        a = [0]
        a.push(1/i) for i in [1..harms-1]
        real = new Float32Array(a)
        imag = new Float32Array(real.length)
        return @context.createPeriodicWave(real, imag)

    
      squarePeriodicWave: (harms) ->
        harms ?= @config.periodic_wave_length
        a = [0]
        for i in [1..harms-1]
          if i%2 != 0
            a.push(2/(Math.PI * i))
          else
            a.push(0)
        real = new Float32Array(a)
        imag = new Float32Array(real.length)
        return @context.createPeriodicWave(real, imag)

    
      trianglePeriodicWave: (harms) ->
        harms ?= @config.periodic_wave_length
        a = [0]
        for i in [1..harms-1]
          if i%2 != 0
            a.push(1/(Math.pow(i,2)))
          else
            a.push(0)
        real = new Float32Array(a)
        imag = new Float32Array(real.length)
        return @context.createPeriodicWave(real, imag)
    
    
      sinePeriodicWave: (harms) ->
        a = [0, 1]
        real = new Float32Array(a)
        imag = new Float32Array(real.length)
        return @context.createPeriodicWave(real, imag)
      



    window.Mooog = Mooog
