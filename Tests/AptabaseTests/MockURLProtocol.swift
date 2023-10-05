import XCTest

class MockURLProtocol: URLProtocol {
    static var requestCount: Int = 0
    static var responseStatusCode:  Int = 0
    
    static func reset() {
        requestCount = 0
        responseStatusCode = 0
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        MockURLProtocol.requestCount += 1;
        
        let data = "{}".data(using: .utf8)!
        let response = HTTPURLResponse(url: request.url!, statusCode: MockURLProtocol.responseStatusCode, httpVersion: nil, headerFields: nil)!
        self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        self.client?.urlProtocol(self, didLoad: data)
        self.client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}
