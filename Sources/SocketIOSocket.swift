// SocketIOSocket.swift
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

public typealias AckCallback = ([StructuredData]) -> Void

public class SocketIOSocket {
	
	internal let namespace: Namespace
	private let client: Client
	
	private var rooms = [AnyObject]()
	private var acks = [Int: AckCallback]()
	private var connected = true
	
	public var storage = [String: Any]()
		
	public var server: SocketIOServer {
		return namespace.server
	}
	
	public var id: String {
		return namespace.name + "#" + client.id
	}
	
	public var request: Request {
		return client.request
	}
	
	internal let eventEmitter = EventEmitter<(event: String, data: [StructuredData], ack: ((StructuredData...) -> Void)?)>()
	internal let errorEventEmitter = EventEmitter<String>()
	internal let disconnectEventEmitter = EventEmitter<Void>()
	
	internal init(namespace: Namespace, client: Client) {
		self.namespace = namespace
		self.client = client
//		self.handshake = buildHandshake()
	}
	
	/// Builds the `handshake` BC object
//	private func buildHandshake() -> [String: String] {
//		return [
//			"time": "0"
//			headers: this.request.headers,
//			time: (new Date) + '',
//			address: this.conn.remoteAddress,
//			xdomain: !!this.request.headers.origin,
//			secure: !!this.request.connection.encrypted,
//			issued: +(new Date),
//			url: this.request.url,
//			query: url.parse(this.request.url, true).query || {}
//		]
//	}
	
	/// Emits to this client
	public func emit(event: String, items: [StructuredData], ackCallback: AckCallback? = nil) {
		var packet = Packet(type: .event, data: [.infer(event)] + items)
		
		if let ackCallback = ackCallback {
//			if (this._rooms || flags.broadcast) {
//				throw new Error('Callbacks are not supported when broadcasting');
//			}
			
			log("emitting packet with ack id \(namespace.ids)")
			acks[namespace.ids] = ackCallback
			packet.id = namespace.ids
			namespace.ids += 1
		}
		
//		if (this._rooms || flags.broadcast) {
//			this.adapter.broadcast(packet, {
//				except: [this.id],
//				rooms: this._rooms,
//				flags: flags
//			});
//		} else {
			// dispatch packet
			writePacket(packet: packet)
//			this.packet(packet, {
//				volatile: flags.volatile,
//				compress: flags.compress
//			});
//		}
		
		// reset flags
//		delete this._rooms;
//		delete this.flags;
	}
	
	public func emit(event: String, _ items: StructuredData..., ackCallback: AckCallback? = nil) {
		emit(event: event, items: items, ackCallback: ackCallback)
	}
	
//	/// Targets a room when broadcasting.
//	func to(name: String) {
//		this._rooms = this._rooms || [];
//		if (!~this._rooms.indexOf(name)) this._rooms.push(name);
//	}
	
//	/// Sends a `message` event.
//	func send(items: InterchangeData..., ackCallback: AckCallback? = nil) {
//		emit("message", items: items)
//	}
	
	/// Writes a packet
	private func writePacket(packet: Packet) {
		var packet = packet
		packet.nsp = namespace.name
//		opts.compress = false !== opts.compress;
		client.writePacket(packet: packet)
	}
	
	/// Joins a room
	public func join(room: String) {
		log("joining room \(room)")
//		if (~this.rooms.indexOf(room)) return this;
//		this.adapter.add(this.id, room, function(err){
//			if (err) return fn && fn(err);
//			debug('joined room %s', room);
//			self.rooms.push(room);
//			fn && fn(null);
//		});
	}
	
	/// Leaves a room
	public func leave(room: String) {
		log("leave room \(room)")
//		this.adapter.del(this.id, room, function(err){
//			if (err) return fn && fn(err);
//			debug('left room %s', room);
//			var idx = self.rooms.indexOf(room);
//			if (idx >= 0) {
//				self.rooms.splice(idx, 1);
//			}
//			fn && fn(null);
//		});
	}
	
	/// Leave all rooms
	public func leaveAll() {
//		adapter.delAll(this.id)
		rooms = []
	}
	
	/// Called by `Namespace` upon succesful middleware execution (ie: authorization)
	internal func onConnect() {
		log("socket connected - writing packet")
		namespace.connected[id] = self
		join(room: id)
		writePacket(packet: Packet(type: .connect))
	}
	
	/// Called with each packet. Called by `Client`
	internal func onPacket(packet: Packet) {
		log("got packet \(packet)")
		switch (packet.type) {
		case .event, .binaryEvent:
			onEvent(packet: packet)
		case .ack, .binaryAck:
			onAck(packet: packet)
		case .disconnect:
			log("got disconnect packet")
			onClose(reason: .transportClose, description: "client namespace disconnect")
		case .error:
			onError(error: packet.data.first?.stringValue ?? "")
		default:
			break
		}
	}
	
	/// Called upon event packet
	private func onEvent(packet: Packet) {
		let data = Array(packet.data.dropFirst())
		
		guard data.count > 0, let event = packet.data.first?.stringValue else {
			return
		}
		
		log("emitting event \(event) with data \(data)")
		
		let ack: ((StructuredData...) -> Void)?
		if let id = packet.id {
			log("attaching ack callback to event")
			ack = makeAck(id: id)
		} else {
			ack = nil
		}
		
		eventEmitter.safeEmit(event: (event: event, data: data, ack: ack))
	}
	
	/// Produces an ack callback to emit with an event
	private func makeAck(id: Int) -> (StructuredData...) -> Void {
		var sent = false
		return { args in
			guard !sent else { return }
			sent = true
			log("sending ack \(args)")
//			var type = hasBin(args) ? parser.BINARY_ACK : parser.ACK;
			self.writePacket(packet: Packet(id: id, type: .ack, data: args))
		}
	}
	
	/// Called upon ack packet
	private func onAck(packet: Packet) {
		guard let id = packet.id, ack = acks[id] else {
			return log("bad ack \(packet.id)")
		}
		
		log("calling ack \(packet.id) with \(packet.data)")
		ack(packet.data)
		acks.removeValue(forKey: id)
	}
	
	/// Handles a client error
	internal func onError(error: String) {
		log(level: .error, "got error packet")
		errorEventEmitter.safeEmit(event: error)
	}
	
	/// Called upon closing. Called by `Client`
	internal func onClose(reason: TransportCloseReason, description: String?) {
		guard connected else { return }
		log("closing socket - reason \(reason) \(description)")
		leaveAll()
		namespace.remove(socket: self)
//		client.remove(self)
		connected = false
		namespace.connected.removeValue(forKey: id)
		disconnectEventEmitter.safeEmit(event: ())
	}
	
	/// Produces an `error` packet
	internal func sendError(error: String) {
		writePacket(packet: Packet(type: .error, data: [.infer(error)]))
	}
	
	/// Disconnects this client
	public func disconnect(close: Bool = false) {
		guard connected else { return }
		if close {
			client.disconnect()
		} else {
			writePacket(packet: Packet(type: .disconnect))
			onClose(reason: .forcedClose, description: "server namespace disconnect")
		}
	}
	
	// MARK: - EventEmitter
	
	public func onEvent(listen: EventListener<(event: String, data: [StructuredData], ack: ((StructuredData...) -> Void)?)>.Listen) -> EventListener<(event: String, data: [StructuredData], ack: ((StructuredData...) -> Void)?)> {
		return eventEmitter.addListener(listen: listen)
	}
	
	public func onError(listen: EventListener<String>.Listen) -> EventListener<String> {
		return errorEventEmitter.addListener(listen: listen)
	}
	
	public func onDisconnect(listen: EventListener<Void>.Listen) -> EventListener<Void> {
		return disconnectEventEmitter.addListener(listen: listen)
	}
	
}

// MARK: - Equatable

extension SocketIOSocket: Equatable {}

public func ==(lhs: SocketIOSocket, rhs: SocketIOSocket) -> Bool {
	return lhs.id == rhs.id
}
