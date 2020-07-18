import XCTest
import FileKit

@testable import Convertor

@available(iOS 10.0, *)
final class ConvertorTests: XCTestCase {
    
    // MARK: Properties
    
    private lazy var convertor = Convertor(delegate: self)
    private var activeConversions: [String:Convertor.OutputFormat] = [:]
    private let queue = DispatchQueue(label: "ConversionTestQueue", attributes: .concurrent)
    private lazy var lock = pthread_rwlock_t()
    private lazy var expectation = XCTestExpectation()
    
    // MARK: Life cycle
    
    override func setUpWithError() throws {
        pthread_rwlock_init(&lock, nil)
    }
    
    override func tearDownWithError() throws {
        activeConversions = [:]
        pthread_rwlock_destroy(&lock)
    }
    
    // MARK: - Tests
    
    func testConvertFile() {
        // GIVEN
        let fileName = "test"
        let filePath = Path(fileName + ".shapr")
        let file = File<Data>(path: filePath)
        let format: Convertor.OutputFormat = .obj
        
        // WHEN
        self.activeConversions[file.name] = format
        queue.async {
            try! self.convertor.convert(file: file, to: format)
        }
        
        // THEN
        wait(for: [expectation], timeout: 30)
    }
    
    func testConvertFiles() {
        // GIVEN
        let fileNames = ["test", "no", "test", "me"]
        let filePaths = fileNames.map { Path($0 + ".shapr") }
        let files = filePaths.map { File<Data>(path: $0) }
        let format: Convertor.OutputFormat = .obj
        expectation.expectedFulfillmentCount = files.count
        
        // WHEN
        for file in files {
            self.activeConversions[file.name] = format
            queue.async {
                try! self.convertor.convert(file: file, to: format)
            }
        }
        
        // THEN
        wait(for: [expectation], timeout: 30)
    }
    
    func testFailConvertFile() {
        // TODO: test convert file
    }
    
    func testFailConvertFiles() {
        // TODO: test convert file
    }
    
    func testProgressUpdate() {
        
    }

    static var allTests = [
        ("testConvertFile", testConvertFile),
        ("testConvertFiles", testConvertFiles),
        ("testFailConvertFile", testFailConvertFile),
        ("testFailConvertFiles", testFailConvertFiles),
        ("testProgressUpdate", testProgressUpdate),
    ]
}

@available(iOS 10.0, *)
extension ConvertorTests: ConversionDelegate {
    func didUpdateProgress(of file: File<Data>, to value: Double) {
        print("Progress of file '\(file.name)':  \(value)% ...")
    }
    
    func didConvert(file: File<Data>, to convertedFile: File<Data>) {
        pthread_rwlock_tryrdlock(&lock)
        if let format = activeConversions[file.name] {
            pthread_rwlock_unlock(&lock)
            XCTAssertEqual(format.rawValue, convertedFile.pathExtension)
            expectation.fulfill()
        } else {
            pthread_rwlock_unlock(&lock)
        }
    }
    
    func didFailToConvert(file: File<Data>, with error: Error) {
        
    }
}
