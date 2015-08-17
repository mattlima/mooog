(function() {
  var AudioBufferSource, Convolver, Gain, Mooog, Node, Oscillator, StereoPanner,
    slice = [].slice,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Node = (function() {
    function Node() {
      var _instance, i, j, len, node_list;
      _instance = arguments[0], node_list = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      this._instance = _instance;
      this._destination = this._instance._destination;
      this.context = this._instance.context;
      this._nodes = [];
      this.config_defaults = {
        connect_to_destination: true
      };
      this.config = {};
      if (this.__typeof(node_list[0]) === "string" && this.__typeof(node_list[1]) === "string" && (Mooog.LEGAL_NODES[node_list[1]] != null)) {
        return new Mooog.LEGAL_NODES[node_list[1]](this._instance, {
          id: node_list[0]
        });
      }
      if (node_list.length === 1) {
        if (this.constructor.name !== "Node") {
          return;
        }
        if (Mooog.LEGAL_NODES[node_list[0].node_type] != null) {
          return new Mooog.LEGAL_NODES[node_list[0].node_type](this._instance, node_list[0]);
        } else {
          throw new Error("Omitted or undefined node type in config options.");
        }
      } else {
        for (j = 0, len = node_list.length; j < len; j++) {
          i = node_list[j];
          if (Mooog.LEGAL_NODES[node_list[i].node_type != null]) {
            this._nodes.push(new Mooog.LEGAL_NODES[node_list[i].node_type](this._instance, node_list[i]));
          } else {
            throw new Error("Omitted or undefined node type in config options.");
          }
        }
      }
    }

    Node.prototype.configure_from = function(ob) {
      var k, ref, v;
      this.id = ob.id != null ? ob.id : this.new_id();
      ref = this.config_defaults;
      for (k in ref) {
        v = ref[k];
        this.config[k] = k in ob ? ob[k] : this.config_defaults[k];
      }
      return this.config;
    };

    Node.prototype.zero_node_settings = function(ob) {
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

    Node.prototype.zero_node_setup = function(config) {
      var k, ref, results, v;
      this.expose_methods_of(this._nodes[0]);
      ref = this.zero_node_settings(config);
      results = [];
      for (k in ref) {
        v = ref[k];
        results.push(this.param(k, v));
      }
      return results;
    };

    Node.prototype.toString = function() {
      return (this.constructor.name + "#") + this.id;
    };

    Node.prototype.new_id = function() {
      return this.constructor.name + "_" + (Math.round(Math.random() * 100000));
    };

    Node.prototype.__typeof = function(thing) {
      if (thing instanceof AudioParam) {
        return "AudioParam";
      }
      if (thing instanceof AudioNode) {
        return "AudioNode";
      }
      if (thing instanceof AudioBuffer) {
        return "AudioBuffer";
      }
      if (thing instanceof Node) {
        return "Node";
      }
      switch (typeof thing) {
        case "string":
          return "string";
        case "number":
          return "number";
        case "function":
          return "function";
        case "object":
          return "object";
        case "boolean":
          return "boolean";
        case "undefined":
          return "undefined";
        default:
          throw new Error("__typeof does not pass for " + typeof thing);
      }
    };

    Node.prototype.insert_node = function(node, ord) {
      var length;
      length = this._nodes.length;
      if (ord == null) {
        ord = length;
      }
      if (ord > length) {
        throw new Error("Invalid index given to insert_node: " + ord + " out of " + length);
      }
      this.debug("insert_node of " + this + " for", node, ord);
      if (ord === 0) {
        this.connect_incoming(node);
        this.disconnect_incoming(this._nodes[0]);
        if (length > 1) {
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

    Node.prototype.add = function(node) {
      return this.insert_node(node);
    };

    Node.prototype.connect_incoming = function() {};

    Node.prototype.disconnect_incoming = function() {};

    Node.prototype.connect = function(node, output, input, return_this) {
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
        case "Node":
          target = node._nodes[0];
          break;
        case "AudioNode":
          target = node;
          break;
        default:
          throw new Error("Unknown node type passed to connect");
      }
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

    Node.prototype.chain = function(node, output, input) {
      if (output == null) {
        output = 0;
      }
      if (input == null) {
        input = 0;
      }
      this.debug(node, this.__typeof(node), typeof output);
      if (this.__typeof(node) === "AudioParam" && typeof output !== 'string') {
        throw new Error("Node.chain() can only target AudioParams when used with the signature .chain(target_node:Node, target_param_name:string)");
      }
      return this.connect(node, output, input, false);
    };

    Node.prototype.to = function(node) {
      switch (this.__typeof(node)) {
        case "Node":
          return node._nodes[0];
        case "AudioNode":
          return node;
        default:
          throw new Error("Unknown node type passed to connect");
      }
    };

    Node.prototype.from = Node.prototype.to;

    Node.prototype.expose_methods_of = function(node) {
      var key, results, val;
      this.debug("exposing", node);
      results = [];
      for (key in node) {
        val = node[key];
        if (this[key] != null) {
          continue;
        }
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

    Node.prototype.safely_disconnect = function(node1, node2, output, input) {
      var e, source, target;
      if (output == null) {
        output = 0;
      }
      if (input == null) {
        input = 0;
      }
      switch (this.__typeof(node1)) {
        case "Node":
          source = node1._nodes[node1._nodes.length - 1];
          break;
        case "AudioNode":
        case "AudioParam":
          source = node1;
          break;
        default:
          throw new Error("Unknown node type passed to connect");
      }
      switch (this.__typeof(node2)) {
        case "Node":
          target = node2._nodes[0];
          break;
        case "AudioNode":
        case "AudioParam":
          target = node2;
          break;
        default:
          throw new Error("Unknown node type passed to connect");
      }
      try {
        source.disconnect(target, output, input);
      } catch (_error) {
        e = _error;
        this.debug("ignored InvalidAccessError disconnecting " + target + " from " + source);
      }
      return this;
    };

    Node.prototype.disconnect = function(node, output, input) {
      if (output == null) {
        output = 0;
      }
      if (input == null) {
        input = 0;
      }
      return this.safely_disconnect(this, node, output, input);
    };

    Node.prototype.param = function(key, val) {
      var k, v;
      if (this.__typeof(key) === 'object') {
        for (k in key) {
          v = key[k];
          this.get_set(k, v);
        }
        return this;
      }
      this.get_set(key, val);
      return this;
    };

    Node.prototype.get_set = function(key, val) {
      if (this[key] == null) {
        return;
      }
      switch (this.__typeof(this[key])) {
        case "AudioParam":
          if (val != null) {
            this[key].value = val;
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

    Node.prototype.define_buffer_source_properties = function() {
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

    Node.prototype.debug = function() {
      var a;
      a = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      if (this._instance.config.debug) {
        return console.log.apply(console, a);
      }
    };

    return Node;

  })();

  AudioBufferSource = (function(superClass) {
    extend(AudioBufferSource, superClass);

    function AudioBufferSource(_instance, config) {
      this._instance = _instance;
      if (config == null) {
        config = {};
      }
      config.node_type = 'AudioBufferSource';
      AudioBufferSource.__super__.constructor.apply(this, arguments);
      this.configure_from(config);
      this.insert_node(this.context.createBufferSource(), 0);
      this.define_buffer_source_properties();
      this.zero_node_setup(config);
    }

    return AudioBufferSource;

  })(Node);

  Convolver = (function(superClass) {
    extend(Convolver, superClass);

    function Convolver(_instance, config) {
      this._instance = _instance;
      if (config == null) {
        config = {};
      }
      config.node_type = 'Convolver';
      Convolver.__super__.constructor.apply(this, arguments);
      this.configure_from(config);
      this.insert_node(this.context.createConvolver(), 0);
      this.define_buffer_source_properties();
      this.zero_node_setup(config);
    }

    return Convolver;

  })(Node);

  Gain = (function(superClass) {
    extend(Gain, superClass);

    function Gain(_instance, config) {
      this._instance = _instance;
      if (config == null) {
        config = {};
      }
      config.node_type = 'Gain';
      Gain.__super__.constructor.apply(this, arguments);
      this.configure_from(config);
      this.insert_node(this.context.createGain(), 0);
      this._nodes[0].gain.value = this._instance.config.default_gain;
      this.zero_node_setup(config);
    }

    return Gain;

  })(Node);

  Oscillator = (function(superClass) {
    extend(Oscillator, superClass);

    function Oscillator(_instance, config) {
      this._instance = _instance;
      if (config == null) {
        config = {};
      }
      config.node_type = 'Oscillator';
      Oscillator.__super__.constructor.apply(this, arguments);
      this.configure_from(config);
      this.insert_node(this.context.createOscillator(), 0);
      this.zero_node_setup(config);
      this.insert_node(new Gain(this._instance, {
        connect_to_destination: this.config.connect_to_destination
      }));
      this._is_started = false;
    }

    Oscillator.prototype.start = function() {
      if (this._is_started) {
        this._nodes[1].gain.value = 1.0;
      } else {
        this._nodes[0].start();
        this._is_started = true;
      }
      return this;
    };

    Oscillator.prototype.stop = function() {
      this._nodes[1].gain.value = 0;
      return this;
    };

    return Oscillator;

  })(Node);

  StereoPanner = (function(superClass) {
    extend(StereoPanner, superClass);

    function StereoPanner(_instance, config) {
      this._instance = _instance;
      if (config == null) {
        config = {};
      }
      config.node_type = 'StereoPanner';
      StereoPanner.__super__.constructor.apply(this, arguments);
      this.configure_from(config);
      this.insert_node(this.context.createStereoPanner(), 0);
      this.zero_node_setup(config);
    }

    return StereoPanner;

  })(Node);

  Mooog = (function() {
    Mooog.LEGAL_NODES = {
      'Oscillator': Oscillator,
      'StereoPanner': StereoPanner,
      'Gain': Gain,
      'AudioBufferSource': AudioBufferSource,
      'Convolver': Convolver
    };

    function Mooog(initConfig1) {
      this.initConfig = initConfig1 != null ? initConfig1 : {};
      this._BROWSER_CONSTRUCTOR = false;
      this.context = this.create_context();
      this._destination = this.context.destination;
      this.config = {
        debug: false,
        default_gain: 0.5
      };
      this.init(this.initConfig);
      this._nodes = {};
    }

    Mooog.prototype.init = function(initConfig) {
      var key, ref, results, val;
      ref = this.config;
      results = [];
      for (key in ref) {
        val = ref[key];
        if (initConfig[key] != null) {
          results.push(this.config[key] = initConfig[key]);
        } else {
          results.push(void 0);
        }
      }
      return results;
    };

    Mooog.prototype.create_context = function() {
      if ((window.AudioContext != null)) {
        this._BROWSER_CONSTRUCTOR = 'AudioContext';
        return new AudioContext();
      }
      if ((window.webkitAudioContext != null)) {
        this._BROWSER_CONSTRUCTOR = 'webkitAudioContext';
        return new webkitAudioContext();
      }
      throw new Error("This browser does not yet support the AudioContext API");
    };

    Mooog.prototype.node = function() {
      var id, node, node_list, ref, ref1;
      id = arguments[0], node_list = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      if (!arguments.length) {
        return new Node(this);
      }
      if (typeof id === 'string') {
        if (node_list.length) {
          return this._nodes[id] = (function(func, args, ctor) {
            ctor.prototype = func.prototype;
            var child = new ctor, result = func.apply(child, args);
            return Object(result) === result ? result : child;
          })(Node, [this, id].concat(slice.call(node_list)), function(){});
        } else if (((ref = this._nodes) != null ? ref[id] : void 0) != null) {
          return this._nodes[id];
        } else {
          throw new Error("No node found with id " + id);
        }
      } else {
        node = (function(func, args, ctor) {
          ctor.prototype = func.prototype;
          var child = new ctor, result = func.apply(child, args);
          return Object(result) === result ? result : child;
        })(Node, [this].concat(slice.call((ref1 = [id]).concat.apply(ref1, node_list))), function(){});
        return this._nodes[node.id] = node;
      }
    };

    return Mooog;

  })();

  window.Mooog = Mooog;

}).call(this);
