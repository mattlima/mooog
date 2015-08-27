## Track

A convenience function that creates a chain with the specified node(s)
followed by a panner/gain stage. It can also create sends with their own  

    class Track extends MooogAudioNode



      constructor: (@_instance, config = {}) ->
        config.node_type = 'Track'
        super
        #@configure_from config

        #@insert_node @context.createOscillator(), 0

        #@zero_node_setup config



        #@_nodes = []
        #@_panner = @_instance.context.createPanner()
        #@_gain = @_instance.context.createGain()
        #@_panner.connect @_gain
        #@_gain.connect @_instance._destination



