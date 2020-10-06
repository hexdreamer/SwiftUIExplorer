//
//  DRFeedParser.swift
//  DailyRadio
//
//  Created by Kenny Leung on 8/22/20.
//

import Foundation
import hexdreamsCocoa

public class SECustomParser : HXSAXParserDelegate {
        
    private var level:Int = 0
    private var stack = [SECustomParserMode]()
    private let root:SECustomParserMode
    private var text:String?
    private var cdata:Data?
    
    private var parser:HXSAXParser?
    private var fileReader:HXDispatchIOFileReader?
    private var urlSessionReader:HXURLSessionReader?
    private var completionHandler:((SECustomParser)->Void)?
    
    var channel:SECustomParsingChannel? {
        return self.stack.first as? SECustomParsingChannel
    }

    init(root:SECustomParserMode) {
        self.stack.append(root)
        self.root = root;
    }
    
    deinit {
        print("deinit SECustomXMLDecoder")
    }
    
    public func parse(file:URL, completion:@escaping (SECustomParser)->Void) throws {
        self.completionHandler = completion;
        self.parser = try HXSAXParser(mode:.XML, delegate:self)
        self.fileReader = HXDispatchIOFileReader(
            file:file,
            dataAvailable: { [weak self] (data) in
                do {
                    try self?.parser?.parseChunk(data:data)
                } catch let e{
                    print(e)
                }
            },
            completion: { [weak self] in
                self?.parser?.finishParsing()
            }
        )
    }
    
    public func parse(network:URL, completion:@escaping (SECustomParser)->Void) throws {
        self.completionHandler = completion;
        self.parser = try HXSAXParser(mode:.XML, delegate:self)
        self.urlSessionReader = HXURLSessionReader(
            url:network,
            dataAvailable: { [weak self] (data) in
                do {
                    try self?.parser?.parseChunk(data:data)
                } catch let e{
                    print(e)
                }
            },
            completion: { [weak self] in
                self?.parser?.finishParsing()
            }
        )
    }

    // MARK:HXSAXParserDelegate
    public func parser(_ parser: HXSAXParser, didStartElement elementName: String, attributes attributeDict: [String : String]) {
//        for _ in 0..<level {
//            print("    ", terminator:"")
//        }
//        print(elementName)

        self.level += 1

        if self.stack.count == 0 && elementName == root.tag {
            self.stack.append(self.root)
        } else if var currentEntity = self.stack.last {
            if var child = currentEntity.makeChildEntity(forTag:elementName) {
                for (key,value) in attributeDict {
                    child.setValue(value, forTag:nil, attribute:key)
                }
                self.stack.append(child);
            } else {
                for (key,value) in attributeDict {
                    currentEntity.setValue(value, forTag:elementName, attribute:key)
                }
                self.stack.hxSetLast(currentEntity)
            }
        }
    }

    public func parser(_ parser: HXSAXParser, foundCharacters string: String) {
        if ( self._isWhiteSpace(string) ) {
            return
        }
        if let text = self.text {
            self.text = text + string
        } else {
            self.text = string
        }
    }
    
    public func parser(_ parser: HXSAXParser, foundCDATA CDATABlock: Data) {
        self.cdata = CDATABlock;
    }

    public func parser(_ parser: HXSAXParser, didEndElement elementName: String) {
        self.level -= 1
        
        if self.stack.count > 1,
           let currentEntity = self.stack.last,
           currentEntity.tag == elementName
        {
            let closedEntity = self.stack.removeLast()
            self.stack.hxWithLast{$0.setChildEntity(closedEntity, forTag:elementName)}
            return
        }

        if let text = self.text {
            self.stack.hxWithLast{$0.setValue(text, forTag:elementName)}
            self.text = nil
        }
        
        if let data = self.cdata {
            self.stack.hxWithLast{$0.setData(data, forTag:elementName)}
            self.cdata = nil
        }
    }
    
    public func parserDidEndDocument(_ parser:HXSAXParser) {
        self.completionHandler?(self)
    }
    
    public func parser(_ parser: HXSAXParser, error: Error) {

    }

    // MARK: Private Methods
    private func _isWhiteSpace(_ string:String) -> Bool {
        for scalar in string.unicodeScalars {
            if !CharacterSet.whitespacesAndNewlines.contains(scalar) {
                return false
            }
        }
        return true
    }

}