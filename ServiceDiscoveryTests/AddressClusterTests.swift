import Foundation
import XCTest
@testable import ServiceDiscovery

class AddressClusterTests: XCTestCase {

    override func setUp() {
        AddressCluster.flushClusters()
    }

    func testFactory() {
        let cluster = AddressCluster.from(addresses: ["2", "3", "z", "1"], hostnames: ["host"])
        XCTAssertEqual("1", cluster.displayAddress)
        XCTAssertEqual(["1", "2", "3", "z", "host"], cluster.sorted)
    }

    func testDifferentCluster() {
        let cluster1 = AddressCluster.from(addresses: ["1", "2"], hostnames: ["host"])
        let cluster2 = AddressCluster.from(addresses: ["3", "4"], hostnames: [])
        XCTAssertFalse(cluster1 == cluster2)
    }

    func testGrowCluster() {
        let cluster1 = AddressCluster.from(addresses: ["1", "2"], hostnames: ["host"])
        let cluster2 = AddressCluster.from(addresses: ["2", "3"], hostnames: [])
        XCTAssertTrue(cluster1 == cluster2) // equal
        XCTAssertTrue(cluster1 === cluster2) // same instances
    }

    func testMergeCluster() {
        // Create 2 non-overlapping clusters
        let cluster1 = AddressCluster.from(addresses: ["1", "2"], hostnames: ["host"])
        let cluster2 = AddressCluster.from(addresses: ["3", "4"], hostnames: [])
        XCTAssertFalse(cluster1 == cluster2)

        // Add new evidence that will cause those clusters to overlap (and so they are now the same cluster)
        let cluster3 = AddressCluster.from(addresses: ["2", "3"], hostnames: [])
        XCTAssertTrue(cluster1 == cluster2)
        XCTAssertTrue(cluster1 == cluster3)
        XCTAssertFalse(cluster1 === cluster2) // still different instances
        XCTAssertTrue(cluster1 === cluster3 || cluster2 == cluster3) // new cluster is one of the existing clusters
    }

}
