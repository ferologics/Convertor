//
//  ConversionToken.swift
//  
//  Convertor
//  Created by Frantisek Hetes on 28/07/2020.
//

import Foundation

public final class ConversionToken {
    
    // MARK: - Private Properties
    
    private weak var operation: ConversionOperation?
    
    // MARK: - Public API
    
    init(with operation: ConversionOperation) {
        self.operation = operation
    }
    
    public func cancel() {
        operation?.cancel()
    }
}
