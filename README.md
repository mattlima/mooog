# Mooog

##Chainable AudioNode API

Version 0.0.2

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

If you want to jump right in, see the examples. They won't run well on the local
filesystem because of CORS restrictions on AJAX audio file loads, so they're also
posted [on the github project page](http://mattlima.github.io/mooog/).

### Initializing Mooog

Mooog sets up a (Webkit)AudioContext object and manages connections to its `DestinationNode` automatically.
It takes an optional configuration object with the following properties:

- `debug`: Output debugging messages to the console. *Default: false*
- `default_gain`: `Gain` objects that are initiated will have their gain automatically set to this value. *Default: 0.5*
- `default_ramp_type`: `adsr` envelopes will be produced using this type of curve ('linear or 'expo'). *Default: 'expo'*
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

Internally, `param()` actually calls `AudioParam.cancelScheduledValues()` and then uses `AudioParam.setValueAtTime(value, currentTime)` 
by default in order to ensure consistent behavior.
Put another way, using `param()` will **always** have the desired effect regardless of whether
other value changes have been scheduled on that parameter, unlike acting on `Audioparam.value` directly.

#### Parameters in time
The `AudioParam` API provides 5 different methods for scheduling parameter changes. `param()` can 
be used to call any of them by adding properties to the object submitted. Here are examples using
an oscillator's `frequency` parameter. Note the use of `from_now` which causes a call to `setValueAtTime`
at the currentTime if used with linear or exponential ramp functions.

- Set `frequency` to 800 immediately. (Use `setValueAtTime`)  
`osc.param( {frequency: 800} );`

- Set `frequency` to 800, 4 seconds from now. (Use `setValueAtTime`)  
`osc.param( {frequency: 800, at: 4} );`

- Ramp `frequency` linearly to 800, starting after the last scheduled value change (or now, if 
there isn't one) and arriving 4 seconds from now. (Use `linearRampToValueAtTime`)  
`osc.param( {frequency: 800, at: 4, ramp: 'linear'} );`

- Ramp `frequency` linearly to 800, starting now and arriving 4 seconds from now.
`osc.param( {frequency: 800, at: 4, ramp: 'linear', from_now: true} );`

- Ramp `frequency` exponentially to 800 over 4 seconds, starting now.
(Use `exponentialRampToValueAtTime`)  
`osc.param( {frequency: 800, at: 4, ramp: 'expo', from_now: true } );`

- Set `frequency` to asymptotically approach 800, beginning 4 seconds from now. 
(Use `setTargetAtTime`)  
`osc.param( {frequency: 800, at: 4, ramp: 'expo', timeConstant: 1.5} );`

- Set `frequency` to values 300, 550, 900, 800 over a period of 2 seconds.* 
(Use `setValueCurveAtTime`)  
`osc.param( {frequency: [300, 550, 900, 800], duration: 2, ramp: 'curve'} );`  
*The rhythmic irregularity of the frequency progression produced by the `setValueCurveAtTime()`
method is due to the nearest-value interpolation algorithm it uses. The function is meant for much larger arrays 
of values describing smooth curves.

The `cancel` and `at` parameters can be used with any of the `ramp` types. 

#### ADSR envelopes
For convenience, you can create ADSR, ASR, or ADS envelopes with the `adsr` method of any Node:

> `MooogAudioNode.adsr( param: mixed, config: object )` 

`param`: An `AudioParam` or the string name of the `AudioParam`, assumed to be on `this`.  
`config`: Object with the following properties: 
- base: The value to start and end with. *Defaults to 'zero'*
- times: An array of time values representing the ending time of each of the 
ADSR stages. The first is relative to the currentTime, and the others are relative
to the previous value. The delay stage can be suppressed by passing an array of three 
elements, in which case the envelope will be an ASR and the `s` value will be ignored.
The release stage can be suppressed by passing an array of 2 elements, in which case the
envelope will be an ADS envelope (useful if you're responding to user input or the duration of the note cannot be predetermined.)
- a: The final value of the parameter at the end of the attack stage. *Defaults to 1*
- s: The value of the parameter at the end of the delay stage (or attack stage, 
if delay is omitted), to be held until the beginning of the release stage. *Defaults to 1*  
- ramp: 'linear' or 'expo', determines the ramping function to use. *Defaults to the `default_ramp_type`
property of the Mooog config object*

A very small number `fake_zero` is used in place of actual zero if given as the `base`, `a`, or `s`
property so that the exponential ramping function doesn't throw an error. `fake_zero` defaults to
1/65536 but can be configured when Mooog is initialized. 
  


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
M.track('my_track').send('rev_send').param('gain', 0.25);
```

Creates a send to another `Track` object.  
`id`: String ID to assign to this send.  
`destination`: The target `Track` object or ID thereof  
`pre`: Either 'pre' or 'post'. *Defaults to config value in the `Mooog` object.*  
`gain`: Initial gain value for the send. *Defaults to config value in the `Mooog` object.*  


## Utilities

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

## Additional Node-specific details

### AudioBufferSource
- Exposes a `state` property that is either 'stopped' or 'playing'
- Includes a config object property `buffer_source_file` indicating the URL of an audio asset from
which to create an AudioBuffer and then set the `buffer` of the underlying `AudioNode`
- Automatically regenerates the `buffer` when the `stop()` method is used so you can repeatedly `stop` 
and `start` without initializing a new Node.

### Convolver
- Includes a config object property `buffer_source_file` indicating the URL of an audio asset (impulse
response) from which to create an AudioBuffer and then set the `buffer` of the underlying `AudioNode`

### Delay
- Exposes a `feedback` property that maps to the `Gain` of a feedback stage. Defaults to zero,
and can be set on initialization: `Mooog.node( { node_type: 'Delay', feedback: 0.2 } )`

### Gain
- Saturation can easily occur in signal chains with multiple paths when they are summed at the output.
To alleviate this effectm the `Gain` object is initiliazed with `gain` set to 0.5 instead of 1.0. You can 
change this default with the `default_gain` Mooog config option.

### Oscillator
- Exposes a `state` property that is either 'stopped' or 'playing'
- Sets an internal `gain` so you can repeatedly `stop` and `start` without initializing a new Node.

### WaveShaper
Includes utility functions [tanh](http://mymbs.mbs.net/~pfisher/FOV2-0010016C/FOV2-0010016E/FOV2-001001A3/tutorials/ezine1/distortion.html) for hyperbolic tangent and [chebyshev](http://music.columbia.edu/cmc/MusicAndComputers/chapter4/04_06.php) for Chebyshev polynomials, generating Float32Array distortion curves. `tanh` takes a single argument representing the coefficient (higher coefficients equal more aggressive shaping). `chebyshev` takes a single argument indicating the number of terms to generate (the exponent of the first term). 
```javascript
/* create the waveshaper */
var shaper = M.node("my_waveshaper", M.node({ node_type:"WaveShaper" });

/* Use a tanh waveshaping curve */
shaper.curve = shaper.tanh(2); 

/* Use a 5th-order Chebyshev polynomial waveshaper */
shaper.curve = shaper.chebyshev(5); 
```

## License

The MIT License (MIT)

Copyright (c) 2015 Matthew Lima

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

### Donations

If you're feeling generous, you can throw me some dosh [here.](https://www.paypal.me/MattLima)

## Todo:

- Equalize gain, add error messages for unsupported browsers in examples
- Optionally use periodic waves for basic oscillator types to minimize volume differences
- Vary duty cycle on period wave generator
- Refactor initialization to combine `configure_from` and `zero_node_setup`
- Clean up debug messages
- Emit loaded event when using `buffer_source_file`
- Allow parameter arrays in `adsr()`

## Contributing

[CONTRIBUTING.md](https://github.com/mattlima/mooog/blob/master/CONTRIBUTING.md)








