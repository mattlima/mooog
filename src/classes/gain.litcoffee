## Gain

Wraps the GainNode AudioContext object

    class Gain extends Node
      constructor: (@_instance, node_list...) ->
        super
        @insert_node @context.createGain(), 0
        @expose_methods_of @_nodes[0]

      
