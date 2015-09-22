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

      
      constructor: (@initConfig = {}) ->
      
`_BROWSER_CONSTRUCTOR` Stores the type of constructor used for the AudioContext 
object (`AudioContext` or `webkitAudioContext`)

        @_BROWSER_CONSTRUCTOR = false
        @context = @create_context()
        @_destination = @context.destination
        @config =
          debug: false
          default_gain: 0.5
          default_ramp_type: 'expo'
          default_send_type: 'post'
          periodic_wave_length: 2048
          curve_length: 65536
          fake_zero: 1/65536
        @init(@initConfig)
        
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
          instantProcess = () ->
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
Tests a few API hooks see whether Mooog will run correctly in a browser. Returns
an object of test results, including `all` property which should indicate whether
Mooog can do its thing.


      @browser_test: ()->
        ctxt = window.AudioContext || window.webkitAudioContext
        __t = new ctxt()
        tests = { all: true }
        tests.all = if (tests.unprefixed = window.AudioContext?) then tests.all else false
        tests.all = if (tests.start_stop = __t.createOscillator().start?) then tests.all else false
        tests.all = if (tests.stereo_panner = __t.createStereoPanner?) then tests.all else false
        tests.all = if (tests.script_processor = __t.createScriptProcessor?)
        then tests.all else false
        tests


    window.Mooog = Mooog
