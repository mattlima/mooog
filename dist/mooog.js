(function() {
  var Context, Mooog, Node, Oscillator, Track,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Context = (function() {
    function Context() {
      this._AudioContext = this.create_context();
      this._destination = this._AudioContext.destination;
      this._tracks = {};
    }

    Context.prototype.create_context = function() {
      return new AudioContext();
    };

    Context.prototype.track = function(id) {
      if (this._tracks[id] != null) {
        return this._tracks[id];
      }
      return this._tracks[id] = new Track(id, this);
    };

    return Context;

  })();

  Node = (function() {
    function Node(type, context, initOb) {
      this.type = type;
      this.context = context;
      this.initOb = initOb;
      switch (this.type) {
        case "oscillator":
          this.original_node = this.context.createOscillator();
      }
    }

    return Node;

  })();

  Oscillator = (function(superClass) {
    extend(Oscillator, superClass);

    function Oscillator(type, context, initOb) {
      this.type = type;
      this.context = context;
      this.initOb = initOb;
      Oscillator.__super__.constructor.apply(this, arguments);
      console.log(this.original_node);
    }

    return Oscillator;

  })(Node);

  Track = (function() {
    function Track(id1, context) {
      this.id = id1;
      this.context = context;
      this._nodes = [];
      this._panner = this.context._AudioContext.createPanner();
      this._gain = this.context._AudioContext.createGain();
    }

    return Track;

  })();

  Mooog = (function() {
    function Mooog(initOb) {
      this.initOb = initOb;
    }

    Mooog.prototype.context = function() {
      return new Context();
    };

    return Mooog;

  })();

  window.Mooog = Mooog;

}).call(this);

//# sourceMappingURL=mooog.js.map
