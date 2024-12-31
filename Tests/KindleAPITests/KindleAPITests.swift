//
//  KindleAPITests.swift
//  KindleAPITests
//
//  Created by Natik Gadzhi on 12/23/23.
//

import Foundation
import KindleAPI
import Testing

struct KindleAPITest {

    @Test func testRequestURLToHost() {
        let url = KindleEndpoint.booksListJSON(paginationToken: "").url
        let host = url.host()!
        #expect(host == "read.amazon.com")
    }

}
