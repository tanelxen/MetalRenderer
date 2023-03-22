//
//  ResourceManager.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 22.03.2023.
//

import Foundation

enum ResourceManager
{
    static func getURL(for path: String) -> URL?
    {
        let pathURL = URL(string: path)!

        let dir = pathURL.deletingLastPathComponent().path
        let name = pathURL.deletingPathExtension().lastPathComponent
        let ext = pathURL.pathExtension

        guard let fileURL = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: dir)
        else
        {
            print("Invalid filepath: \(path)")
            return nil
        }

        return fileURL
    }
    
    static func getData(for path: String) -> Data?
    {
        guard let url = getURL(for: path)
        else
        {
            print("Invalid url for filepath: \(path)")
            return nil
        }
        
        guard let data = try? Data(contentsOf: url)
        else
        {
            print("Invalid data for filepath: \(path)")
            return nil
        }
        
        return data
    }
    
    private static let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    static func URLInDocuments(for path: String) -> URL
    {
        return documentDirectory.appendingPathComponent(path)
    }
    
    static func dataInDocuments(for path: String) throws -> Data
    {
        let url = URLInDocuments(for: path)
        return try Data(contentsOf: url)
    }
}
