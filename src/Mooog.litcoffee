## Mooog

Wraps the AudioContext object and exposes the Track object. Exposes the API
as the Mooog global.  


    class Mooog
    
      @LEGAL_NODES:
      
        'Analyser': Analyser
        'AudioBufferSource': AudioBufferSource
        'BiquadFilter': BiquadFilter
        'ChannelMerger': ChannelMerger
        'ChannelSplitter': ChannelSplitter
        'Convolver': Convolver
        'Delay': Delay
        'DynamicsCompressor': DynamicsCompressor
        'Gain': Gain
        'MediaElementSource': MediaElementSource
        'Oscillator': Oscillator
        'Panner': Panner
        'ScriptProcessor': ScriptProcessor
        'StereoPanner': StereoPanner
        'WaveShaper': WaveShaper
      
      @MooogAudioNode = MooogAudioNode
      
      @EVENT_NAMES:
        AUDIO_BUFFER_LOADED: 'mooog.audioBufferLoaded'
      



      
      constructor: (@initConfig = {}) ->
        @config =
          debug: false
          default_gain: 0.5
          default_ramp_type: 'expo'
          default_send_type: 'post'
          periodic_wave_length: 2048
          curve_length: 65536
          fake_zero: 1/65536
          allow_multiple_audiocontexts: false


It's not unusual to have several AudioBufferNodes using the same buffer source
file. If they are initialized at the same time, each one will make an HTTP
request for the file, resulting in a lot of unnecessary network traffic. We store
the URLs of audio assets here to make sure they're only loaded once by any object that needs them
      
      
        @audioBuffersLoaded = {}
              

`_BROWSER_CONSTRUCTOR` Stores the type of constructor used for the AudioContext 
object (`AudioContext` or `webkitAudioContext`)

        @_BROWSER_CONSTRUCTOR = false
        @context = @create_context()
        @_destination = @context.destination
        
        @init(@initConfig)
        
        Mooog.browser_test()
        @iOS_setup()
        @_nodes = {}
        #@_connections = {}
        @__typeof = MooogAudioNode.prototype.__typeof
        console.log "AudioContext not fully supported in this browser.
        Run Mooog.browser_test() for more info" unless Mooog.browser_test().all


### Mooog.iOS_setup
A little hocus pocus to get around Apple's restrictions on sound production before
use input. Taken from 
https://github.com/shinnn/AudioContext-Polyfill/blob/master/audiocontext-polyfill.js

      iOS_setup: () ->
        is_iOS = (navigator.userAgent.indexOf('like Mac OS X') isnt -1)
        if is_iOS
          body = document.body
          tmpBuf = @context.createBufferSource()
          tmpProc = @context.createScriptProcessor(256, 1, 1)
          instantProcess = () =>
            tmpBuf.start(0)
            tmpBuf.connect(tmpProc)
            tmpProc.connect(@context.destination)
          body.addEventListener('touchstart', instantProcess, false)
          tmpProc.onaudioprocess = () ->
            tmpBuf.disconnect()
            tmpProc.disconnect()
            body.removeEventListener('touchstart', instantProcess, false)
            tmpProc.onaudioprocess = null


      init: (initConfig) ->
        for key, val of @config
          if initConfig[key]?
            @config[key] = initConfig[key]
        null

        
      @context = false
      
      create_context: () ->
        @_BROWSER_CONSTRUCTOR = switch
          when window.AudioContext? then 'AudioContext'
          when window.webkitAudioContext? then 'webkitAudioContext'
          else throw new Error("This browser does not yet support the AudioContext API")
        if @config.allow_multiple_audiocontexts
          return new window[@_BROWSER_CONSTRUCTOR]
        Mooog.context || Mooog.context = new window[@_BROWSER_CONSTRUCTOR]
          
        


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
          

### Mooog.node

Creates new nodes or chains of nodes. Signatures:

> node(id:string, node_type:string)

`id`: A unique identifier to assign to this Node
`node_type`: String representing the type of Node to initialize


> node(node_definition:object)
> node(id:string, node_definition:object [, node_definition...])

`node_definition`: An object used to create and configure the new Node. 

Required properties:
  - `node_type`: String indicating the type of Node (Oscillator, Gain, etc.)
  
Optional properties for all nodes
  - `id`: Unique string identifier, will be created programatically if not given.
  - `connect_to_destination`: Boolean indicating whether the last in this node's 
`_nodes` array is automatically connected to the `AudioDestinationNode`. *default: true*

Additional properties  
  - Any additional key-value pairs will be used to set properties of the underlying `AudioNode`
object after initialization. 

If more than one `node_definition` object is given, the first argument must be a string id
to assign to a `MooogAudioNode` base node. The nodes will be added to its internal chain 
according to the `node_definition` objects.


      node: () ->
        arg0 = arguments[0]
        arg1 = arguments[1]
        type0 = @__typeof arg0
        type1 = @__typeof arg1
        
        
Take care of first type signature (ID and string type)
        
    
        if type0 is "string" and type1 is "string"
          if Mooog.LEGAL_NODES[arg1]?
            if @_nodes[arg0]
              throw new Error("#{arg0} is already assigned to #{@_nodes[arg0]}")
            @_nodes[arg0] = new Mooog.LEGAL_NODES[arg1] @, { id: arg0, node_type: arg1 }
          else
            console.log(arguments)
            throw new Error "Unknown node type #{arg1}"
            
            
This might be a request for an existing node
        
    
        else if type0 is "string" and type1 is "undefined"
          if @_nodes[arg0]
            return @_nodes[arg0]
          else
            throw new Error("No MooogAudioNode found with id #{arg0}")
    
            
Is it a single `node_definition` object?
    
        
        else if type0 is "object" and type1 is "undefined"
          if @_nodes[arg0.id]
            throw new Error("#{arg0.id} is already assigned to #{@_nodes[arg0.id]}")
          else if Mooog.LEGAL_NODES[arg0.node_type]?
            new_node = new Mooog.LEGAL_NODES[arg0.node_type] @, arg0
            @_nodes[new_node.id] = new_node
          else
            throw new Error("Omitted or undefined node type in config options.")
        
Or an array of `node_definition` objects
        
        
        else if type0 is "object" and type1 is "object"
          throw new Error "A string id for the base node must be provided if you give
          more than one node definition"
        
        else if type0 is "string" and type1 is "object"
          new_node = new MooogAudioNode @, {id: arg0}
          @_nodes[new_node.id] = new_node
          for i in arguments
            new_node.add new MooogAudioNode @, i
            
            
        

### Mooog.extend_with

Adds a new node definition from defined after initialization. At a minimum, the node definition
looks like:

``` coffeescript
class MyNewNode extends Mooog.MooogAudioNode
  constructor: (@_instance, config)->
    super

  #this hook runs before the configuration object is parsed
  before_config: (config)->
    #do something here like create the internal node chain
  
  #this hook runs after the configuration object is parsed
  after_config: (config)->
    #add additional nodes, perform post-config settings

  #all object properties defined will be available on the node
  some_new_function: (e) ->
    

#Then run this command to sanity-check the node and make it available via the Mooog instance
Mooog.extend_with "MyNewNodeName", MyNewNode
```


      @extend_with: (nodeName, nodeDef) ->
        window.nodeDef = nodeDef
        if !nodeDef.prototype.before_config?
          throw new Error "Node definition prototype must have a before_config function"
        if !nodeDef.prototype.after_config?
          throw new Error "Node definition prototype must have a before_config function"
        if Mooog.LEGAL_NODES[nodeName]?
          throw new Error "#{nodeName} class already defined"
        Mooog.LEGAL_NODES[nodeName] = nodeDef
        null
      
      
                


      
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
      
      

### Mooog.browser_test
Tests parts of the API to see whether Mooog will run correctly in a browser. Attempts to
patch a few of them (StereoPanner, noteOn/NoteOff), and returns an object of test results
including an `all` property which should indicate whether Mooog can do its thing, or simply
false if the AudioContext API is not supported at all.

      @brower_test_results: false
      
      @browser_test: ()->
        if @browser_test_results
          return @browser_test_results
        tests = { all: true }
        ctxt = window.AudioContext || window.webkitAudioContext
        tests.all = if (tests.audio_context = !!ctxt) then tests.all else false
        return false if !ctxt
        __t = new ctxt()
        tests.all = if (tests.unprefixed = window.AudioContext?) then tests.all else false
        tests.all = if (tests.start_stop = __t.createOscillator().start?) then tests.all else false
        if __t.createStereoPanner?
          tests.stereo_panner = true
        else
          try
            @patch_StereoPanner()
            tests.stereo_panner = 'patched'
          catch error
            test.stereo_panner = false
            tests.all = false
        tests.all = if (tests.script_processor = __t.createScriptProcessor?)
        then tests.all else false
        @browser_test_results = tests
        


### Mooog.patch_StereoPanner
Safari currently lacks support for the StereoPanner node. This function patches it.
Adapted from 
(https://github.com/mohayonao/stereo-panner-node)[https://github.com/mohayonao/stereo-panner-node]

        
        
        
      @patch_StereoPanner: () ->
        WS_CURVE_SIZE = 4096
        curveL = new Float32Array(WS_CURVE_SIZE)
        curveR = new Float32Array(WS_CURVE_SIZE)
      
        for i in [0..WS_CURVE_SIZE]
          curveL[i] = Math.cos((i / WS_CURVE_SIZE) * Math.PI * 0.5)
          curveR[i] = Math.sin((i / WS_CURVE_SIZE) * Math.PI * 0.5)
      
        ###
            
         *  StereoPannerImpl
         *  +--------------------------------+  +------------------------+
         *  | ChannelSplitter(inlet)         |  | BufferSourceNode(_dc1) |
         *  +--------------------------------+  | buffer: [ 1, 1 ]       |
         *    |                            |    | loop: true             |
         *    |                            |    +------------------------+
         *    |                            |       |
         *    |                            |  +----------------+
         *    |                            |  | GainNode(_pan) |
         *    |                            |  | gain: 0(pan)   |
         *    |                            |  +----------------+
         *    |                            |    |
         *    |    +-----------------------|----+
         *    |    |                       |    |
         *    |  +----------------------+  |  +----------------------+
         *    |  | WaveShaperNode(_wsL) |  |  | WaveShaperNode(_wsR) |
         *    |  | curve: curveL        |  |  | curve: curveR        |
         *    |  +----------------------+  |  +----------------------+
         *    |               |            |               |
         *    |               |            |               |
         *    |               |            |               |
         *  +--------------+  |          +--------------+  |
         *  | GainNode(_L) |  |          | GainNode(_R) |  |
         *  | gain: 0    <----+          | gain: 0    <----+
         *  +--------------+             +--------------+
         *    |                            |
         *  +--------------------------------+
         *  | ChannelMergerNode(outlet)      |
         *  +--------------------------------+
        ###
      
        class StereoPannerImpl
      
          constructor: (audioContext) ->
            @audioContext = audioContext
            @inlet = audioContext.createChannelSplitter(2)
            @_pan = audioContext.createGain()
            @pan = @_pan.gain
            @_wsL = audioContext.createWaveShaper()
            @_wsR = audioContext.createWaveShaper()
            @_L = audioContext.createGain()
            @_R = audioContext.createGain()
            @outlet = audioContext.createChannelMerger(2)
      
            @inlet.channelCount = 2
            @inlet.channelCountMode = "explicit"
            @_pan.gain.value = 0
            @_wsL.curve = curveL
            @_wsR.curve = curveR
            @_L.gain.value = 0
            @_R.gain.value = 0
      
            @inlet.connect(@_L, 0)
            @inlet.connect(@_R, 1)
            @_L.connect(@outlet, 0, 0)
            @_R.connect(@outlet, 0, 1)
            @_pan.connect(@_wsL)
            @_pan.connect(@_wsR)
            @_wsL.connect(@_L.gain)
            @_wsR.connect(@_R.gain)
      
            @_isConnected = false
            @_dc1buffer = null
            @_dc1 = null
      
          connect:  (destination) ->
            audioContext = @audioContext
      
            if (!@_isConnected)
              @_isConnected = true
              @_dc1buffer = audioContext.createBuffer(1, 2, audioContext.sampleRate)
              @_dc1buffer.getChannelData(0).set([ 1, 1 ])
      
              @_dc1 = audioContext.createBufferSource()
              @_dc1.buffer = @_dc1buffer
              @_dc1.loop = true
              @_dc1.start(audioContext.currentTime)
              @_dc1.connect(@_pan)
      
            AudioNode.prototype.connect.call(@outlet, destination)
      
      
          disconnect: () ->
            @audioContext
      
            if (@_isConnected)
              @_isConnected = false
              @_dc1.stop(audioContext.currentTime)
              @_dc1.disconnect()
              @_dc1 = null
              @_dc1buffer = null
      
            AudioNode.prototype.disconnect.call(@outlet)
      
      
      
      
      
        class StereoPanner
      
          constructor: (audioContext) ->
            impl = new StereoPannerImpl(audioContext)
      
            Object.defineProperties(impl.inlet,
              pan:
                value: impl.pan,
                enumerable: true
              connect:
                value: (node) ->
                  return impl.connect(node)
              disconnect:
                value: () ->
                  return impl.disconnect()
            )
      
            return impl.inlet
      
      
        ctxt = window.AudioContext || window.webkitAudioContext
        if (!ctxt || ctxt.prototype.hasOwnProperty("createStereoPanner"))
          return
        else
          ctxt.prototype.createStereoPanner = () ->
            return new StereoPanner(this)


    window.Mooog = Mooog
