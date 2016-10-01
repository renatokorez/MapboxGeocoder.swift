import XCTest
import OHHTTPStubs
import CoreLocation
@testable import MapboxGeocoder

class ReverseGeocodingTests: XCTestCase {
    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testValidReverseGeocode() {
        let expectation = self.expectation(description: "reverse geocode should return results")
        
        _ = stub(condition: isHost("api.mapbox.com")
            && isPath("/geocoding/v5/mapbox.places/-95.78558,37.13284.json")
            && containsQueryParams(["access_token": BogusToken])) { _ in
                let path = Bundle(for: type(of: self)).path(forResource: "reverse_valid", ofType: "json")
                return OHHTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }

        let geocoder = Geocoder(accessToken: BogusToken)
        var pointOfInterestPlacemark: Placemark?
        var placePlacemark: Placemark?
        let options = ReverseGeocodeOptions(location: CLLocation(latitude: 37.13284000, longitude: -95.78558000))
        let task = geocoder.geocode(options) { (placemarks, attribution, error) in
            XCTAssertEqual(placemarks?.count, 5, "reverse geocode should have 5 results")
            pointOfInterestPlacemark = placemarks![0]
            placePlacemark = placemarks![1]
            
            XCTAssertEqual(attribution, "NOTICE: © 2016 Mapbox and its suppliers. All rights reserved. Use of this data is subject to the Mapbox Terms of Service (https://www.mapbox.com/about/maps/). This response and the information it contains may not be retained.")
            
            expectation.fulfill()
        }
        XCTAssertNotNil(task)

        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, "Error: \(error)")
            XCTAssertEqual(task.state, URLSessionTask.State.completed)
        }
        
        XCTAssertEqual(pointOfInterestPlacemark?.description, "Jones Jerry", "reverse geocode should populate description")
        XCTAssertEqual(pointOfInterestPlacemark?.name, "Jones Jerry", "reverse geocode should populate name")
        XCTAssertEqual(pointOfInterestPlacemark?.qualifiedName, "Jones Jerry, 2850 CR 3100, Independence, Kansas 67301, United States", "reverse geocode should populate qualified name")
        XCTAssertEqual(pointOfInterestPlacemark?.location?.coordinate.latitude, 37.128003, "reverse geocode should populate location")
        XCTAssertEqual(pointOfInterestPlacemark?.location?.coordinate.longitude, -95.782951, "reverse geocode should populate location")
        XCTAssertEqual(pointOfInterestPlacemark?.scope, PlacemarkScope.pointOfInterest, "reverse geocode should populate scope")
        XCTAssertEqual(pointOfInterestPlacemark?.country?.code, "US", "reverse geocode should populate ISO country code")
        XCTAssertEqual(pointOfInterestPlacemark?.country?.name, "United States", "reverse geocode should populate country")
        XCTAssertEqual(pointOfInterestPlacemark?.postalCode?.name, "67301", "reverse geocode should populate postal code")
        XCTAssertEqual(pointOfInterestPlacemark?.administrativeRegion?.name, "Kansas", "reverse geocode should populate administrative region")
        XCTAssertNil(pointOfInterestPlacemark?.district?.name, "reverse geocode in the United States should not populate district")
        XCTAssertEqual(pointOfInterestPlacemark?.place?.name, "Independence", "reverse geocode should populate place")
        XCTAssertNil(pointOfInterestPlacemark?.thoroughfare, "reverse geocode for POI should not populate thoroughfare")
        XCTAssertNil(pointOfInterestPlacemark?.subThoroughfare, "reverse geocode for POI should not populate sub-thoroughfare")
        
        XCTAssertNotNil(pointOfInterestPlacemark?.addressDictionary)
        let addressDictionary = pointOfInterestPlacemark?.addressDictionary
        XCTAssertEqual(addressDictionary?[MBPostalAddressStreetKey] as? String, "2850 CR 3100", "reverse geocode should populate street in address dictionary")
        XCTAssertEqual(addressDictionary?[MBPostalAddressCityKey] as? String, "Independence", "reverse geocode should populate city in address dictionary")
        XCTAssertEqual(addressDictionary?[MBPostalAddressStateKey] as? String, "Kansas", "reverse geocode should populate state in address dictionary")
        XCTAssertEqual(addressDictionary?[MBPostalAddressCountryKey] as? String, "United States", "reverse geocode should populate country in address dictionary")
        XCTAssertEqual(addressDictionary?[MBPostalAddressISOCountryCodeKey] as? String, "US", "reverse geocode should populate ISO country code in address dictionary")
        
        let southWest = CLLocationCoordinate2D(latitude: 37.033229992893, longitude: -95.927990005645)
        let northEast = CLLocationCoordinate2D(latitude: 37.35632800706, longitude: -95.594628992671)
        let region = placePlacemark?.region as! RectangularRegion
        XCTAssertEqualWithAccuracy(region.southWest.latitude, southWest.latitude, accuracy: 0.000000000001)
        XCTAssertEqualWithAccuracy(region.southWest.longitude, southWest.longitude, accuracy: 0.000000000001)
        XCTAssertEqualWithAccuracy(region.northEast.latitude, northEast.latitude, accuracy: 0.000000000001)
        XCTAssertEqualWithAccuracy(region.northEast.longitude, northEast.longitude, accuracy: 0.000000000001)
    }

    func testInvalidReverseGeocode() {
        _ = stub(condition: isHost("api.mapbox.com")
            && isPath("/geocoding/v5/mapbox.places/0.00000,0.00000.json")
            && containsQueryParams(["access_token": BogusToken])) { _ in
                let path = Bundle(for: type(of: self)).path(forResource: "reverse_invalid", ofType: "json")
                return OHHTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let expectation = self.expectation(description: "reverse geocode execute completion handler for invalid query")
        let geocoder = Geocoder(accessToken: BogusToken)
        let options = ReverseGeocodeOptions(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
        let task = geocoder.geocode(options) { (placemarks, attribution, error) in
            XCTAssertEqual(placemarks?.count, 0, "reverse geocode should return no results for invalid query")
            
            XCTAssertEqual(attribution, "NOTICE: © 2016 Mapbox and its suppliers. All rights reserved. Use of this data is subject to the Mapbox Terms of Service (https://www.mapbox.com/about/maps/). This response and the information it contains may not be retained.")
            
            expectation.fulfill()
        }
        XCTAssertNotNil(task)

        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, "Error: \(error)")
            XCTAssertEqual(task.state, URLSessionTask.State.completed)
        }
    }
}
