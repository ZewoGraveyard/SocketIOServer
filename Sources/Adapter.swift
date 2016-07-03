// Adapter.swift
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

public class Adapter {
	
	public let namespace: Namespace
	private var sids: [String: Set<String>] = [:]
	private var rooms: [String: Set<String>] = [:]
	
	public init(namespace: Namespace) {
		self.namespace = namespace
	}
	
	/// Adds a socket to a room
	public func addSocket(id: String, toRoom room: String) {
		if sids[id] == nil { sids[id] = [] }
		sids[id]?.insert(room)
		
		if rooms[room] == nil { rooms[room] = [] }
		rooms[room]?.insert(id)
	}
	
	/// Removes a socket from a room
	public func removeSocket(id: String, fromRoom room: String) {
		sids[id]?.remove(room)
		
		rooms[room]?.remove(id)
		if rooms[room]?.count == 0 {
			rooms[room] = nil
		}
	}
	
	/// Removes a socket from all rooms it's joined
	public func removeSocketFromAllRooms(id: String) {
//		  var rooms = this.sids[id];
//		  if (rooms) {
//			for (var room in rooms) {
//				if (this.rooms.hasOwnProperty(room)) {
//					this.rooms[room].del(id);
//					if (this.rooms[room].length === 0) delete this.rooms[room];
//				}
//			}
//		  }
//		  delete this.sids[id];
	}
	
	/// Broadcasts a packet
	public func broadcast(packet: Packet) {
//		  var rooms = opts.rooms || [];
//		  var except = opts.except || [];
//		  var flags = opts.flags || {};
//		  var packetOpts = {
//			preEncoded: true,
//			volatile: flags.volatile,
//			compress: flags.compress
//		  };
//		  var ids = {};
//		  var self = this;
//		  var socket;
//				
//		  packet.nsp = this.nsp.name;
//		  this.encoder.encode(packet, function(encodedPackets) {
//			if (rooms.length) {
//				for (var i = 0; i < rooms.length; i++) {
//					var room = self.rooms[rooms[i]];
//					if (!room) continue;
//					var sockets = room.sockets;
//					for (var id in sockets) {
//						if (sockets.hasOwnProperty(id)) {
//							if (ids[id] || ~except.indexOf(id)) continue;
//							socket = self.nsp.connected[id];
//							if (socket) {
//								socket.packet(encodedPackets, packetOpts);
//								ids[id] = true;
//							}
//						}
//					}
//				}
//			} else {
//				for (var id in self.sids) {
//					if (self.sids.hasOwnProperty(id)) {
//						if (~except.indexOf(id)) continue;
//						socket = self.nsp.connected[id];
//						if (socket) socket.packet(encodedPackets, packetOpts);
//					}
//				}
//			}
//		  });
	}
	
	/// Gets a list of clients by sid
	public func clientsInRooms(rooms: [String]) -> [String] {
		
//		  var ids = {};
//		  var sids = [];
//		  var socket;
//				
//		  if (rooms.length) {
//			for (var i = 0; i < rooms.length; i++) {
//				var room = self.rooms[rooms[i]];
//				if (!room) continue;
//				var sockets = room.sockets;
//				for (var id in sockets) {
//					if (sockets.hasOwnProperty(id)) {
//						if (ids[id]) continue;
//						socket = self.nsp.connected[id];
//						if (socket) {
//							sids.push(id);
//							ids[id] = true;
//						}
//					}
//				}
//			}
//		} else {
//			for (var id in self.sids) {
//				if (self.sids.hasOwnProperty(id)) {
//					socket = self.nsp.connected[id];
//					if (socket) sids.push(id);
//				}
//			}
//		  }
		
		return []
	}
	
}
