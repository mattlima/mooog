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
chain) so you can talk to them just like the underlying AudioNode. 
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
- `periodic_wave_length`: The `PeriodicWave` generator functions calculate up to this many partials. *Default: 2048*
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
Here we've assigned the node reference to a variable, but we can also reference an initialized node using its
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

If you want to link nodes in series, you can use `chain()` instead of `connect()`. 

> You can also easily initialize chains of nodes in a single Track object. See below.

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

### Working with parameters

#### The `param()` getter/setter
AudioNode parameters are a mix of enumerated properties, strings, numbers, and `AudioParam` objects. Mooog 
supports setting any of these jQuery-style via the `param()` getter/setter function. 

```javascript
var osc = M.node('my_oscillator', 'Oscillator');
osc.param('frequency'); // -> returns 440 
osc.param('frequency', 800); // -> returns 800
osc.param('frequency'); // -> returns 800
```

Like jQuery, multiple parameters can be set in the same param call:

`osc.param( {frequency: 800, type: 'sawtooth'} );`

Internally, `param()` actually calls `AudioParam.cancelScheduledValues()` and then uses `AudioParam.setValueAtTime(value, currentTime)` by default in order to ensure consistent behavior.
Put another way, using `param()` will **always** have the desired effect regardless of whether
other value changes have been scheduled on that parameter.  

#### Parameters in time
The `AudioParam` API provides 5 different methods for scheduling parameter changes. `param()` can 
be used to call any of them by adding properties to the object submitted. Here are examples using
an oscillator's `frequency` parameter:
- Set `frequency` to 800 immediately. (Use `setValueAtTime`)  
`osc.param( {frequency: 800} );`

- Set `frequency` to 800, 4 seconds from now. (Use `setValueAtTime`)  
`osc.param( {frequency: 800, at: 4} );`
- Set `frequency` to 200, 4 seconds after the previous parameter change.
(Use `setValueAtTime` without first calling `cancelScheduledValues`)  
`osc.param( {frequency: 800, at: 4, cancel: false} );`
- Ramp `frequency` from current value linearly, to 800, arriving 4 seconds from now.
(Use `linearRampToValueAtTime`)  
`osc.param( {frequency: 800, at: 4, ramp: 'linear'} );`
- Ramp `frequency` from current value exponentially, to 800, arriving 4 seconds from now.
(Use `exponentialRampToValueAtTime`)  
`osc.param( {frequency: 800, at: 4, ramp: 'expo'} );`
- Set `frequency` to asymptotically approach 800, beginning 4 seconds from now. 
(Use `setTargetAtTime`)  
`osc.param( {frequency: 800, at: 4, ramp: 'expo', timeConstant: 1.5} );`
- Set `frequency` to values 300, 550, 900, 800 over a period of 2 seconds. 
(Use `setValueCurveAtTime`)  
`osc.param( {frequency: [300, 550, 900, 800], duration: 2, ramp: 'curve'} );`

The `cancel` and `at` parameters can be used with any of the `ramp` types. 

#### ADSR envelopes



### The Track Object

Mooog includes a `Track` object designed to make working with lots of nodes a little easier. You set up and refer to
the Track with a unique string identifier (just like a node), and populate its internal chain of nodes with one or
more additional arguments to the creator function: 

```javascript
M.track( 'my_track', node [, node...] );
```
Each `node` argument can be a node definition object of the type you'd pass to the `Mooog.node()` function or an existing
node. The Track object routes the last node in its internal chain through a pan/gain stage. Like all nodes, the Track exposes
the native methods/properties of the first node in its internal chain, but it also exposes the `gain` and `pan` AudioParams of 
the nodes in the pan/gain stage directly. 

Tracks can be used interchangeably with nodes as arguments to functions like `connect()` and `chain()`. 

Tracks have a `send()` function analagous to mixing board sends. Once created, the send (which is a `Gain` node) is referenced by string id, just like Tracks and other nodes. 

```javascript
/* create the track */
M.track("my_track", M.node({id:"sin", node_type:"Oscillator", type:"sawtooth"}), { id:"fil",node_type:"BiquadFilter" } );

/* Set up a reverb effect track*/
rev = M.track('reverb', { id:"cv", node_type:"Convolver", buffer_source_file:"/some-impulse-response.wav" });

/* Create the send */
M.track('my_track').send('rev_send', rev, 'post');

/* Come back later and change the gain */
M.track('my_track').send('rev_send').param('gain', 0.25)
```

Creates a send to another `Track` object.  
`id`: String ID to assign to this send.  
`destination`: The target `Track` object or ID thereof  
`pre`: Either 'pre' or 'post'. *Defaults to config value in the `Mooog` object.*  
`gain`: Initial gain value for the send. *Defaults to config value in the `Mooog` object.*  


## Utilities and Node-specific details

### Mooog.freq()

A convenience function for converting MIDI notes to equal temperament Hz

### PeriodicWave constructors

The native versions of the native (Sine, Sawtooth, Triangle, Square) waveforms 
are louder than equivalent waveforms created with `createPeriodicWave` so if your signal path
includes both it may be easier to mix them if you use generated versions of the native waveforms: 
 
####Mooog.sawtoothPeriodicWave(n)

Calculates and returns a sawtooth `PeriodicWave` up to the nth partial.
 
####Mooog.squarePeriodicWave(n)

Calculates and returns a square `PeriodicWave` up to the nth partial.
 
####Mooog.trianglePeriodicWave(n)

Calculates and returns a triangle `PeriodicWave` up to the nth partial.
 
####Mooog.sinePeriodicWave()

Returns a sine `PeriodicWave`.




### Todo:

- Optionally use periodic waves for basic oscillator types to minimize volume differences
- Vary duty cycle on period wave generator

### Patches
- Allows `Oscillator`, `AudioBufferSource` nodes to be `stop()`ed and 
`start()`ed again without throwing errors.
- Changes to `AudioParam` values via `.param()` are made using setValueAtTime(0)
to ensure values are set instantly





[Make a donation](https://www.paypal.me/MattLima)


