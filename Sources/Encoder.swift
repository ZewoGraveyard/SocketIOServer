// Encoder.swift
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

import JSON

struct SocketIOEncoder {
	
	/// Encode a packet as a single string if non-binary, or as a NSData, depending on packet type.
	static func encode(packet: Packet) -> Data {
		if packet.type == .binaryEvent || packet.type == .binaryAck {
			fatalError("not implemented")
		} else {
			return encodeAsString(packet: packet).data
		}
	}
	
	/// Encode packet as string
	private static func encodeAsString(packet: Packet) -> String {
		var str = ""
		var nsp = false
		
		// first is type
		str += String(packet.type.rawValue)
		
		// attachments if we have them
		if packet.type == .binaryEvent || packet.type == .binaryAck {
			fatalError("not implemented")
		}
		
		// if we have a namespace other than `/` we append it followed by a comma `,`
		if let nspStr = packet.nsp where nspStr != "/" {
			nsp = true
			str += nspStr
		}
		
		// immediately followed by the id
		if let id = packet.id {
			if nsp {
				str += ","
				nsp = false
			}
			str += String(id)
		}
		
		// json data
		if nsp { str += "," }
		
		str += try! JSONStructuredDataSerializer().serializeToString(.infer(packet.data))
		
		log("encoded \(packet) as \(str)")
		return str
	}
	
}
