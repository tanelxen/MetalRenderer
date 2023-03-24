//
//  Audio.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 25.03.2023.
//

import AVFoundation
import Accelerate

enum AudioEngine
{
    private static var engine: AVAudioEngine!
    
    private static var players: [AVAudioFormat: AVAudioPlayerNode] = [:]
    private static var sounds: [String: AVAudioFile] = [:]
    
    private static let player = AVAudioPlayerNode()
    
    static func play(file: String)
    {
        var sound = sounds[file]
        
        if sound == nil
        {
            //first we need the resource url for our file
            guard let url = Bundle.main.url(forResource: file, withExtension: nil) else {
                print("\(file) not found")
                return
            }
            
            do {
                //player nodes have a few ways to play-back music, the easiest way is from an AVAudioFile
                let audioFile = try AVAudioFile(forReading: url)
                
                //audio always has a format, lets keep track of what the format is as an AVAudioFormat
                let format = audioFile.processingFormat
                print(format)
                
                sound = audioFile
                sounds[file] = audioFile
                
            } catch let error {
                print(error.localizedDescription)
            }
        }
        
        if let audioFile = sound
        {
            let format = audioFile.processingFormat
            var player = players[format]
            
            if player == nil
            {
                player = AVAudioPlayerNode()
                
                engine.attach(player!)
                engine.connect(player!, to: engine.mainMixerNode, format: format)
                
                players[format] = player
            }
            
            player?.scheduleFile(audioFile, at: nil, completionHandler: nil)
            player?.play()
        }
    }
    
    static func start()
    {
        let engine = AVAudioEngine()
        
        _ = engine.mainMixerNode
        
        engine.prepare()
        
        do
        {
            try engine.start()
        }
        catch
        {
            print(error)
        }
        
        Self.engine = engine
    }
}
