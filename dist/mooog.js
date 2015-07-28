(function() {
  var Mooog, Node, Oscillator, Track,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    slice = [].slice;

  Node = (function() {
    function Node(_track, params) {
      this._track = _track;
      this._incoming = [];
      this._outgoing = [];
      this._rebinds = {};
      this.update_bindings(this.base_node);
    }

    Node.prototype.update_bindings = function(base_node) {
      var key;
      for (key in base_node) {
        if (this._rebinds[key] || (this[key] == null)) {
          this._rebinds[key] = true;
          switch (this.__typeof(base_node[key])) {
            case "function":
              this[key] = base_node[key].bind(base_node);
              break;
            case "string":
            case "number":
              (function(o, key) {
                return Object.defineProperty(o, key, {
                  get: function() {
                    return this.base_node[key];
                  },
                  set: function(val) {
                    return this.base_node[key] = val;
                  },
                  enumerable: true,
                  configurable: true
                });
              })(this, key);
              break;
            case "AudioParam":
              this[key] = base_node[key];
          }
        }
      }
      return this;
    };

    Node.prototype.__typeof = function(thing) {
      if (thing instanceof AudioParam) {
        return "AudioParam";
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

    Node.prototype.clone_AudioNode = function(source, dest) {
      var key;
      for (key in source) {
        switch (this.__typeof(source[key])) {
          case "function":
            if (this.functions_to_copy.indexOf(key) > -1) {
              dest[key] = source[key].bind(dest);
            }
            break;
          case "string":
          case "number":
            dest[key] = source[key];
            break;
          case "AudioParam":
            dest[key].value = source[key].value;
        }
      }
      return dest;
    };

    return Node;

  })();

  Oscillator = (function(superClass) {
    extend(Oscillator, superClass);

    function Oscillator() {
      var _track, params;
      _track = arguments[0], params = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      this._track = _track;
      this.functions_to_copy = ["onended"];
      this.base_node = this._track._instance._context.createOscillator();
      this.base_node.connect(this._track._instance._destination, 0);
      Oscillator.__super__.constructor.apply(this, arguments);
    }

    Oscillator.prototype.stop = function() {
      var new_base;
      this.base_node.stop();
      new_base = this._track._instance._context.createOscillator();
      this.base_node = this.clone_AudioNode(this.base_node, new_base);
      this.base_node.connect(this._track._instance._destination, 0);
      this.update_bindings(this.base_node);
      return this;
    };

    return Oscillator;

  })(Node);

  Track = (function() {
    function Track(id1, _instance, type, params) {
      this.id = id1;
      this._instance = _instance;
      this._nodes = [];
      this._panner = this._instance._context.createPanner();
      this._gain = this._instance._context.createGain();
      if (type != null) {
        this.add_node(type, 0, params);
      }
    }

    Track.prototype.add_node = function(type, ord, params) {
      switch (type) {
        case "Oscillator":
          return this._nodes.splice(ord, 0, new Oscillator(this, params));
        default:
          throw new Error("Unknown AudioNode type: " + type);
      }
    };

    return Track;

  })();

  Mooog = (function() {
    function Mooog(initOb) {
      this.initOb = initOb;
      this._BROWSER_CONSTRUCTOR = false;
      this._context = this.create_context();
      this._destination = this._context.destination;
      this._tracks = {};
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

    Mooog.prototype.track = function(id, type, params) {
      var ref;
      if (((ref = this._tracks) != null ? ref[id] : void 0) != null) {
        return this._tracks[id];
      }
      return this._tracks[id] = new Track(id, this, type, params);
    };

    return Mooog;

  })();

  window.Mooog = Mooog;

}).call(this);
