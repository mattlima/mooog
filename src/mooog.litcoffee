## Mooog

Wraps the AudioContext object and exposes the Track object. Exposes the API
as the Mooog global


    class Mooog
      constructor: (@initOb) ->
      
Stores the type of constructor used for the AudioContext object
(`AudioContext` or `webkitAudioContext`)

        @_BROWSER_CONSTRUCTOR = false
        @_context = @create_context()
        @_destination = @_context.destination
        @_tracks = {}





      create_context: () ->
        if(window.AudioContext?)
          @_BROWSER_CONSTRUCTOR = 'AudioContext'
          return new AudioContext()
        if(window.webkitAudioContext?)
          @_BROWSER_CONSTRUCTOR = 'webkitAudioContext'
          return new webkitAudioContext()
        throw new Error("This browser does not yet support the AudioContext API")

The track object holds a chain of AudioNodes. By default it includes panner
and gain stages.

      track: (id, type, params) ->
        return @_tracks[id] if @_tracks?[id]?
        @_tracks[id] = new Track(id, this, type, params)

    window.Mooog = Mooog
