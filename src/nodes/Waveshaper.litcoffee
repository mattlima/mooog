## WaveShaper

Wraps the WaveShaperNode AudioContext object

    class WaveShaper extends MooogAudioNode
      
      constructor: (@_instance, config = {}) ->
        config.node_type = 'WaveShaper'
        super
        @configure_from config
        @insert_node @context.createWaveShaper(), 0
        @zero_node_setup config

   
      
      chebyshev: (terms, last = [1], current = [1,0]) ->
        if terms < 2
          throw new Error("Terms must be 2 or more for chebyshev generator")
        if current.length is terms
          return @poly.apply @, current
        else
          lasttemp = last
          last = current
          current = current.map( (x)-> 2*x )
          current.push 0
          lasttemp.unshift 0, 0
          lasttemp = lasttemp.map( (x) -> -1 * x )
          newcurrent = for el, i in current
            lasttemp[i] + current[i]
          console.log current, lasttemp, "new cur", newcurrent, this
          return @chebyshev terms, last, newcurrent
      
      # used by the chebyshev generator once the coefficients have been calculated
      poly: (coeffs...) ->
        length = @_instance.config.curve_length
        step = 2/(length - 1)
        curve = new Float32Array(length)
        p = (x, coeffs) ->
          accum = 0
          for i in [0..(coeffs.length-1)]
            a = coeffs[i]
            accum += (a * Math.pow(x, coeffs.length - i - 1))
          accum

        curve[i] = ( p(((i * step) - 1), coeffs) ) for i in [0..length-1]
        curve
      

      
      
      tanh: (n) ->
        length = @_instance.config.curve_length
        step = 2 / (length - 1)
        curve = new Float32Array(length)
        curve[i] = (
          Math.tanh((Math.PI / 2) * n * ((i * step) - 1))
        ) for i in [0..length-1]
        curve
          
      
      

      
