import FileKit
import Foundation

@available(iOS 10.0, *)
public class Convertor {
    
    // MARK: Private Properties
    
    private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "ConvertorOperationQueue"
        return queue
    }()
    
    // MARK: Public Properties
    
    public var delegate: ConversionDelegate?
    
    // MARK: Life cycle
    
    public convenience init(delegate: ConversionDelegate) {
        self.init()
        self.delegate = delegate
    }
    
    deinit {
        operationQueue.operations.forEach { $0.cancel() }
    }
    
    // MARK: - Public API
    
    public func convert(file: File<Data>, to format: OutputFormat) throws {
        guard file.pathExtension == InputFormat.shapr.rawValue else {
            throw Error.invalidInputFormat(of: file)
        }
        
        internalConvert(file: file, to: format)
    }
    
    public func convert(files: [File<Data>], to format: OutputFormat) throws {
        for file in files {
            try convert(file: file, to: format)
        }
    }
    
    // MARK: - Internal API
    
    func internalConvert(file: File<Data>, to format: OutputFormat) {
        let operation = ConversionOperation(delegate: delegate, file: file, outputFormat: format)
        operationQueue.addOperation(operation)
    }
}

// MARK: - Supported Formats

@available(iOS 10.0, *)
extension Convertor {
    public enum InputFormat: String {
        case shapr
    }
    
    public enum OutputFormat: String {
        case step, stl, obj
        
        public static let allCases: Set<OutputFormat> = [.step, .stl, .obj]
        
        public static let allCasesStrings: Set<String> = Set(OutputFormat.allCases.map { $0.rawValue })
        
        public var description: String {
            switch self {
            case .step: return "STEP-File"
            case .stl: return "Standard Triangle Language"
            case .obj: return "3D Model Format"
            }
        }
    }
}

// MARK: - Error Handling

@available(iOS 10.0, *)
extension Convertor {
    public enum Error: Swift.Error {
        case invalidInputFormat(of: File<Data>)
    }
}

// MARK: - Delegate

public protocol ConversionDelegate {
    func didConvert(file: File<Data>, to convertedFile: File<Data>)
    func didUpdateProgress(of file: File<Data>, with outputFormat: Convertor.OutputFormat, to value: Float)
    func didCancelConversion(of file: File<Data>)
}
