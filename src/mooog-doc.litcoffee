# Mooog

> Chainable AudioNode objects

### What is Mooog?

Mooog is inspired by audio mixing boards on the one hand and jQuery chainable
syntax on the other. It automatically does a lot of stuff so you don't have to.
Mooog's goal is to take some of the tedium work out of working with AudioNodes,
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
    { id:'lfo', node_type:'Oscillator', connect_to_destination:false, type:'sawtooth', frequency:3 }
  )
  .start()
  .chain(
    M.node( {id:'gain',node_type:'Gain',connect_to_destination:false,gain:40} )
  )
  .chain(
    M.node({id:'osc',node_type:'Oscillator',frequency:300}), 'frequency'
  )
  .start()
```


### What Mooog isn't

Mooog is not a shim for the deprecated Audio API. It also doesn't (yet) worry
about cross-platform issues. It is developed and tested on the latest version
of Google Chrome, and expects to run there. Ensuring cross-platform
consistency is on the to-do list once the API stabilizes. 

### Features
Mooog provides nestable `Node` objects that wrap AudioNodes. At a minumum, they
expose the methods of the wrapped Node, so you can talk to them just like the
underlying AudioNode. Many of them offer additional functionality

There is also a specialized Node object called `Track`, which will automatically
create a panner and a gain module that can be controlled from a single place, as
well as effect sends. It automatically routes the end of its internal chain
to the destinationNode.

### Attributions
The Convolver `Node` comes with some presets that make use of impulse responses
from the [OpenAir](http://www.openairlib.net/) project:

  - *stalbans_a_binaural.wav*    
  The Lady Chapel, St Albans Cathedral: 
  [CC share/share alike license](http://creativecommons.org/licenses/by-sa/3.0/)
    - www.openairlib.net
    - Audiolab, University of York
    - Marcin Gorzel
    - Gavin Kearney
    - Aglaia Foteinou
    - Sorrel Hoare
    - Simon Shelley
