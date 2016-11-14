class SocketBridge 
{
	// Joymax socket
	static var sJoymax = new flash.net.Socket();
	
	// WebCL server socket
	static var sCL = new flash.net.Socket();
		
	static var jsScope;

        static function main() 
        {		        
		if (flash.external.ExternalInterface.available) 
		{
			jsScope = flash.Lib.current.loaderInfo.parameters.scope;

			if(jsScope == null) 
			{
				jsScope = "";
			} 
			else 
			{
				jsScope += ".";
			}

			/* Calls the javascript load method once the SWF has loaded */
			flash.external.ExternalInterface.call("setTimeout", jsScope + "loaded()");			

			// Set event listeners for socket

			// Connected to Joymax
			sJoymax.addEventListener(flash.events.Event.CONNECT, function(e) : Void { 
					trace("Connected to Joymax");
					flash.external.ExternalInterface.call("setTimeout", jsScope + "connected()", 0);
				}
			);

			// Receiving data from Joymax
			sJoymax.addEventListener(flash.events.ProgressEvent.SOCKET_DATA, function(e) : Void {
						var msgSize = sJoymax.bytesAvailable;
						trace("Receiving " + msgSize + " bytes from Joymax" );
						var packet = new flash.utils.ByteArray();
						sJoymax.readBytes(packet);
						packet.position = 0;
						
						flash.external.ExternalInterface.call("logmsg", "JM->WebCL client: ");
						
						while(packet.bytesAvailable != 0)
						{
							var byte = packet.readUnsignedByte();
							
							// Call the JS log function
							flash.external.ExternalInterface.call("logmsg", StringTools.hex(byte, 2));							
						}
						
						// Make a new line in the HTML document
						flash.external.ExternalInterface.call("logmsg", "<br>");
						
						// Forward the packet to WebCL server
						sCL.writeBytes(packet);
						sCL.flush();
						
						flash.external.ExternalInterface.call("setTimeout", jsScope + "receive('" + packet.toString() + "')", 0);
					}
			);

			// Joymax closed the socket
			sJoymax.addEventListener(flash.events.Event.CLOSE, function(e) : Void {
					trace("Disconnected from Joymax");
					flash.external.ExternalInterface.call("setTimeout", jsScope + "disconnected()", 0);				
				}
			);

			// Connected to WebCL server
			sCL.addEventListener(flash.events.Event.CONNECT, function(e) : Void { 
					trace("Connected to WebCL server");
					flash.external.ExternalInterface.call("setTimeout", jsScope + "connected()", 0);
				}
			);

			// Receiving data from WebCL server
			sCL.addEventListener(flash.events.ProgressEvent.SOCKET_DATA, function(e) : Void {
						trace("Receiving " + sCL.bytesAvailable + " bytes from WebCL server" );
						var packet = new flash.utils.ByteArray();
						sCL.readBytes(packet);
						packet.position = 0;
						
						flash.external.ExternalInterface.call("logmsg", "WebCL server -> WebCL client: ");
						
						while(packet.bytesAvailable != 0)
						{
							var byte = packet.readUnsignedByte();

							// Call the JS log function
							flash.external.ExternalInterface.call("logmsg", StringTools.hex(byte, 2));							
						}
						
						// Check the direction of packet
						packet.position = 0;
						
						// To client
						if(packet.readByte() == 0)
						{
							flash.external.ExternalInterface.call("logmsg", " [Direction: Client][Type : WebCL packet]");
							// Now send the packet
						}
						
						packet.position = 0;
						
						// To server
						if(packet.readByte() == 1)
						{
							flash.external.ExternalInterface.call("logmsg", " [Direction: Server][Type : Silkroad packet]");
							// Now send the packet
						}
						
												
						// Make a new line in the HTML document
						flash.external.ExternalInterface.call("logmsg", "<br>");
						
						flash.external.ExternalInterface.call("setTimeout", jsScope + "receive('" + packet.toString() + "')", 0);
					}
			);

			// WebCL server closed the socket
			sCL.addEventListener(flash.events.Event.CLOSE, function(e) : Void {
					trace("Disconnected from WebCL server");
					flash.external.ExternalInterface.call("setTimeout", jsScope + "disconnected()", 0);				
				}
			);


			// Set External Interface Callbacks

			// connect(host, port) 
			flash.external.ExternalInterface.addCallback("connectSocket", connect);	    	

			// close() 
			flash.external.ExternalInterface.addCallback("closeSocket", close);	
			
			// Connect to joymax and webcl
			flash.external.ExternalInterface.addCallback("connect", ConnectToServers);
		} 
		else 
		{
			trace("Flash external interface not available");
		}   

        } 
        
        // Connects to the WebCL server and Joymax loginserver
        static function ConnectToServers()
        {
        	// Connect to WebCL server
		connect(sCL, "localhost", "15778");

		// Connect to JM loginserver
		connect(sJoymax, "gwgt1.joymax.com", "15779");	
        }
          
	// Connect the socket to some server
	// Host is the hostname or IP of the server
	// Port is the port of the server
	static function connect(socket, host : String, port : String) 
	{
		trace("Connecting to socket server at " + host + ":" + port);
		socket.connect(host, Std.parseInt(port));    	
	}

	// Disconnects the given socket from server it's connected to
	static function close(socket) 
	{
		if (socket.connected) 
		{
			trace("Closing current connection");
			socket.close();
		} 
		else 
		{
			trace("Cannot disconnect to server because there is no connection!");
		}
	}
}