(function() {
  var Analyser, AudioBufferSource, BiquadFilter, ChannelMerger, ChannelSplitter, Convolver, Delay, DynamicsCompressor, Gain, MediaElementSource, Mooog, MooogAudioNode, Oscillator, Panner, ScriptProcessor, StereoPanner, Track, WaveShaper,
    slice = [].slice,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  MooogAudioNode = (function() {
    function MooogAudioNode(_instance, config) {
      this._instance = _instance;
      this._destination = this._instance._destination;
      this.context = this._instance.context;
      this._nodes = [];
      this.config_defaults = {
        connect_to_destination: true
      };
      this.config = {};
      this._connections = [];
      this._exposed_properties = {};
      if (this.constructor.name === "MooogAudioNode") {
        if (Mooog.LEGAL_NODES[config.node_type] != null) {
          return new Mooog.LEGAL_NODES[config.node_type](this._instance, config);
        } else {
          throw new Error("Omitted or undefined node type in config options.");
        }
      } else {
        this.configure_from(config);
        this.before_config(config);
        this.zero_node_setup(config);
        this.after_config(config);
      }
    }

    MooogAudioNode.prototype.configure_from = function(ob) {
      var k, ref, v;
      this.node_type = ob.node_type != null ? ob.node_type : this.constructor.name;
      this.id = ob.id != null ? ob.id : this.new_id();
      ref = this.config_defaults;
      for (k in ref) {
        v = ref[k];
        this.config[k] = k in ob ? ob[k] : this.config_defaults[k];
      }
      return this.config;
    };

    MooogAudioNode.prototype.zero_node_settings = function(ob) {
      var k, v, zo;
      zo = {};
      for (k in ob) {
        v = ob[k];
        if (!(k in this.config_defaults || k === 'node_type' || k === 'id')) {
          zo[k] = v;
        }
      }
      return zo;
    };

    MooogAudioNode.prototype.zero_node_setup = function(config) {
      var k, ref, results, v;
      if (this._nodes[0] != null) {
        this.expose_properties_of(this._nodes[0]);
      }
      ref = this.zero_node_settings(config);
      results = [];
      for (k in ref) {
        v = ref[k];
        this.debug("zero node settings, " + k + " = " + v);
        results.push(this.param(k, v));
      }
      return results;
    };

    MooogAudioNode.prototype.toString = function() {
      return (this.node_type + "#") + this.id;
    };

    MooogAudioNode.prototype.new_id = function() {
      return this.node_type + "_" + (Math.round(Math.random() * 100000));
    };

    MooogAudioNode.prototype.__typeof = function(thing) {
      if (thing instanceof AudioParam) {
        return "AudioParam";
      }
      if (thing instanceof AudioNode) {
        return "AudioNode";
      }
      if (thing instanceof AudioBuffer) {
        return "AudioBuffer";
      }
      if (thing instanceof PeriodicWave) {
        return "PeriodicWave";
      }
      if (thing instanceof AudioListener) {
        return "AudioListener";
      }
      if (thing instanceof MooogAudioNode) {
        return "MooogAudioNode";
      }
      return typeof thing;
    };

    MooogAudioNode.prototype.insert_node = function(node, ord) {
      var length;
      length = this._nodes.length;
      if (ord == null) {
        ord = length;
      }
      if (node._destination != null) {
        node.disconnect(node._destination);
      }
      if (ord > length) {
        throw new Error("Invalid index given to insert_node: " + ord + " out of " + length);
      }
      this.debug("insert_node of " + this + " for", node, ord);
      if (ord === 0) {
        this.connect_incoming(node);
        this.disconnect_incoming(this._nodes[0]);
        if (length > 0) {
          node.connect(this.to(this._nodes[0]));
          this.debug('- node.connect to ', this._nodes[0]);
        }
      }
      if (ord === length) {
        if (ord !== 0) {
          this.safely_disconnect(this._nodes[ord - 1], this.from(this._destination));
        }
        if (ord !== 0) {
          this.debug("- disconnect ", this._nodes[ord - 1], 'from', this._destination);
        }
        if (this.config.connect_to_destination) {
          node.connect(this.to(this._destination));
          this.debug('- connect', node, 'to', this._destination);
        }
        if (ord !== 0) {
          this._nodes[ord - 1].connect(this.to(node));
        }
        if (ord !== 0) {
          this.debug('- connect', this._nodes[ord - 1], "to", node);
        }
      }
      if (ord !== length && ord !== 0) {
        this.safely_disconnect(this._nodes[ord - 1], this.from(this._nodes[ord]));
        this.debug("- disconnect", this._nodes[ord - 1], "from", this._nodes[ord]);
        this._nodes[ord - 1].connect(this.to(node));
        this.debug("- connect", this._nodes[ord - 1], "to", node);
        node.connect(this.to(this._nodes[ord]));
        this.debug("- connect", node, "to", this._nodes[ord]);
      }
      this._nodes.splice(ord, 0, node);
      return this.debug("- spliced:", this._nodes);
    };

    MooogAudioNode.prototype.delete_node = function(ord) {
      var del, length;
      if (ord == null) {
        return;
      }
      length = this._nodes.length;
      if (ord > (length - 1)) {
        throw new Error("Invalid index given to delete_node: " + ord + " out of " + length);
      }
      this.debug("delete of " + this + " for position", ord);
      if (ord !== 0) {
        this.safely_disconnect(this._nodes[ord - 1], this.from(this._nodes[ord]));
      }
      if (ord < (length - 1)) {
        this.safely_disconnect(this._nodes[ord], this.from(this._nodes[ord + 1]));
      }
      if (ord === (length - 1)) {
        this.safely_disconnect(this._nodes[ord], this.from(this._destination));
      }
      del = this._nodes.splice(ord, 1);
      delete del[0];
      return this.debug("remove node at index " + ord);
    };

    MooogAudioNode.prototype.add = function(nodes) {
      var i, j, len, results;
      if (!(nodes instanceof Array)) {
        nodes = [nodes];
      }
      results = [];
      for (j = 0, len = nodes.length; j < len; j++) {
        i = nodes[j];
        switch (this.__typeof(i)) {
          case "MooogAudioNode":
            results.push(this.insert_node(i));
            break;
          case "object":
            results.push(this.insert_node(this._instance.node(i)));
            break;
          default:
            throw new Error("Unknown argument type (should be config object or MooogAudioNode)");
        }
      }
      return results;
    };

    MooogAudioNode.prototype.connect_incoming = function() {};

    MooogAudioNode.prototype.disconnect_incoming = function() {};

    MooogAudioNode.prototype.connect = function(node, output, input, return_this) {
      var target;
      if (output == null) {
        output = 0;
      }
      if (input == null) {
        input = 0;
      }
      if (return_this == null) {
        return_this = true;
      }
      this.debug("called connect from " + this + " to " + node + ", " + output);
      switch (this.__typeof(node)) {
        case "AudioParam":
          this._nodes[this._nodes.length - 1].connect(node, output);
          return this;
        case "string":
          node = this._instance.node(node);
          target = node._nodes[0];
          break;
        case "MooogAudioNode":
          target = node._nodes[0];
          break;
        case "AudioNode":
          target = node;
          break;
        default:
          throw new Error("Unknown node type passed to connect");
      }
      this._connections.push([node, output, input]);
      switch (false) {
        case typeof output !== 'string':
          this._nodes[this._nodes.length - 1].connect(target[output], input);
          break;
        case typeof output !== 'number':
          this._nodes[this._nodes.length - 1].connect(target, output, input);
      }
      if (return_this) {
        return this;
      } else {
        return node;
      }
    };

    MooogAudioNode.prototype.chain = function(node, output, input) {
      if (output == null) {
        output = 0;
      }
      if (input == null) {
        input = 0;
      }
      if (this.__typeof(node) === "AudioParam" && typeof output !== 'string') {
        throw new Error("MooogAudioNode.chain() can only target AudioParams when used with the signature .chain(target_node:Node, target_param_name:string)");
      }
      this.disconnect(this._destination);
      return this.connect(node, output, input, false);
    };

    MooogAudioNode.prototype.to = function(node) {
      switch (this.__typeof(node)) {
        case "MooogAudioNode":
          return node._nodes[0];
        case "AudioNode":
          return node;
        default:
          throw new Error("Unknown node type passed to connect");
      }
    };

    MooogAudioNode.prototype.from = MooogAudioNode.prototype.to;

    MooogAudioNode.prototype.expose_properties_of = function(node) {
      var key, results, val;
      this.debug("exposing", node);
      results = [];
      for (key in node) {
        val = node[key];
        if ((this[key] != null) && !this._exposed_properties[key]) {
          continue;
        }
        this._exposed_properties[key] = true;
        switch (this.__typeof(val)) {
          case 'function':
            results.push(this[key] = val.bind(node));
            break;
          case 'AudioParam':
            results.push(this[key] = val);
            break;
          case "string":
          case "number":
          case "boolean":
          case "object":
            results.push((function(o, node, key) {
              return Object.defineProperty(o, key, {
                get: function() {
                  return node[key];
                },
                set: function(val) {
                  return node[key] = val;
                },
                enumerable: true,
                configurable: true
              });
            })(this, node, key));
            break;
          default:
            results.push(void 0);
        }
      }
      return results;
    };

    MooogAudioNode.prototype.safely_disconnect = function(node1, node2, output, input) {
      var e, source, target;
      if (output == null) {
        output = 0;
      }
      if (input == null) {
        input = 0;
      }
      switch (this.__typeof(node1)) {
        case "MooogAudioNode":
          source = node1._nodes[node1._nodes.length - 1];
          break;
        case "AudioNode":
        case "AudioParam":
          source = node1;
          break;
        case "string":
          source = this._instance.node(node1);
          break;
        default:
          throw new Error("Unknown node type passed to disconnect");
      }
      switch (this.__typeof(node2)) {
        case "MooogAudioNode":
          target = node2._nodes[0];
          break;
        case "AudioNode":
        case "AudioParam":
          target = node2;
          break;
        case "string":
          target = this._instance.node(node2);
          break;
        default:
          throw new Error("Unknown node type passed to disconnect");
      }
      try {
        source.disconnect(target, output, input);
      } catch (_error) {
        e = _error;
        this.debug("ignored InvalidAccessError disconnecting " + target + " from " + source);
      }
      return this;
    };

    MooogAudioNode.prototype.disconnect = function(node, output, input) {
      if (output == null) {
        output = 0;
      }
      if (input == null) {
        input = 0;
      }
      return this.safely_disconnect(this, node, output, input);
    };

    MooogAudioNode.prototype.param = function(key, val) {
      var at, cancel, duration, extra, from_now, k, rampfun, ref, ref1, ref2, ref3, ref4, timeConstant, v;
      if (this.__typeof(key) === 'object') {
        at = parseFloat(key.at) || 0;
        timeConstant = key.timeConstant != null ? parseFloat(key.timeConstant) : false;
        duration = key.duration ? parseFloat(key.duration) : false;
        cancel = !!key.cancel;
        from_now = !!key.from_now;
        this.debug("keyramp", key.ramp);
        switch (key.ramp) {
          case "linear":
            ref = ["linearRampToValueAtTime", false], rampfun = ref[0], extra = ref[1];
            break;
          case "curve":
            ref1 = ["setValueCurveAtTime", duration], rampfun = ref1[0], extra = ref1[1];
            break;
          case "expo":
            if (timeConstant) {
              ref2 = ["setTargetAtTime", timeConstant], rampfun = ref2[0], extra = ref2[1];
            } else {
              ref3 = ["exponentialRampToValueAtTime", false], rampfun = ref3[0], extra = ref3[1];
            }
            break;
          default:
            ref4 = ["setValueAtTime", false], rampfun = ref4[0], extra = ref4[1];
        }
        for (k in key) {
          v = key[k];
          this.get_set(k, v, rampfun, at, cancel, from_now, extra);
        }
        return this;
      }
      return this.get_set(key, val, 'setValueAtTime', 0, true);
    };

    MooogAudioNode.prototype.get_set = function(key, val, rampfun, at, cancel, from_now, extra) {
      if (!((this[key] != null) || this.hasOwnProperty(key))) {
        return;
      }
      switch (this.__typeof(this[key])) {
        case "AudioParam":
          if (val != null) {
            if (cancel) {
              this[key].cancelScheduledValues(0);
            }
            if (val === 0) {
              val = this._instance.config.fake_zero;
            }
            if (val instanceof Array) {
              val = new Float32Array(val);
            }
            switch (rampfun) {
              case "linearRampToValueAtTime":
              case "exponentialRampToValueAtTime":
                if (from_now) {
                  this[key].setValueAtTime(this[key].value, this.context.currentTime);
                }
                this[key][rampfun](val, this.context.currentTime + at);
                break;
              case "setValueAtTime":
                this[key][rampfun](val, this.context.currentTime + at);
                break;
              case "setValueCurveAtTime":
                this[key][rampfun](val, this.context.currentTime + at, extra);
                break;
              case "setTargetAtTime":
                this[key][rampfun](val, this.context.currentTime + at, extra);
            }
            return this;
          } else {
            return this[key].value;
          }
          break;
        default:
          if (val != null) {
            this[key] = val;
            return this;
          } else {
            return this[key];
          }
      }
    };

    MooogAudioNode.prototype.define_buffer_source_properties = function() {
      this._buffer_source_file_url = '';
      return Object.defineProperty(this, 'buffer_source_file', {
        get: function() {
          return this._buffer_source_file_url;
        },
        set: (function(_this) {
          return function(filename) {
            var request;
            request = new XMLHttpRequest();
            request.open('GET', filename, true);
            request.responseType = 'arraybuffer';
            request.onload = function() {
              _this.debug("loaded " + filename);
              _this._buffer_source_file_url = filename;
              return _this._instance.context.decodeAudioData(request.response, function(buffer) {
                _this.debug("setting buffer", buffer);
                return _this.buffer = buffer;
              }, function(error) {
                throw new Error("Could not decode audio data from " + request.responseURL + " - unsupported file format?");
              });
            };
            return request.send();
          };
        })(this),
        enumerable: true,
        configurable: true
      });
    };

    MooogAudioNode.prototype.define_readonly_property = function(prop_name, func) {
      return Object.defineProperty(this, prop_name, {
        get: func,
        set: function() {
          throw new Error(this + "." + prop_name + " is read-only");
        },
        enumerable: true,
        configurable: false
      });
    };

    MooogAudioNode.prototype.adsr = function(param, config) {
      var _0, a, base, ramp, s, t, times;
      if (typeof param === "string") {
        param = this[param];
      }
      _0 = this._instance.config.fake_zero;
      base = config.base, times = config.times, a = config.a, s = config.s;
      if (base == null) {
        base = _0;
      }
      if (base === 0) {
        base = _0;
      }
      if (a == null) {
        a = 1;
      }
      if (a === 0) {
        a = _0;
      }
      if (s == null) {
        s = 1;
      }
      if (s === 0) {
        s = _0;
      }
      t = this.context.currentTime;
      times[0] || (times[0] = _0);
      times[1] || (times[1] = _0);
      if (times.length > 2) {
        times[2] || (times[2] = _0);
      }
      if (times.length > 3) {
        times[3] || (times[3] = _0);
      }
      if (config.ramp == null) {
        config.ramp = this._instance.config.default_ramp_type;
      }
      switch (config.ramp) {
        case 'linear':
          ramp = param.linearRampToValueAtTime.bind(param);
          break;
        case 'expo':
          ramp = param.exponentialRampToValueAtTime.bind(param);
      }
      if (times.length === 2) {
        param.cancelScheduledValues(t);
        param.setValueAtTime(base, t);
        ramp(a, t + times[0]);
        return ramp(s, t + times[0] + times[1]);
      } else if (times.length === 3) {
        param.cancelScheduledValues(t);
        param.setValueAtTime(base, t);
        ramp(a, t + times[0]);
        param.setValueAtTime(a, t + times[0] + times[1]);
        return ramp(base, t + times[0] + times[1] + times[2]);
      } else {
        param.cancelScheduledValues(t);
        param.setValueAtTime(base, t);
        ramp(a, t + times[0]);
        ramp(s, t + times[0] + times[1]);
        param.setValueAtTime(s, t + times[0] + times[1] + times[2]);
        return ramp(base, t + times[0] + times[1] + times[2] + times[3]);
      }
    };

    MooogAudioNode.prototype.debug = function() {
      var a;
      a = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      if (this._instance.config.debug) {
        return console.log.apply(console, a);
      }
    };

    return MooogAudioNode;

  })();

  Analyser = (function(superClass) {
    extend(Analyser, superClass);

    function Analyser(_instance, config) {
      this._instance = _instance;
      if (config == null) {
        config = {};
      }
      Analyser.__super__.constructor.apply(this, arguments);
    }

    Analyser.prototype.before_config = function(config) {
      return this.insert_node(this.context.createAnalyser(), 0);
    };

    Analyser.prototype.after_config = function(config) {};

    return Analyser;

  })(MooogAudioNode);

  AudioBufferSource = (function(superClass) {
    extend(AudioBufferSource, superClass);

    function AudioBufferSource(_instance, config) {
      this._instance = _instance;
      if (config == null) {
        config = {};
      }
      AudioBufferSource.__super__.constructor.apply(this, arguments);
    }

    AudioBufferSource.prototype.before_config = function(config) {
      this.insert_node(this.context.createBufferSource(), 0);
      return this.define_buffer_source_properties();
    };

    AudioBufferSource.prototype.after_config = function(config) {
      this.insert_node(new Gain(this._instance, {
        gain: 1.0,
        connect_to_destination: this.config.connect_to_destination
      }));
      this._state = 'stopped';
      return this.define_readonly_property('state', (function(_this) {
        return function() {
          return _this._state;
        };
      })(this));
    };

    AudioBufferSource.prototype.start = function() {
      if (this._state === 'playing') {
        return this;
      }
      this._state = 'playing';
      this._nodes[1].param('gain', 1);
      return this._nodes[0].start();
    };

    AudioBufferSource.prototype.stop = function() {
      var new_source;
      if (this._state === 'stopped') {
        return this;
      }
      this._state = 'stopped';
      this._nodes[1].param('gain', 0);
      new_source = this.context.createBufferSource();
      this.clone_AudioNode_properties(this._nodes[0], new_source);
      this.delete_node(0);
      this.insert_node(new_source, 0);
      this.expose_properties_of(this._nodes[0]);
      return this;
    };

    AudioBufferSource.prototype.clone_AudioNode_properties = function(source, dest) {
      var k, results, v;
      results = [];
      for (k in source) {
        v = source[k];
        switch (this.__typeof(source[k])) {
          case 'AudioBuffer':
          case 'boolean':
          case 'number':
          case 'string':
            results.push(dest[k] = v);
            break;
          case 'AudioParam':
            results.push(dest[k].value = v.value);
            break;
          default:
            results.push(void 0);
        }
      }
      return results;
    };

    return AudioBufferSource;

  })(MooogAudioNode);

  BiquadFilter = (function(superClass) {
    extend(BiquadFilter, superClass);

    function BiquadFilter(_instance, config) {
      this._instance = _instance;
      if (config == null) {
        config = {};
      }
      BiquadFilter.__super__.constructor.apply(this, arguments);
    }

    BiquadFilter.prototype.before_config = function(config) {
      return this.insert_node(this.context.createBiquadFilter(), 0);
    };

    BiquadFilter.prototype.after_config = function(config) {};

    return BiquadFilter;

  })(MooogAudioNode);

  ChannelMerger = (function(superClass) {
    extend(ChannelMerger, superClass);

    function ChannelMerger(_instance, config) {
      this._instance = _instance;
      if (config == null) {
        config = {};
      }
      this.__numberOfInputs = config.numberOfInputs != null ? config.numberOfInputs : 6;
      delete config.numberOfInputs;
      ChannelMerger.__super__.constructor.apply(this, arguments);
    }

    ChannelMerger.prototype.before_config = function(config) {
      return this.insert_node(this.context.createChannelMerger(this.__numberOfInputs), 0);
    };

    ChannelMerger.prototype.after_config = function(config) {};

    return ChannelMerger;

  })(MooogAudioNode);

  ChannelSplitter = (function(superClass) {
    extend(ChannelSplitter, superClass);

    function ChannelSplitter(_instance, config) {
      this._instance = _instance;
      if (config == null) {
        config = {};
      }
      this.__numberOfOutputs = config.numberOfOutputs != null ? config.numberOfOutputs : 6;
      delete config.numberOfOutputs;
      ChannelSplitter.__super__.constructor.apply(this, arguments);
    }

    ChannelSplitter.prototype.before_config = function(config) {
      return this.insert_node(this.context.createChannelSplitter(this.__numberOfOutputs), 0);
    };

    ChannelSplitter.prototype.after_config = function(config) {};

    return ChannelSplitter;

  })(MooogAudioNode);

  Convolver = (function(superClass) {
    extend(Convolver, superClass);

    function Convolver(_instance, config) {
      this._instance = _instance;
      if (config == null) {
        config = {};
      }
      Convolver.__super__.constructor.apply(this, arguments);
    }

    Convolver.prototype.before_config = function(config) {
      this.insert_node(this.context.createConvolver(), 0);
      return this.define_buffer_source_properties();
    };

    Convolver.prototype.after_config = function(config) {};

    return Convolver;

  })(MooogAudioNode);

  Delay = (function(superClass) {
    extend(Delay, superClass);

    function Delay(_instance, config) {
      this._instance = _instance;
      if (config == null) {
        config = {};
      }
      Delay.__super__.constructor.apply(this, arguments);
    }

    Delay.prototype.before_config = function(config) {
      this.insert_node(this.context.createDelay(), 0);
      this._feedback_stage = new Gain(this._instance, {
        connect_to_destination: false,
        gain: 0
      });
      this._nodes[0].connect(this.to(this._feedback_stage));
      this._feedback_stage.connect(this.to(this._nodes[0]));
      return this.feedback = this._feedback_stage.gain;
    };

    Delay.prototype.after_config = function(config) {};

    return Delay;

  })(MooogAudioNode);

  DynamicsCompressor = (function(superClass) {
    extend(DynamicsCompressor, superClass);

    function DynamicsCompressor(_instance, config) {
      this._instance = _instance;
      if (config == null) {
        config = {};
      }
      DynamicsCompressor.__super__.constructor.apply(this, arguments);
    }

    DynamicsCompressor.prototype.before_config = function(config) {
      return this.insert_node(this.context.createDynamicsCompressor(), 0);
    };

    DynamicsCompressor.prototype.after_config = function(config) {};

    return DynamicsCompressor;

  })(MooogAudioNode);

  Gain = (function(superClass) {
    extend(Gain, superClass);

    function Gain(_instance, config) {
      this._instance = _instance;
      if (config == null) {
        config = {};
      }
      Gain.__super__.constructor.apply(this, arguments);
    }

    Gain.prototype.before_config = function(config) {
      this.insert_node(this.context.createGain(), 0);
      return this._nodes[0].gain.value = this._instance.config.default_gain;
    };

    Gain.prototype.after_config = function(config) {};

    return Gain;

  })(MooogAudioNode);

  MediaElementSource = (function(superClass) {
    extend(MediaElementSource, superClass);

    function MediaElementSource(_instance, config) {
      this._instance = _instance;
      if (config == null) {
        config = {};
      }
      MediaElementSource.__super__.constructor.apply(this, arguments);
    }

    MediaElementSource.prototype.before_config = function(config) {
      if (!config.mediaElement) {
        throw new Error("MediaElementSource requires mediaElement config argument");
      }
      if (typeof config.mediaElement === 'string') {
        config.mediaElement = document.querySelector(config.mediaElement);
      }
      return this.insert_node(this.context.createMediaElementSource(config.mediaElement), 0);
    };

    MediaElementSource.prototype.after_config = function(config) {};

    return MediaElementSource;

  })(MooogAudioNode);

  Oscillator = (function(superClass) {
    extend(Oscillator, superClass);

    function Oscillator(_instance, config) {
      this._instance = _instance;
      if (config == null) {
        config = {};
      }
      this.__start = bind(this.__start, this);
      this.__stop = bind(this.__stop, this);
      Oscillator.__super__.constructor.apply(this, arguments);
    }

    Oscillator.prototype.before_config = function(config) {
      return this.insert_node(this.context.createOscillator(), 0);
    };

    Oscillator.prototype.after_config = function(config) {
      this.insert_node(new Gain(this._instance, {
        connect_to_destination: this.config.connect_to_destination
      }));
      this._is_started = false;
      this._state = 'stopped';
      this._timeout = false;
      return this.define_readonly_property('state', (function(_this) {
        return function() {
          return _this._state;
        };
      })(this));
    };

    Oscillator.prototype.start = function(time) {
      if (time == null) {
        time = 0;
      }
      clearTimeout(this._timeout);
      if (this._state === 'playing') {
        return this;
      }
      if (time === 0) {
        this.__start(time);
      } else {
        this._timeout = setTimeout(this.__start, time * 1000);
      }
      return this;
    };

    Oscillator.prototype.stop = function(time) {
      if (time == null) {
        time = 0;
      }
      clearTimeout(this._timeout);
      if (this._state === 'stopped') {
        return this;
      }
      if (time === 0) {
        this.__stop();
      } else {
        this._timeout = setTimeout(this.__stop, time * 1000);
      }
      return this;
    };

    Oscillator.prototype.__stop = function() {
      this._state = 'stopped';
      this._nodes[1].gain.value = 0;
      return this;
    };

    Oscillator.prototype.__start = function() {
      this._state = 'playing';
      if (this._is_started) {
        this._nodes[1].gain.value = 1.0;
      } else {
        this._nodes[0].start(0);
        this._is_started = true;
      }
      return this;
    };

    return Oscillator;

  })(MooogAudioNode);

  Panner = (function(superClass) {
    extend(Panner, superClass);

    function Panner(_instance, config) {
      this._instance = _instance;
      if (config == null) {
        config = {};
      }
      Panner.__super__.constructor.apply(this, arguments);
    }

    Panner.prototype.before_config = function(config) {
      return this.insert_node(this.context.createPanner(), 0);
    };

    Panner.prototype.after_config = function(config) {};

    return Panner;

  })(MooogAudioNode);

  ScriptProcessor = (function(superClass) {
    extend(ScriptProcessor, superClass);

    function ScriptProcessor(_instance, config) {
      this._instance = _instance;
      if (config == null) {
        config = {};
      }
      this.__bufferSize = config.bufferSize != null ? config.bufferSize : null;
      this.__numberOfInputChannels = config.numberOfInputChannels != null ? config.numberOfInputChannels : 2;
      this.__numberOfOuputChannels = config.numberOfOuputChannels != null ? config.numberOfOuputChannels : 2;
      delete config.bufferSize;
      delete config.numberOfInputChannels;
      delete config.numberOfOuputChannels;
      this.debug("ScriptProcessorNode is deprecated and will be replaced by AudioWorker");
      ScriptProcessor.__super__.constructor.apply(this, arguments);
    }

    ScriptProcessor.prototype.before_config = function(config) {
      return this.insert_node(this.context.createScriptProcessor(this.__bufferSize, this.__numberOfInputChannels, this.__numberOfOuputChannels), 0);
    };

    ScriptProcessor.prototype.after_config = function(config) {};

    return ScriptProcessor;

  })(MooogAudioNode);

  StereoPanner = (function(superClass) {
    extend(StereoPanner, superClass);

    function StereoPanner(_instance, config) {
      this._instance = _instance;
      if (config == null) {
        config = {};
      }
      StereoPanner.__super__.constructor.apply(this, arguments);
    }

    StereoPanner.prototype.before_config = function(config) {
      return this.insert_node(this.context.createStereoPanner(), 0);
    };

    StereoPanner.prototype.after_config = function(config) {};

    return StereoPanner;

  })(MooogAudioNode);

  Track = (function(superClass) {
    extend(Track, superClass);

    function Track(_instance, config) {
      this._instance = _instance;
      if (config == null) {
        config = {};
      }
      this._sends = {};
      this.debug('initializing track object');
      config.node_type = 'Track';
      Track.__super__.constructor.apply(this, arguments);
    }

    Track.prototype.before_config = function(config) {
      this._pan_stage = this._instance.context.createStereoPanner();
      this._gain_stage = this._instance.context.createGain();
      this._gain_stage.gain.value = this._instance.config.default_gain;
      this._pan_stage.connect(this._gain_stage);
      this._gain_stage.connect(this._destination);
      this._destination = this._pan_stage;
      this.gain = this._gain_stage.gain;
      return this.pan = this._pan_stage.pan;
    };

    Track.prototype.after_config = function(config) {};

    Track.prototype.send = function(id, dest, pre, gain) {
      var new_send, source;
      if (pre == null) {
        pre = this._instance.config.default_send_type;
      }
      if (gain == null) {
        gain = this._instance.config.default_gain;
      }
      if (dest == null) {
        return this._sends[id];
      }
      source = pre === 'pre' ? this._nodes[this._nodes.length - 1] : this._gain_stage;
      if (this._sends[id] != null) {
        return this._sends[id];
      }
      this._sends[id] = new_send = new Gain(this._instance, {
        connect_to_destination: false,
        gain: gain
      });
      source.connect(this.to(new_send));
      new_send.connect(this.to(dest));
      return new_send;
    };

    return Track;

  })(MooogAudioNode);

  WaveShaper = (function(superClass) {
    extend(WaveShaper, superClass);

    function WaveShaper(_instance, config) {
      this._instance = _instance;
      if (config == null) {
        config = {};
      }
      WaveShaper.__super__.constructor.apply(this, arguments);
    }

    WaveShaper.prototype.before_config = function(config) {
      return this.insert_node(this.context.createWaveShaper(), 0);
    };

    WaveShaper.prototype.after_config = function(config) {};

    WaveShaper.prototype.chebyshev = function(terms, last, current) {
      var el, i, lasttemp, newcurrent;
      if (last == null) {
        last = [1];
      }
      if (current == null) {
        current = [1, 0];
      }
      if (terms < 2) {
        throw new Error("Terms must be 2 or more for chebyshev generator");
      }
      if (current.length === terms) {
        return this.poly.apply(this, current);
      } else {
        lasttemp = last;
        last = current;
        current = current.map(function(x) {
          return 2 * x;
        });
        current.push(0);
        lasttemp.unshift(0, 0);
        lasttemp = lasttemp.map(function(x) {
          return -1 * x;
        });
        newcurrent = (function() {
          var j, len, results;
          results = [];
          for (i = j = 0, len = current.length; j < len; i = ++j) {
            el = current[i];
            results.push(lasttemp[i] + current[i]);
          }
          return results;
        })();
        console.log(current, lasttemp, "new cur", newcurrent, this);
        return this.chebyshev(terms, last, newcurrent);
      }
    };

    WaveShaper.prototype.poly = function() {
      var coeffs, curve, i, j, length, p, ref, step;
      coeffs = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      length = this._instance.config.curve_length;
      step = 2 / (length - 1);
      curve = new Float32Array(length);
      p = function(x, coeffs) {
        var a, accum, i, j, ref;
        accum = 0;
        for (i = j = 0, ref = coeffs.length - 1; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
          a = coeffs[i];
          accum += a * Math.pow(x, coeffs.length - i - 1);
        }
        return accum;
      };
      for (i = j = 0, ref = length - 1; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
        curve[i] = p((i * step) - 1, coeffs);
      }
      return curve;
    };

    WaveShaper.prototype.tanh = function(n) {
      var curve, i, j, length, ref, step;
      length = this._instance.config.curve_length;
      step = 2 / (length - 1);
      curve = new Float32Array(length);
      for (i = j = 0, ref = length - 1; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
        curve[i] = Math.tanh((Math.PI / 2) * n * ((i * step) - 1));
      }
      return curve;
    };

    return WaveShaper;

  })(MooogAudioNode);

  Mooog = (function() {
    Mooog.LEGAL_NODES = {
      'Analyser': Analyser,
      'AudioBufferSource': AudioBufferSource,
      'BiquadFilter': BiquadFilter,
      'ChannelMerger': ChannelMerger,
      'ChannelSplitter': ChannelSplitter,
      'Convolver': Convolver,
      'Delay': Delay,
      'DynamicsCompressor': DynamicsCompressor,
      'Gain': Gain,
      'MediaElementSource': MediaElementSource,
      'Oscillator': Oscillator,
      'Panner': Panner,
      'ScriptProcessor': ScriptProcessor,
      'StereoPanner': StereoPanner,
      'WaveShaper': WaveShaper
    };

    Mooog.MooogAudioNode = MooogAudioNode;

    function Mooog(initConfig1) {
      this.initConfig = initConfig1 != null ? initConfig1 : {};
      this.config = {
        debug: false,
        default_gain: 0.5,
        default_ramp_type: 'expo',
        default_send_type: 'post',
        periodic_wave_length: 2048,
        curve_length: 65536,
        fake_zero: 1 / 65536,
        allow_multiple_audiocontexts: false
      };
      this._BROWSER_CONSTRUCTOR = false;
      this.context = this.create_context();
      this._destination = this.context.destination;
      this.init(this.initConfig);
      Mooog.browser_test();
      this.iOS_setup();
      this._nodes = {};
      this.__typeof = MooogAudioNode.prototype.__typeof;
      if (!Mooog.browser_test().all) {
        console.log("AudioContext not fully supported in this browser. Run Mooog.browser_test() for more info");
      }
    }

    Mooog.prototype.iOS_setup = function() {
      var body, instantProcess, is_iOS, tmpBuf, tmpProc;
      is_iOS = navigator.userAgent.indexOf('like Mac OS X') !== -1;
      if (is_iOS) {
        body = document.body;
        tmpBuf = this.context.createBufferSource();
        tmpProc = this.context.createScriptProcessor(256, 1, 1);
        instantProcess = function() {
          tmpBuf.start(0);
          tmpBuf.connect(tmpProc);
          return tmpProc.connect(this.context.destination);
        };
        body.addEventListener('touchstart', instantProcess, false);
        return tmpProc.onaudioprocess = function() {
          tmpBuf.disconnect();
          tmpProc.disconnect();
          body.removeEventListener('touchstart', instantProcess, false);
          return tmpProc.onaudioprocess = null;
        };
      }
    };

    Mooog.prototype.init = function(initConfig) {
      var key, ref, val;
      ref = this.config;
      for (key in ref) {
        val = ref[key];
        if (initConfig[key] != null) {
          this.config[key] = initConfig[key];
        }
      }
      return null;
    };

    Mooog.context = false;

    Mooog.prototype.create_context = function() {
      this._BROWSER_CONSTRUCTOR = (function() {
        switch (false) {
          case window.AudioContext == null:
            return 'AudioContext';
          case window.webkitAudioContext == null:
            return 'webkitAudioContext';
          default:
            throw new Error("This browser does not yet support the AudioContext API");
        }
      })();
      if (this.config.allow_multiple_audiocontexts) {
        return new window[this._BROWSER_CONSTRUCTOR];
      }
      return Mooog.context || (Mooog.context = new window[this._BROWSER_CONSTRUCTOR]);
    };

    Mooog.prototype.track = function() {
      var id, node_list, ref;
      id = arguments[0], node_list = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      if (!arguments.length) {
        return new Track(this);
      }
      if (typeof id === 'string') {
        if (node_list.length) {
          if (this._nodes[id] != null) {
            throw new Error(id + " is already assigned to " + this._nodes[id]);
          }
          this._nodes[id] = new Track(this, {
            id: id
          });
          this._nodes[id].add(node_list);
          return this._nodes[id];
        } else if (((ref = this._nodes) != null ? ref[id] : void 0) != null) {
          return this._nodes[id];
        } else {
          throw new Error("No Track found with id " + id);
        }
      } else {
        throw new Error("Track id must be a string");
      }
    };

    Mooog.prototype.node = function() {
      var arg0, arg1, i, j, len, new_node, results, type0, type1;
      arg0 = arguments[0];
      arg1 = arguments[1];
      type0 = this.__typeof(arg0);
      type1 = this.__typeof(arg1);
      if (type0 === "string" && type1 === "string") {
        if (Mooog.LEGAL_NODES[arg1] != null) {
          if (this._nodes[arg0]) {
            throw new Error(arg0 + " is already assigned to " + this._nodes[arg0]);
          }
          return this._nodes[arg0] = new Mooog.LEGAL_NODES[arg1](this, {
            id: arg0,
            node_type: arg1
          });
        } else {
          console.log(arguments);
          throw new Error("Unknown node type " + arg1);
        }
      } else if (type0 === "string" && type1 === "undefined") {
        if (this._nodes[arg0]) {
          return this._nodes[arg0];
        } else {
          throw new Error("No MooogAudioNode found with id " + arg0);
        }
      } else if (type0 === "object" && type1 === "undefined") {
        if (this._nodes[arg0.id]) {
          throw new Error(arg0.id + " is already assigned to " + this._nodes[arg0.id]);
        } else if (Mooog.LEGAL_NODES[arg0.node_type] != null) {
          new_node = new Mooog.LEGAL_NODES[arg0.node_type](this, arg0);
          return this._nodes[new_node.id] = new_node;
        } else {
          throw new Error("Omitted or undefined node type in config options.");
        }
      } else if (type0 === "object" && type1 === "object") {
        throw new Error("A string id for the base node must be provided if you give more than one node definition");
      } else if (type0 === "string" && type1 === "object") {
        new_node = new MooogAudioNode(this, {
          id: arg0
        });
        this._nodes[new_node.id] = new_node;
        results = [];
        for (j = 0, len = arguments.length; j < len; j++) {
          i = arguments[j];
          results.push(new_node.add(new MooogAudioNode(this, i)));
        }
        return results;
      }
    };

    Mooog.extend_with = function(nodeName, nodeDef) {
      window.nodeDef = nodeDef;
      if (nodeDef.prototype.before_config == null) {
        throw new Error("Node definition prototype must have a before_config function");
      }
      if (nodeDef.prototype.after_config == null) {
        throw new Error("Node definition prototype must have a before_config function");
      }
      if (Mooog.LEGAL_NODES[nodeName] != null) {
        throw new Error(nodeName + " class already defined");
      }
      Mooog.LEGAL_NODES[nodeName] = nodeDef;
      return null;
    };

    Mooog.freq = function(n) {
      return 440 * Math.pow(2, (n - 69) / 12);
    };

    Mooog.prototype.sawtoothPeriodicWave = function(harms) {
      var a, i, imag, j, real, ref;
      if (harms == null) {
        harms = this.config.periodic_wave_length;
      }
      a = [0];
      for (i = j = 1, ref = harms - 1; 1 <= ref ? j <= ref : j >= ref; i = 1 <= ref ? ++j : --j) {
        a.push(1 / i);
      }
      real = new Float32Array(a);
      imag = new Float32Array(real.length);
      return this.context.createPeriodicWave(real, imag);
    };

    Mooog.prototype.squarePeriodicWave = function(harms) {
      var a, i, imag, j, real, ref;
      if (harms == null) {
        harms = this.config.periodic_wave_length;
      }
      a = [0];
      for (i = j = 1, ref = harms - 1; 1 <= ref ? j <= ref : j >= ref; i = 1 <= ref ? ++j : --j) {
        if (i % 2 !== 0) {
          a.push(2 / (Math.PI * i));
        } else {
          a.push(0);
        }
      }
      real = new Float32Array(a);
      imag = new Float32Array(real.length);
      return this.context.createPeriodicWave(real, imag);
    };

    Mooog.prototype.trianglePeriodicWave = function(harms) {
      var a, i, imag, j, real, ref;
      if (harms == null) {
        harms = this.config.periodic_wave_length;
      }
      a = [0];
      for (i = j = 1, ref = harms - 1; 1 <= ref ? j <= ref : j >= ref; i = 1 <= ref ? ++j : --j) {
        if (i % 2 !== 0) {
          a.push(1 / (Math.pow(i, 2)));
        } else {
          a.push(0);
        }
      }
      real = new Float32Array(a);
      imag = new Float32Array(real.length);
      return this.context.createPeriodicWave(real, imag);
    };

    Mooog.prototype.sinePeriodicWave = function(harms) {
      var a, imag, real;
      a = [0, 1];
      real = new Float32Array(a);
      imag = new Float32Array(real.length);
      return this.context.createPeriodicWave(real, imag);
    };

    Mooog.brower_test_results = false;

    Mooog.browser_test = function() {
      var __t, ctxt, tests;
      if (this.browser_test_results) {
        return this.browser_test_results;
      }
      ctxt = window.AudioContext || window.webkitAudioContext;
      __t = new ctxt();
      tests = {
        all: true
      };
      tests.all = (tests.unprefixed = window.AudioContext != null) ? tests.all : false;
      tests.all = (tests.start_stop = __t.createOscillator().start != null) ? tests.all : false;
      if (!(__t.createStereoPanner != null)) {
        tests.stereo_panner = 'patched';
        this.patch_StereoPanner();
      }
      tests.all = (tests.script_processor = __t.createScriptProcessor != null) ? tests.all : false;
      return this.browser_test_results = tests;
    };

    Mooog.patch_StereoPanner = function() {
      var StereoPannerImpl, WS_CURVE_SIZE, ctxt, curveL, curveR, i, j, ref;
      WS_CURVE_SIZE = 4096;
      curveL = new Float32Array(WS_CURVE_SIZE);
      curveR = new Float32Array(WS_CURVE_SIZE);
      for (i = j = 0, ref = WS_CURVE_SIZE; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
        curveL[i] = Math.cos((i / WS_CURVE_SIZE) * Math.PI * 0.5);
        curveR[i] = Math.sin((i / WS_CURVE_SIZE) * Math.PI * 0.5);
      }

      /*
          
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
       */
      StereoPannerImpl = (function() {
        function StereoPannerImpl(audioContext) {
          this.audioContext = audioContext;
          this.inlet = audioContext.createChannelSplitter(2);
          this._pan = audioContext.createGain();
          this.pan = this._pan.gain;
          this._wsL = audioContext.createWaveShaper();
          this._wsR = audioContext.createWaveShaper();
          this._L = audioContext.createGain();
          this._R = audioContext.createGain();
          this.outlet = audioContext.createChannelMerger(2);
          this.inlet.channelCount = 2;
          this.inlet.channelCountMode = "explicit";
          this._pan.gain.value = 0;
          this._wsL.curve = curveL;
          this._wsR.curve = curveR;
          this._L.gain.value = 0;
          this._R.gain.value = 0;
          this.inlet.connect(this._L, 0);
          this.inlet.connect(this._R, 1);
          this._L.connect(this.outlet, 0, 0);
          this._R.connect(this.outlet, 0, 1);
          this._pan.connect(this._wsL);
          this._pan.connect(this._wsR);
          this._wsL.connect(this._L.gain);
          this._wsR.connect(this._R.gain);
          this._isConnected = false;
          this._dc1buffer = null;
          this._dc1 = null;
        }

        StereoPannerImpl.prototype.connect = function(destination) {
          var audioContext;
          audioContext = this.audioContext;
          if (!this._isConnected) {
            this._isConnected = true;
            this._dc1buffer = audioContext.createBuffer(1, 2, audioContext.sampleRate);
            this._dc1buffer.getChannelData(0).set([1, 1]);
            this._dc1 = audioContext.createBufferSource();
            this._dc1.buffer = this._dc1buffer;
            this._dc1.loop = true;
            this._dc1.start(audioContext.currentTime);
            this._dc1.connect(this._pan);
          }
          return AudioNode.prototype.connect.call(this.outlet, destination);
        };

        StereoPannerImpl.prototype.disconnect = function() {
          this.audioContext;
          if (this._isConnected) {
            this._isConnected = false;
            this._dc1.stop(audioContext.currentTime);
            this._dc1.disconnect();
            this._dc1 = null;
            this._dc1buffer = null;
          }
          return AudioNode.prototype.disconnect.call(this.outlet);
        };

        return StereoPannerImpl;

      })();
      StereoPanner = (function() {
        function StereoPanner(audioContext) {
          var impl;
          impl = new StereoPannerImpl(audioContext);
          Object.defineProperties(impl.inlet, {
            pan: {
              value: impl.pan,
              enumerable: true
            },
            connect: {
              value: function(node) {
                return impl.connect(node);
              }
            },
            disconnect: {
              value: function() {
                return impl.disconnect();
              }
            }
          });
          return impl.inlet;
        }

        return StereoPanner;

      })();
      ctxt = window.AudioContext || window.webkitAudioContext;
      if (!ctxt || ctxt.prototype.hasOwnProperty("createStereoPanner")) {

      } else {
        return ctxt.prototype.createStereoPanner = function() {
          return new StereoPanner(this);
        };
      }
    };

    return Mooog;

  })();

  window.Mooog = Mooog;

}).call(this);
