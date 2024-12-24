//
//  FileManager.swift
//  sqeid
//
//  Created by Samuel Maynard on 22/10/24.
//

import Foundation

extension FileManager {
    
    func doesSoundFileExist(named soundName: String) -> Bool {
        if let soundPath = Bundle.main.path(forResource: soundName, ofType: nil) {
            return FileManager.default.fileExists(atPath: soundPath)
        }
        return false
    }
    
}
