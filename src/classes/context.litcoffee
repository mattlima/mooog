## Context

Wraps the AudioContext object and exposes the Track object

    class Context
      constructor: ->
        @_AudioContext = @create_context()
        @_destination = @_AudioContext.destination
        @_tracks = {}

      create_context: () ->
        new AudioContext()

      track: (id) ->
        return @_tracks[id] if @_tracks[id]?
        @_tracks[id] = new Track(id, this)
