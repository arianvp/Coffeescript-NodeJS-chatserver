# We need the net module for tcp functionality
net = require 'net'
###
 this is the client list. it keeps track of all active connections
###
clients = []
###
 the server object emits an event if a connection is made
 the first argument is an anonymous function/closure that is
 the initial connection handler. The initial connection handler
 sets the correct encoding, adds the client to the
 clientlist and adds the appropiate handler to the client
 so that the connection gets removed from the clientlist when
 it disconnects.
###
server = net.createServer (client) ->

    ###
     It's a text-based protocol, hence we use utf8 encoding.
    ###
    client.setEncoding 'utf8'
    
    ###
     we save the index to the slot field of the client object
     so that we can remove the client from the clientlist when
     it is no longer needed.
    ###
    client.slot = (clients.push client) - 1
    
    ###
     Here we add a handler for the 'end' event. The end event is
     emitted when the socket ends. If the end event is emitted
     we know the client won't send us any data anymore so we
     remove it from the client list as it isn't part of the chat
     anymore.
    ###
    client.on 'end', ->
        clients.splice client.index, 1

###
 here we add a secondary event handler for the connection event.
 I could have put the stuff that happens in this handler in the
 initial handler, but I like to keep stuff apart. Lets call this
 the protocol definition and the above the administration definition.
###
server.on 'connection', (client) ->
    client.write 'Please enter your name:'
    client.on 'data', (message) ->
        # check if the client has a name yet
        if client.name is undefined
            # We filter out the newline character and then set the name
            client.name = message.split('\n')[0]
            ###
             we broadcast that a new client has logged in to all other clients
             that are logged in. 
            ###
            for cli in clients when cli isnt client and cli.name isnt undefined
                cli.write "#{client.name} has joined the chat!\n"
        else
            ###
             if the client already has a name, then we know he is sending a
             message instead of a name. hence we broadcast it to all other
             logged in clients.
            ###
            for cli in clients when cli isnt client and cli.name isnt undefined
                cli.write "#{client.name} says : #{message}"
    
    ###
     lets broadcast to all other clients that the client left the chat.
    ###
    client.on 'end', ->
        for cli in clients when cli.name isnt undefined
            cli.write "#{client.name} has left the chat!\n"
                
# lets fire up our server!
server.listen 5000
                
                
