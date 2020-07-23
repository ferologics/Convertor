import XCTest
import FileKit

@testable import Convertor

@available(iOS 10.0, *)
final class ConvertorTests: XCTestCase {
    
    // MARK: Properties
    
    private lazy var convertor = Convertor(delegate: self)
    private lazy var activeConversions: [String:Convertor.OutputFormat] = [:]
    private lazy var conversionExpectation = XCTestExpectation()
    private lazy var progressExpectation = XCTestExpectation()
    private lazy var cancelExpecatation = XCTestExpectation()
    
    // MARK: Life cycle
    
    override func tearDownWithError() throws {
        activeConversions = [:]
    }
    
    // MARK: - Tests
    
    func testConvertFile() throws {
        // GIVEN
        let fileName = "test"
        let filePath = Path(fileName + ".shapr")
        let file = File<Data>(path: filePath)
        let format: Convertor.OutputFormat = .obj
        
        // WHEN
        self.activeConversions[file.name] = format
        try self.convertor.convert(file: file, to: format)
        
        // THEN
        wait(for: [conversionExpectation], timeout: 30)
    }
    
    func testConvertFiles() throws {
        // GIVEN
        let fileNames = ["test", "no", "test", "me"]
        let filePaths = fileNames.map { Path($0 + ".shapr") }
        let files = filePaths.map { File<Data>(path: $0) }
        let format: Convertor.OutputFormat = .obj
        conversionExpectation.expectedFulfillmentCount = files.count
        
        // WHEN
        for file in files {
            self.activeConversions[file.name] = format
            try self.convertor.convert(file: file, to: format)
        }
        
        // THEN
        wait(for: [conversionExpectation], timeout: 30)
    }
    
    func testFailConvertFile() throws {
        // GIVEN
        let fileName = "test"
        let filePath = Path(fileName + ".shaper")
        let file = File<Data>(path: filePath)
        let format: Convertor.OutputFormat = .obj
        
        // THEN
        XCTAssertThrowsError(try self.convertor.convert(file: file, to: format))
    }
    
    func testFailConvertFiles() throws {
        // GIVEN
        let fileNames = ["test.shapr", "no.shaper", "test.shapr", "me"]
        let filePaths = fileNames.map { Path($0) }
        let files = filePaths.map { File<Data>(path: $0) }
        let format: Convertor.OutputFormat = .obj
        
        // THEN
        XCTAssertThrowsError(try self.convertor.convert(files: files, to: format))
    }
    
    func testProgressUpdate() throws {
        // GIVEN
        let fileName = "test"
        let filePath = Path(fileName + ".shapr")
        let file = File<Data>(path: filePath)
        let format: Convertor.OutputFormat = .obj
        
        // WHEN
        try self.convertor.convert(file: file, to: format)
        
        // THEN
        wait(for: [progressExpectation], timeout: 30)
    }
    
    func testFileConversionCancel() throws {
        // GIVEN
        let fileName = "test"
        let filePath = Path(fileName + ".shapr")
        let file = File<Data>(path: filePath)
        let format: Convertor.OutputFormat = .obj
        
        // WHEN
        self.activeConversions[file.name] = format
        try self.convertor.convert(file: file, to: format)
        
        // THEN
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
            self.convertor = Convertor(delegate: self)
        }
        wait(for: [cancelExpecatation], timeout: 10)
    }
    
    func testFilesConversionCancel() throws {
        // GIVEN
        let fileNames = ["test", "no", "test", "me"]
        let filePaths = fileNames.map { Path($0 + ".shapr") }
        let files = filePaths.map { File<Data>(path: $0) }
        let format: Convertor.OutputFormat = .obj
        conversionExpectation.expectedFulfillmentCount = files.count
        
        // WHEN
        for file in files {
            self.activeConversions[file.name] = format
            try self.convertor.convert(file: file, to: format)
        }
        
        // THEN
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
            self.convertor = Convertor(delegate: self)
        }
        wait(for: [cancelExpecatation], timeout: 10)
    }

    static var allTests = [
        ("testConvertFile", testConvertFile),
        ("testConvertFiles", testConvertFiles),
        ("testFailConvertFile", testFailConvertFile),
        ("testFailConvertFiles", testFailConvertFiles),
        ("testProgressUpdate", testProgressUpdate),
        ("testFileConversionCancel", testFileConversionCancel),
        ("testFilesConversionCancel", testFilesConversionCancel),
    ]
}

@available(iOS 10.0, *)
extension ConvertorTests: ConversionDelegate {
    func didUpdateProgress(of file: File<Data>, to value: Float) {
        print("Progress of file '\(file.name)':  \(value)% ...")
        progressExpectation.fulfill()
    }
    
    func didConvert(file: File<Data>, to convertedFile: File<Data>) {
        if let format = activeConversions[file.name] {
            XCTAssertEqual(format.rawValue, convertedFile.pathExtension)
            conversionExpectation.fulfill()
        }
    }
    
    func didCancelConversion(of file: File<Data>) {
        cancelExpecatation.fulfill()
    }
}
