# Mooog

> Chainable AudioNode objects

### Why Mooog?

Mooog is inspired by audio mixing boards on the one hand and jQuery chainable
syntax on the other. It automatically does a lot of stuff so you don't have to.

### Assumptions

Mooog assumes that you'll be working with one or more chains of AudioNode
objects, organized into tracks, like a mixer. It will automatically create a
panner and a gain module that can be controlled from the track. It
automatically routes the end of the chain to the destinationNode.
