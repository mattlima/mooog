(function() {
  var Gain, Mooog, Node, Oscillator, StereoPanner,
    slice = [].slice,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Node = (function() {
    function Node() {
      var _instance, i, j, k, len, len1, node_list, t, todo;
      _instance = arguments[0], node_list = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      this._instance = _instance;
      this._destination = this._instance._destination;
      this.context = this._instance.context;
      this._incoming = [];
      this._outgoing = [];
      this._nodes = [];
      if (!(node_list instanceof Array)) {
        node_list = [node_list];
      }
      if (node_list.length === 1) {
        for (j = 0, len = node_list.length; j < len; j++) {
          i = node_list[j];
          t = this.__typeof(i);
          if (t === "AudioNode") {
            this._nodes.push(i);
          }
          if (t === "string") {
            return new Mooog.LEGAL_NODES[i](this._instance);
          }
          if (t === "Node") {
            return i;
          }
        }
      } else {
        for (k = 0, len1 = node_list.length; k < len1; k++) {
          i = node_list[k];
          t = this.__typeof(i);
          if (t === "AudioNode") {
            todo = i.constructor.name.replace(/Node/, '');
            this._nodes.push(new Mooog.LEGAL_NODES[todo](this._instance));
          }
          if (t === "string") {
            this._insert_node(new Mooog.LEGAL_NODES[i](this._instance), 0);
          }
          if (t === "Node") {
            this._nodes.push(i);
          }
        }
      }
    }

    Node.prototype.__typeof = function(thing) {
      if (thing instanceof AudioParam) {
        return "AudioParam";
      }
      if (thing instanceof AudioNode) {
        return "AudioNode";
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
      console.log('called insert on', node, ord);
      if (ord === 0) {
        this.connect_incoming(node);
        this.disconnect_incoming(this._nodes[0]);
        if (length > 1) {
          node.connect(this.to(this._nodes[0]));
          console.log('node.connect to ', this._nodes[0]);
        }
      }
      if (ord === length) {
        if (ord !== 0) {
          this._nodes[ord - 1].disconnect(this.from(this._destination));
        }
        if (ord !== 0) {
          console.log(this._nodes[ord - 1], 'disconnect', this._destination);
        }
        node.connect(this.to(this._destination));
        console.log(node, 'connect', this._destination);
        if (ord !== 0) {
          this._nodes[ord - 1].connect(this.to(node));
        }
        if (ord !== 0) {
          console.log(this._nodes[ord - 1], "connect", node);
        }
      }
      if (ord !== length && ord !== 0) {
        console.log(this._nodes[ord - 1], "disconnect", this._nodes[ord]);
        this._nodes[ord - 1].disconnect(this.from(this._nodes[ord]));
        console.log(this._nodes[ord - 1], "connect", node);
        this._nodes[ord - 1].connect(this.to(node));
        console.log(node, "connect", this._nodes[ord]);
        node.connect(this.to(this._nodes[ord]));
      }
      this._nodes.splice(ord, 0, node);
      return console.log("spliced:", this._nodes);
    };

    Node.prototype.connect_incoming = function() {
      return console.log('do incoming');
    };

    Node.prototype.disconnect_incoming = function() {
      return console.log('undo incoming');
    };

    Node.prototype.connect = function(node, param, output, input) {
      console.log("called connect on ", this, node);
      return this._nodes[this._nodes.length - 1].connect(node);
    };

    Node.prototype.to = function(node) {
      switch (this.__typeof(node)) {
        case "Node":
          return node._nodes[0];
        case "AudioNode":
          return node;
        default:
          throw New(Error("Unknown node type passed to connect"));
      }
    };

    Node.prototype.from = Node.prototype.to;

    Node.prototype.expose_methods_of = function(node) {
      var key, results, val;
      console.log("exposing", node);
      results = [];
      for (key in node) {
        val = node[key];
        if (this[key] != null) {
          continue;
        }
        console.log("- checking", this.__typeof(val));
        switch (this.__typeof(val)) {
          case 'function':
            results.push(this[key] = val.bind(node));
            break;
          case 'AudioParam':
            results.push(this[key] = val);
            break;
          case "string":
          case "number":
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

    return Node;

  })();

  Gain = (function(superClass) {
    extend(Gain, superClass);

    function Gain() {
      var _instance, node_list;
      _instance = arguments[0], node_list = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      this._instance = _instance;
      Gain.__super__.constructor.apply(this, arguments);
      this.insert_node(this.context.createGain(), 0);
      this.expose_methods_of(this._nodes[0]);
    }

    return Gain;

  })(Node);

  Oscillator = (function(superClass) {
    extend(Oscillator, superClass);

    function Oscillator() {
      var _instance, node_list;
      _instance = arguments[0], node_list = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      this._instance = _instance;
      Oscillator.__super__.constructor.apply(this, arguments);
      this.insert_node(this.context.createOscillator(), 0);
      this.insert_node(new Gain(this._instance, 'Gain'));
      this._is_started = false;
      this.expose_methods_of(this._nodes[0]);
    }

    Oscillator.prototype.start = function() {
      if (this._is_started) {
        return this._nodes[1].gain.value = 1.0;
      } else {
        this._nodes[0].start();
        return this._is_started = true;
      }
    };

    Oscillator.prototype.stop = function() {
      return this._nodes[1].gain.value = 0;
    };

    return Oscillator;

  })(Node);

  StereoPanner = (function(superClass) {
    extend(StereoPanner, superClass);

    function StereoPanner() {
      var _instance, node_list;
      _instance = arguments[0], node_list = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      this._instance = _instance;
      StereoPanner.__super__.constructor.apply(this, arguments);
    }

    return StereoPanner;

  })(Node);

  Mooog = (function() {
    Mooog.LEGAL_NODES = {
      'Oscillator': Oscillator,
      'StereoPanner': StereoPanner,
      'Gain': Gain
    };

    function Mooog(initOb) {
      this.initOb = initOb;
      this._BROWSER_CONSTRUCTOR = false;
      this.context = this.create_context();
      this._destination = this.context.destination;
      this._nodes = {};
      this._connections = {};
      this._node_id_count = 1;
    }

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
      var id, node_list, ref;
      id = arguments[0], node_list = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      if (((ref = this._nodes) != null ? ref[id] : void 0) != null) {
        return this._nodes[id];
      }
      return this._nodes[id] = (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return Object(result) === result ? result : child;
      })(Node, [this].concat(slice.call(node_list)), function(){});
    };

    Mooog.prototype.create_connection = function(from, to) {
      var ref;
      return (ref = this._connections[from]) != null ? ref[to] = true : void 0;
    };

    Mooog.prototype.delete_connection = function(from, to) {
      var ref;
      return (ref = this._connections[from]) != null ? delete ref[to] : void 0;
    };

    Mooog.prototype.next_node_id = function() {
      this._node_id_count += 1;
      return "_node" + this._node_id_count;
    };

    return Mooog;

  })();

  window.Mooog = Mooog;

}).call(this);
