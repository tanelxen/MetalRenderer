//
//  File.swift
//  
//
//  Created by Fedor Artemenkov on 22.09.2023.
//

import Foundation

enum FileUtils
{
    static func getURL(path: String) -> URL?
    {
        guard let filePathURL = URL(string: path) else {
            assertionFailure("Invalid filepath: \(path)")
            return nil
        }
        
        let directory = filePathURL.deletingLastPathComponent().path
        let filename = filePathURL.deletingPathExtension().lastPathComponent
        let filenameExtension = filePathURL.pathExtension
        
        guard let fileURL = Bundle.module.url(forResource: filename,
                                              withExtension: filenameExtension,
                                              subdirectory: directory)
        else {
            assertionFailure("Invalid filepath: \(path)")
            return nil
        }
        
        return fileURL
    }
}
