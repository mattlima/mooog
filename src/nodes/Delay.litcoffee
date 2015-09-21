## Delay

Wraps the DelayNode AudioContext object. Has a built-in `feedback`
parameter (off by default).

    class Delay extends MooogAudioNode
      constructor: (@_instance, config = {}) ->
        super
      
      before_config: (config)->
        @insert_node @context.createDelay(), 0
        @_feedback_stage = new Gain( @_instance, { connect_to_destination: false, gain: 0 } )
        @_nodes[0].connect @to @_feedback_stage
        @_feedback_stage.connect @to @_nodes[0]
        @feedback = @_feedback_stage.gain
      
      after_config: (config)->
