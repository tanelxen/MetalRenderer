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

        if let fileURL = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: dir)
        {
            return fileURL
        }
        
        guard let workingDir = UserDefaults.standard.url(forKey: "workingDir")
        else {
            return nil
        }
        
        let relativeAtWorkingDir = workingDir.appendingPathComponent(path)
        
        guard FileManager.default.fileExists(atPath: relativeAtWorkingDir.path)
        else {
            return nil
        }
        
        return relativeAtWorkingDir
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
    private static let libraryDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
    
    static func URLInDocuments(for path: String) -> URL
    {
        return documentDirectory.appendingPathComponent(path)
    }
    
    static func folderInDocuments(name: String) -> URL?
    {
        let url = documentDirectory.appendingPathComponent(name)
        
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
                return nil
            }
        }
        
        return url
    }
    
    static func getOrCreateFolder(named: String, directory: URL) -> URL?
    {
        let url = directory.appendingPathComponent(named)
        
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
                return nil
            }
        }
        
        return url
    }
    
    static func pathInPreferences(for path: String) -> String
    {
        let preferences = libraryDirectory.appendingPathComponent("Preferences")
        return preferences.appendingPathComponent(path).path
    }
    
    static func dataInDocuments(for path: String) throws -> Data
    {
        let url = URLInDocuments(for: path)
        return try Data(contentsOf: url)
    }
}
