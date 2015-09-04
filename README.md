# Mooog

##Chainable AudioNode API

Version 0.0.1a

### What is Mooog?

Mooog is inspired by audio mixing boards on the one hand and jQuery chainable
syntax on the other. It automatically does a lot of stuff so you don't have to.
Mooog's goal is to take some of the tedium out of working with AudioNodes,
as well as patching some odd behaviors. With Mooog, instead of writing this:

```javascript
AudioContext = AudioContext || webkitAudioContext;  
var ctxt = new AudioContext();  
var osc = ctxt.createOscillator();  
var lfo = ctxt.createOscillator();  
var gain = ctxt.createGain();  
osc.frequency.value = 300;  
lfo.type = 'sawtooth';  
lfo.frequency.value = 3;  
lfo.connect(gain);  
gain.gain.value = 40;  
gain.connect(osc.frequency);  
osc.connect(ctxt.destination);  
lfo.start();  
osc.start();
```

...you can write this:
```javascript
M = new Mooog();
M.node(
    { id:'lfo', node_type:'Oscillator', type:'sawtooth', frequency:3 }
  )
  .start()
  .chain(
    M.node( {id:'gain', node_type:'Gain', gain:40} )
  )
  .chain(
    M.node({id:'osc', node_type:'Oscillator', frequency:300}), 'frequency'
  )
  .start()
```

### What Mooog isn't

Mooog is not a shim for the deprecated Audio API. It also doesn't (yet) worry
about cross-platform issues. It is developed and tested on the latest version
of Google Chrome, and expects to run there. Ensuring cross-platform 
consistency is on the to-do list once the API stabilizes and browser support
improves. 

### Features
Mooog provides a `MooogAudioNode` object that can wrap one or more AudioNodes. 
At a minumum, it exposes the methods of the wrapped Node (or the first in its internal
chain, so you can talk to them just like the underlying AudioNode. 
Many of them offer additional functionality. There are also utilities like 
an ADSR generator as well as functions to generate common waveshaping curves like Chebyshevs 
and `tanh`.

There is also a specialized MooogAudioNode object called `Track`, which will automatically
create panner and gain nodes at the end of its internal chain that can be controlled 
from a single place and easily create sends to other `Track`s. Like the base 
`MooogAudioNode`, it automatically routes the end of its internal chain to the destinationNode.

## Getting started

### Initializing Mooog

Mooog sets up a (Webkit)AudioContext object and manages connections to its `DestinationNode` automatically.
It takes an optional configuration object with the following properties:

- `debug`: Output debugging messages to the console. *Default: false*
- `default_gain`: `Gain` objects that are initiated will have their gain automatically set to this value. *Default: 0.5*
- `default_ramp_type`: `adsr` envelopes will be produced using this type of curve. *Default: 'exponential'*
- `default_send_type`: For sends from `Track` objects. *Default: 'post'*
- `periodic_wave_length`: The `PeriodicWave` generator functions produce buffers of this length. *Default: 2048*
- `curve_length`: The `WaveShaper` curve generator functions produce `Float32Array`s of this length. *Default: 65536*
- `fake_zero`: This number is substituted for zero to prevent errors when zero is passed to an exponential ramp function. *Default: 1 / 65536*
          

### Creating AudioNodes

Nodes are created via the `node()` method of the Mooog object, which takes a node definition object with a single required
parameter, `node_type`. You can also give it a string id to reference it later on:

```javascript
M = new Mooog();
var my_oscillator = M.node( { 
    id: "my_new_node_string_id",
    node_type: "Oscillator"
} );
```
Here we've assigned the Node reference to a variable, but we can also reference an initialized node using its
id as a single argument:

`M.node('my_new_node_string_id');`

The `node_type` parameter is the name of the `AudioNode` as found in its create function, i.e. "Gain" because `AudioContext.createGain()`, "BiquadFilter" because `AudioContext.createBiquadFilter()`, etc. 

Any other parameters you want to set on the `AudioNode` can be submitted as part of the node definition:

```javascript
var my_oscillator = M.node( { 
    id: "my_new_node_string_id",
    node_type: "Oscillator",
    frequency: 850,
    type: "sawtooth"
} );
```

If you don't need to set parameters, there is also a shorthand for creating a node where you specify only the id and the type:

```javascript
var my_oscillator = M.node( "my_new_node_string_id", "Oscillator" );
```


Nodes automatically route their output to the `DestinationNode` of the context. To override this behavior 
(useful if you're creating LFOs to modulate `AudioParams`, for example), pass `connect_to_destination : false` 
in the node definition object: 

```javascript
var my_oscillator = M.node( { 
    id: "my_new_node_string_id",
    node_type: "Oscillator",
    connect_to_destination: false
} );
```

### Connecting AudioNodes

`connect()` works just like the native `AudioNode` method, except it returns the source, so you can chain them 
to accomplish fan-out more easily:

```javascript
M.node("my_previously_created_audio_buffer_source")
    .connect( M.node({ id: "my_short_delay", node_type: "Delay", delayTime: 0.2 }) )
    .connect( M.node({ id: "my_long_delay", node_type: "Delay", delayTime: 1.5 }) );
```

If you want to link Nodes in series, you can use `chain()` instead of `connect()`. 

> You can also easily initialize chains of Nodes in a single Track object. See below.

`chain` returns the destination node, not the source node. It also automatically disconnects the source 
from the context's `AudioDestinationNode`. To `chain` an `AudioParam`, use the name of the param as the 
second argument.

```javascript
M.node("my_previously_created_audio_buffer_source")
    .chain( M.node({ id: "my_delay", node_type: "Delay", delayTime: 0.5 ) )
    .chain( M.node({ id: "my_reverb", node_type: "Convolver", buffer_source_file: "/my-impulse-response.wav" ) );
```

`disconnect()` works like the native function but won't throw an error if the connection doesn't exist. It will output
a warning to the console if Mooog was initialized with `debug: true`. 


## Node-specific details

### Todo:

- Optionally use periodic waves for basic oscillator types to minimize volume differences

### Patches
  - Allows `Oscillator`, `AudioBufferSource` nodes to be `stop()`ed and 
  `start()`ed again without throwing errors.
  - Changes to `AudioParam` values via `.param()` are made using setValueAtTime(0)
  to ensure values are set instantly





[Make a donation](https://www.paypal.me/MattLima)


