// Namespace.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2016 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDINbG BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import StructuredData
import Event

public class Namespace {
	
	public typealias Middleware = (SocketIOSocket) -> String?
	
	public let name: String
	internal let server: SocketIOServer
	internal internal(set) var sockets: [SocketIOSocket] = []
	public internal(set) var connected: [String: SocketIOSocket] = [:]
	private var fns = [Middleware]()
	internal var ids = 0
	private var acks = [String: Any]()
	
	internal let connectionEventEmitter = EventEmitter<SocketIOSocket>()
	
	init(server: SocketIOServer, name: String) {
		self.server = server
		self.name = name
		initAdapter()
	}
	
	/// Initializes the `Adapter` for this nsp
	/// Run upon changing adapter by `Server#adapter` in addition to the constructor
	private func initAdapter() {
//		this.adapter = new (this.server.adapter())(this);
	}
	
	/// Sets up namespace middleware
	public func use(fn: Middleware) {
		fns.append(fn)
	}
	
	/// Executes the middleware for an incoming client
	private func runMiddleware(socket: SocketIOSocket) -> String? {
		if fns.count <= 0 { return nil }
//		var fns = self.fns
		
//		func run(i) {
//			fns[i](socket, function(err){
//				// upon error, short-circuit
//				if (err) return fn(err);
//
//				// if no middleware left, summon callback
//				if (!fns[i + 1]) return fn(null);
//
//				// go on to next
//				run(i + 1);
//			});
//		}
//
//		run(0);
		
		return nil
	}
	
//	/// Targets a room when emitting
//	public func to(name: String) {
//		this.rooms = this.rooms || [];
//		if (!~this.rooms.indexOf(name)) this.rooms.push(name);
//	}
	
	/// Adds a new client
	internal func add(client: Client) -> SocketIOSocket {
		log("adding socket to nsp \(name)")
		let socket = SocketIOSocket(namespace: self, client: client)
		
		let error = runMiddleware(socket: socket)
		
		guard client.conn.readyState == .open else {
			log("next called after client was closed - ignoring socket")
			return socket
		}
		
		if let error = error {
			socket.sendError(error: error)
			return socket
		}
		
		// track socket
		sockets.append(socket)
		
		// it's paramount that the internal `onconnect` logic fires before user-set events to prevent state order violations
		// (such as a disconnection before the connection logic is complete)
		socket.onConnect()
		
		// fire user-set events
		connectionEventEmitter.safeEmit(event: socket)
		
		return socket
	}
	
	/// Removes a client. Called by each `Socket`
	internal func remove(socket: SocketIOSocket) {
		if let index = sockets.index(of: socket) {
			sockets.remove(at: index)
		} else {
			log("ignoring remove for \(socket.id)")
		}
	}
	
	/// Emits to all clients
	public func emit(event: String, _ items: StructuredData...) {
		emit(event: event, items: items)
	}
	
	public func emit(event: String, items: [StructuredData]) {
		// set up packet object
//		if (hasBin(args)) { parserType = parser.BINARY_EVENT; } // binary
//		let packet = SocketIOPacket(type: .Event, data: items)

//		this.adapter.broadcast(packet, {
//			rooms: this.rooms,
//			flags: this.flags
//		});

//		delete this.rooms;
//		delete this.flags;
	}
	
	/// Sends a `message` event to all clients
	public func send(items: StructuredData...) {
		emit(event: "message", items: items)
	}
	
//	/// Gets a list of clients
//	public func clients() {
//		this.adapter.clients(this.rooms, fn);
//	}
	
}
