//
//  Q3EntityParser.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 07.02.2022.
//

import Foundation

fileprivate let openBrace = CharacterSet.init(charactersIn: "{")
fileprivate let closeBrace = CharacterSet.init(charactersIn: "}")
fileprivate let quote = CharacterSet.init(charactersIn: "\"")

class Q3EntityParser
{
    let scanner: Scanner

    init(entitiesString: String)
    {
        scanner = Scanner(string: entitiesString)
    }

    func parse() -> Array<Dictionary<String, String>>
    {
        var entities = Array<Dictionary<String, String>>()

        while scanner.scanCharacters(from: openBrace, into: nil)
        {
            entities.append(parseEntity())
        }

        return entities
    }

    private func parseEntity() -> Dictionary<String, String>
    {
        var entity = Dictionary<String, String>()

        while !scanner.scanCharacters(from: closeBrace, into: nil)
        {
            var rawKey: NSString?
            var rawValue: NSString?

            scanner.scanCharacters(from: quote, into: nil)
            scanner.scanUpToCharacters(from: quote, into: &rawKey)
            scanner.scanString("\" \"", into: nil)
            scanner.scanUpToCharacters(from: quote, into: &rawValue)
            scanner.scanCharacters(from: quote, into: nil)

            if let key = rawKey, let value = rawValue
            {
                entity[key as String] = value as String
            }
        }

        return entity
    }
}
