//
//  File.swift
//  
//  Convertor
//  Created by Frantisek Hetes on 18/07/2020.
//

import Foundation
import FileKit

@available(iOS 10.0, *)
final class ConversionOperation: Operation {
     
    // MARK: Private properties
    
    private let delegate: ConversionDelegate?
    private let file: File<Data>
    private let outputFormat: Convertor.OutputFormat
    private var convertedFile: File<Data>!
    
    // MARK: - Life cycle
    
    init(delegate: ConversionDelegate?, file: File<Data>, outputFormat: Convertor.OutputFormat) {
        self.delegate = delegate
        self.file = file
        self.outputFormat = outputFormat
    }
    
    // MARK: - Operation API
    
    override func start() {
        
        // *** set up state ***
        
        var progress = 0
        let duration = Int.random(in: 5...25)
        
        // *** schedule timer ***
        
        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            progress += 1
            if progress == duration {
                timer.invalidate()
                self.finishConversion()
            } else {
                let value = Float(progress)/Float(duration)
                self.delegate?.didUpdateProgress(
                    of: self.file,
                    with: self.outputFormat,
                    to: value
                )
            }
        }
        
        RunLoop.current.run()
    }
    
    override func cancel() {
        delegate?.didCancelConversion(of: file, to: outputFormat)
    }
    
    // MARK: - Helpers
    
    private func finishConversion() {
        let convertedFile = File<Data>(path: file.path)
        convertedFile.pathExtension = outputFormat.rawValue
        delegate?.didConvert(file: file, to: convertedFile)
    }
}
