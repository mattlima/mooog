var Wrapper;

Wrapper = (function() {
  function Wrapper(name) {
    this.name = name;
    ({
      move: function(meters) {
        return alert(this.name + (" moved " + meters + "m."));
      }
    });
  }

  return Wrapper;

})();

console.log('goodbye');

//# sourceMappingURL=mooog.js.map
