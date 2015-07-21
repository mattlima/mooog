## Node

Base class for all the node wrappers

    class Node
      constructor: (@type, @context, @initOb) ->
        switch @type
          when "oscillator"
            @original_node = @context.createOscillator()
