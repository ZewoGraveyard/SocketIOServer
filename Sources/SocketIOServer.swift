// Server.swift
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

import HTTP
import Event
import EngineIOServer

internal extension EventEmitter {
	func safeEmit(event: T) {
		do {
			try emit(event)
		} catch {
			log(level: .error, "error: \(error)")
		}
	}
}

internal func log(level: LogLevel = .debug, _ item: Any) {
	guard level.rawValue >= SocketIOServer.logLevel.rawValue else { return }
	print(item)
}

public class SocketIOServer: Responder, Middleware {
	
	public static var logLevel: LogLevel = .error {
		didSet {
			EngineIOServer.logLevel = logLevel
		}
	}
	
	public var path = "/socket.io" {
		didSet {
			engine.path = self.path
		}
	}
	public let engine = EngineIOServer()
	public private(set) var mainNsp: Namespace!
	public private(set) var nsps = [String: Namespace]()
	
	let connectionEventEmitter = EventEmitter<SocketIOSocket>()
	
	public init() {
		// set engine.io path to `/socket.io`
		engine.path = self.path
		
		// create main namespace
		self.mainNsp = of(name: "/")
		
		// set origins verification
//		opts.allowRequest = this.checkRequest.bind(this);
		
		// initialize engine
		log("creating engine.io instance")
		
		// bind to engine events
		engine.onConnect(listen: self.onConnection)
	}
	
	public convenience init(onConnect: EventListener<SocketIOSocket>.Listen) {
		self.init()
		self.onConnect(listen: onConnect)
	}
	
	/// Called with each incoming transport connection
	func onConnection(socket: EngineIOSocket) {
		log("incoming connection with id \(socket.id)")
		let client = Client(server: self, conn: socket)
		client.connect(name: "/")
	}
	
	/// Looks up a namespace
	public func of(name: String, onConnect: EventListener<SocketIOSocket>.Listen? = nil) -> Namespace {
		var name = name
		if !name.hasPrefix("/") {
			name = "/" + name
		}
		let nsp: Namespace
		if let _nsp = nsps[name] {
			nsp = _nsp
		} else {
			log("initializing namespace \(name)")
			nsp = Namespace(server: self, name: name)
			nsps[name] = nsp
		}
		if let onConnect = onConnect {
			nsp.connectionEventEmitter.addListener(listen: onConnect)
		}
		return nsp
	}
	
	/// Closes server connection
	public func close() {
		for socket in mainNsp.sockets {
			socket.onClose(reason: .serverClose, description: nil)
		}
		
		engine.close()
	}
	
	// MARK: - Expose main namespace (/)
	
//	on, to, in, use, emit, send, write, clients, compress
	
//	public override func _on(event: String, _ callback: EventEmitterCallback) -> EventEmitterHandler {
//		return self.mainNsp._on(event, callback)
//	}
	
	public func emit(event: String, _ items: StructuredData...) {
		mainNsp.emit(event: event, items: items)
		
	}
	
	// MARK: - Middleware
	
	public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
		return try engine.respond(to: request, chainingTo: next)
	}
	
	// MARK: - Responder
	
	/// Handles an Engine.IO HTTP request
	public func respond(to request: Request) throws -> Response {
		return try engine.respond(to: request)
	}
	
	// MARK: - EventEmitter
	
	public func onConnect(listen: EventListener<SocketIOSocket>.Listen) -> EventListener<SocketIOSocket> {
		return mainNsp.connectionEventEmitter.addListener(listen: listen)
	}
	
}
