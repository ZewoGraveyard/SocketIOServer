// Decoder.swift
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
import String

extension String {
	subscript(i: Int) -> Character? {
		guard i >= 0 && i < characters.count else { return nil }
		return Array(characters)[i]
	}
}

struct SocketIODecoder {
	
	private let onDecoded: (Packet) -> Void
	
	internal init(onDecoded: (Packet) -> Void) {
		self.onDecoded = onDecoded
	}
	
	internal func add(data: Data) {
		if let str = try? String(data: data)  {
			let packet = decodeString(str: str)
			onDecoded(packet)
		} else {
			fatalError("Unknown type \(data)")
		}
	}
	
	/// Decode a packet String (JSON data)
	private func decodeString(str: String) -> Packet {
		var i = 0
		
		// look up type
		guard let char = str[i], num = Int(String(char)), type = Packet.PacketType(rawValue: num) else {
			return Packet(type: .error, data: "Parser Error")
		}
		
		var packet = Packet(type: type)
		
		// look up attachments if type binary
//		if type == .BinaryEvent || type == .BinaryAck {
//
//		}
		
		// look up namespace (if any)
		if let char = str[i+1] where char == "/" {
			var nsp = ""
			while true {
				i += 1
				guard let char = str[i] where char != "," else {
					break
				}
				nsp += String(char)
			}
			packet.nsp = nsp
		} else {
			packet.nsp = "/"
		}
		
		// look up id
		if let char = str[i+1], let _ = Int(String(char)) {
			var idStr = ""
			while true {
				i += 1
				guard let char = str[i], let _ = Int(String(char)) else {
					i -= 1
					break
				}
				idStr += String(char)
			}
			packet.id = Int(idStr)
		}
		
		// look up json data
		i += 1
		
		if let _ = str[i], json = try? JSONStructuredDataParser().parse(String(str.characters.dropFirst(i))), jsonArr = json.arrayValue {
			packet.data = jsonArr
		}
		
		log("decoded \(str) as \(packet)")
		return packet
	}
	
	internal func destroy() {
		
	}
	
}
