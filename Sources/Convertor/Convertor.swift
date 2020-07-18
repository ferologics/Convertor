import FileKit
import Foundation

@available(iOS 10.0, *)
public class Convertor {
    
    // MARK: Private Properties
    
    private var conversionTimers: [String:Timer] = [:]
    private lazy var lock: pthread_rwlock_t = {
        var lock = pthread_rwlock_t()
        pthread_rwlock_init(&lock, nil)
        return lock
    }()
    
    // MARK: Public Properties
    
    public var delegate: ConversionDelegate?
    
    
    // MARK: Life cycle
    
    public convenience init(delegate: ConversionDelegate) {
        self.init()
        self.delegate = delegate
    }
    
    deinit {
        pthread_rwlock_rdlock(&lock)
        for timer in conversionTimers.values {
            timer.invalidate()
        }
        pthread_rwlock_unlock(&lock)
        pthread_rwlock_destroy(&lock)
    }
    
    // MARK: - Public API
    
    public func convert(file: File<Data>, to format: OutputFormat) throws {
        guard file.pathExtension == InputFormat.shapr.rawValue else {
            throw Error.invalidInputFormat(of: file)
        }
        
        print("read lock:", pthread_rwlock_tryrdlock(&lock))
        guard !conversionTimers.keys.contains(file.name) else {
            print("unlock:", pthread_rwlock_unlock(&lock))
            throw Error.conversionAlreadyInProgress(of: file)
        }
        print("unlock:", pthread_rwlock_unlock(&lock))
        
        internalConvert(file: file, to: format)
    }
    
    public func convert(files: [File<Data>], to format: OutputFormat) throws {
        for file in files {
            try convert(file: file, to: format)
        }
    }
    
    // MARK: - Internal API
    
    func internalConvert(file: File<Data>, to format: OutputFormat) {
        // set up state
        var progress = 0
        let duration = Int.random(in: 5...25)
        // schedule timer
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            progress += 1
            if progress == duration {
                timer.invalidate()
                self.finishConversion(of: file, to: format)
            } else {
                let value = Double(progress)/Double(duration)
                self.delegate?.didUpdateProgress(of: file, to: value)
            }
        }
 
        
        let error = pthread_rwlock_trywrlock(&lock)
        if error == 0 {
            conversionTimers[file.name] = timer
            print("unlock:", pthread_rwlock_unlock(&lock))
        } else if error == EDEADLK {
            conversionTimers[file.name] = timer
            print("unlock:", pthread_rwlock_unlock(&lock))
        } else {
            // TODO: wait until we have lock
            let error = pthread_rwlock_trywrlock(&lock)
            conversionTimers[file.name] = timer
            print("unlock:", pthread_rwlock_unlock(&lock))
            print("resource busy error:", error)
        }
        
        // print("unlock:", pthread_rwlock_unlock(&lock))
        RunLoop.current.run()
    }
    
    func finishConversion(of file: File<Data>, to format: OutputFormat) {
        let convertedFile = File<Data>(path: file.path)
        convertedFile.pathExtension = format.rawValue
        delegate?.didConvert(file: file, to: convertedFile)
        print("write lock:", pthread_rwlock_trywrlock(&lock))
        conversionTimers.removeValue(forKey: file.name)
        print("unlock:", pthread_rwlock_unlock(&lock))
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
    }
}

// MARK: - Error handling

@available(iOS 10.0, *)
extension Convertor {
    enum Error: Swift.Error {
        case invalidInputFormat(of: File<Data>)
        case conversionAlreadyInProgress(of: File<Data>)
    }
}

// MARK: - Delegate

public protocol ConversionDelegate {
    func didConvert(file: File<Data>, to convertedFile: File<Data>)
    func didUpdateProgress(of file: File<Data>, to value: Double)
}
