import XCTest
import com_awareframework_ios_sensor_linearaccelerometer
import com_awareframework_ios_core
import GRDB

final class Tests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
    }
    
    func testControllers() {
        let sensor = LinearAccelerometerSensor(LinearAccelerometerSensor.Config().apply { config in
            config.debug = true
        })
        
        let expectSetLabel = expectation(description: "set label")
        let newLabel = "hello"
        let labelObserver = NotificationCenter.default.addObserver(forName: .actionAwareLinearAccelerometerSetLabel,
                                                                   object: nil,
                                                                   queue: .main) { notification in
            XCTAssertEqual((notification.userInfo as? [String: String])?[LinearAccelerometerSensor.EXTRA_LABEL], newLabel)
            expectSetLabel.fulfill()
        }
        sensor.set(label: newLabel)
        wait(for: [expectSetLabel], timeout: 5)
        NotificationCenter.default.removeObserver(labelObserver)
        
        let expectSync = expectation(description: "sync")
        let syncObserver = NotificationCenter.default.addObserver(forName: .actionAwareLinearAccelerometerSync,
                                                                  object: nil,
                                                                  queue: .main) { _ in
            expectSync.fulfill()
        }
        sensor.sync()
        wait(for: [expectSync], timeout: 5)
        NotificationCenter.default.removeObserver(syncObserver)
        
        #if targetEnvironment(simulator)
        print("Start and stop controller tests require a real device.")
        #else
        let expectStart = expectation(description: "start")
        let startObserver = NotificationCenter.default.addObserver(forName: .actionAwareLinearAccelerometerStart,
                                                                   object: nil,
                                                                   queue: .main) { _ in
            expectStart.fulfill()
        }
        sensor.start()
        wait(for: [expectStart], timeout: 5)
        NotificationCenter.default.removeObserver(startObserver)
        
        let expectStop = expectation(description: "stop")
        let stopObserver = NotificationCenter.default.addObserver(forName: .actionAwareLinearAccelerometerStop,
                                                                  object: nil,
                                                                  queue: .main) { _ in
            expectStop.fulfill()
        }
        sensor.stop()
        wait(for: [expectStop], timeout: 5)
        NotificationCenter.default.removeObserver(stopObserver)
        #endif
    }
    
    func testLinearAccelerometerData() {
        let data = LinearAccelerometerData(x: 1,
                                           y: 2,
                                           z: 3,
                                           timestamp: 4,
                                           eventTimestamp: 5,
                                           accuracy: 6,
                                           label: "test")
        let dict = data.toDictionary()
        XCTAssertEqual(dict["x"] as? Double, 1)
        XCTAssertEqual(dict["y"] as? Double, 2)
        XCTAssertEqual(dict["z"] as? Double, 3)
        XCTAssertEqual(dict["timestamp"] as? Int64, 4)
        XCTAssertEqual(dict["eventTimestamp"] as? Int64, 5)
        XCTAssertEqual(dict["accuracy"] as? Int, 6)
        XCTAssertEqual(dict["label"] as? String, "test")
    }
    
    func testConfig() {
        let samplingFrequencyHz = 1
        let threshold = 0.5
        let saveIntervalSeconds = 1.0
        let config: [String: Any] = ["samplingFrequencyHz": samplingFrequencyHz, "threshold": threshold, "saveIntervalSeconds": saveIntervalSeconds]
        
        var sensor = LinearAccelerometerSensor(LinearAccelerometerSensor.Config(config))
        XCTAssertEqual(samplingFrequencyHz, sensor.CONFIG.samplingFrequencyHz)
        XCTAssertEqual(threshold, sensor.CONFIG.threshold)
        XCTAssertEqual(saveIntervalSeconds, sensor.CONFIG.saveIntervalSeconds)
        
        sensor = LinearAccelerometerSensor(LinearAccelerometerSensor.Config().apply { config in
            config.samplingFrequencyHz = samplingFrequencyHz
            config.threshold = threshold
            config.saveIntervalSeconds = saveIntervalSeconds
        })
        XCTAssertEqual(samplingFrequencyHz, sensor.CONFIG.samplingFrequencyHz)
        XCTAssertEqual(threshold, sensor.CONFIG.threshold)
        XCTAssertEqual(saveIntervalSeconds, sensor.CONFIG.saveIntervalSeconds)
        
        sensor = LinearAccelerometerSensor()
        sensor.CONFIG.set(config: config)
        XCTAssertEqual(samplingFrequencyHz, sensor.CONFIG.samplingFrequencyHz)
        XCTAssertEqual(threshold, sensor.CONFIG.threshold)
        XCTAssertEqual(saveIntervalSeconds, sensor.CONFIG.saveIntervalSeconds)
    }
    
    func testSQLiteStorage() {
        let sensor = LinearAccelerometerSensor(LinearAccelerometerSensor.Config().apply { config in
            config.dbType = .sqlite
            config.dbPath = "linear_accelerometer_unit_test"
            config.dbTableName = LinearAccelerometerData.TABLE_NAME
        })

        guard let sqliteEngine = sensor.dbEngine as? SQLiteEngine,
              let queue = sqliteEngine.getSQLiteInstance() else {
            return XCTFail("SQLiteEngine should be initialized")
        }

        // Drop and recreate table to ensure schema is current
        try? queue.write { db in
            try db.execute(sql: "DROP TABLE IF EXISTS \(LinearAccelerometerData.TABLE_NAME)")
        }
        try? LinearAccelerometerData.createTable(queue: queue)

        let engine = sensor.dbEngine!
        engine.removeAll()
        engine.save([
            LinearAccelerometerData(x: 1, y: 2, z: 3, timestamp: 4, eventTimestamp: 5, accuracy: 6)
        ])
        
        let results = engine.fetch(filter: nil, limit: nil)
        XCTAssertEqual(results?.count, 1)
        XCTAssertEqual(results?.first?["x"] as? Double, 1)
        XCTAssertEqual(results?.first?["eventTimestamp"] as? Int64, 5)
    }
    
    func testSyncModule() throws {
        throw XCTSkip("Sync integration test requires external server configuration and is excluded from unit tests.")
    }
}
