// Client.swift
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

import EngineIOServer
import Event
import HTTP
import JSON

public class Client {
	
	public let server: SocketIOServer
	public let conn: EngineIOSocket
	private var decoder: SocketIODecoder!
	
	private var onDecodedEventListener: EventListener<Packet>?
	private var onDataEventListener: EventListener<Data>?
	private var onErrorEventListener: EventListener<String>?
	private var onCloseEventListener: EventListener<(reason: TransportCloseReason, description: String?)>?
	
	private var sockets: [SocketIOSocket] = []
	private var nsps: [String: SocketIOSocket] = [:]
	private var connectBuffer: [String] = []
	
	public var id: String {
		return conn.id
	}
	
	public var request: Request {
		return conn.request
	}
	
	internal init(server: SocketIOServer, conn: EngineIOSocket) {
		self.server = server
		self.conn = conn
		self.decoder = SocketIODecoder(onDecoded: self.onDecoded)
		
		// Set up event listeners
		onDataEventListener = conn.onMessage(listen: onData)
		onErrorEventListener = conn.onError(listen: onError)
		onCloseEventListener = conn.onClose(listen: onClose)
	}
	
	/// Connects a client to a namespace
	internal func connect(name: String) {
		log("connecting to namespace \(name)")
		
		guard let nsp = server.nsps[name] else {
			log("Invalid namespace")
			return writePacket(packet: Packet(type: .error, nsp: name, data: .infer("Invalid namespace")))
		}
		
		if name != "/" && nsps["/"] == nil {
			return connectBuffer.append(name)
		}
		
		let socket = nsp.add(client: self)
		sockets.append(socket)
		log("Added namespace \(nsp.name)")
		nsps[nsp.name] = socket
		
		if nsp.name == "/" {
			connectBuffer.forEach(self.connect)
			connectBuffer.removeAll()
		}
	}
	
	/// Disconnects from all namespaces and closes transport
	internal func disconnect() {
		sockets.forEach({ $0.disconnect() })
		sockets.removeAll()
		close()
	}
	
	/// Removes a socket. Called by each `Socket`
	private func remove(socket: SocketIOSocket) {
		if let i = sockets.index(of: socket) {
			let nsp = socket.namespace.name
			sockets.remove(at: i)
			nsps.removeValue(forKey: nsp)
		} else {
			log("ignoring remove for \(socket.id)")
		}
	}
	
	/// Closes the underlying connection
	private func close() {
		guard conn.readyState == .open else { return }
		log("forcing transport close")
		conn.close(discard: true)
		onClose(reason: .forcedClose)
	}
	
	/// Writes a packet to the transport
	internal func writePacket(packet: Packet) {
		guard conn.readyState == .open else {
			return log("ignoring packet write \(packet)")
		}
		
		log("writing packet \(packet)")
		let data = SocketIOEncoder.encode(packet: packet)
//		if (opts.volatile && !self.conn.transport.writable) return;
		conn.send(data: data)
	}
	
	/// Called with incoming transport data
	private func onData(data: Data) {
		decoder.add(data: data)
	}
	
	/// Called when parser fully decodes a packet
	private func onDecoded(packet: Packet) {
		guard let nsp = packet.nsp else {
			return log("no nsp")
		}
		
		if packet.type == .connect {
			connect(name: nsp)
		} else {
			if let socket = nsps[nsp] {
				socket.onPacket(packet: packet)
			} else {
				log("no socket for namespace \(nsp)")
			}
		}
	}
	
	/// Handles an error
	private func onError(error: String) {
		sockets.forEach({ $0.onError(error: error) })
		onClose(reason: .clientError)
	}
	
	/// Called upon transport close
	private func onClose(reason: TransportCloseReason, description: String? = nil) {
		log("client close with reason \(reason)")
		
		// ignore a potential subsequent `close` event
		destroy()
		
		// `nsps` and `sockets` are cleaned up seamlessly
		sockets.forEach({ $0.onClose(reason: reason, description: description) })
		sockets.removeAll(keepingCapacity: false)
		
		// clean up decoder
		decoder.destroy()
	}
	
	/// Cleans up event listeners
	private func destroy() {
		onDecodedEventListener?.stop()
		onDecodedEventListener = nil
		onDataEventListener?.stop()
		onDataEventListener = nil
		onErrorEventListener?.stop()
		onErrorEventListener = nil
		onCloseEventListener?.stop()
		onCloseEventListener = nil
	}
	
}
