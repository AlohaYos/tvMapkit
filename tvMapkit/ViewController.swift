//
//  ViewController.swift
//  tvMapkit
//
//  Created by Yos Hashimoto
//  Copyright © 2016年 NewtonJapan. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, MKMapViewDelegate {
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var searchText: UITextField!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var routeInfoLabel: UILabel!
	@IBOutlet weak var initButton: UIButton!
	@IBOutlet weak var searchButton: UIButton!
	@IBOutlet weak var navigateButton: UIButton!
	
	var mapItems = NSMutableArray()
	var response:MKDirectionsResponse?
	var mapItemFrom:MKMapItem?
	var mapItemTo:MKMapItem?
	var routeIndex:Int = 0
	var selectedRoute:MKRoute?
	
	// MARK: - View setup
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		initMapRegion()

		mapView.mapType = .Standard
		
		mapView.userInteractionEnabled = false
	}

	override func viewWillAppear(animated: Bool) {
		initMapRegion()
		
		searchButton.becomeFirstResponder()
	}
	
	override func viewDidAppear(animated: Bool) {
		mapView.userInteractionEnabled = true
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	
	// MARK: - User Action
	
	@IBAction func initButtonPushed(sender: AnyObject) {
		initMapRegion()
	}

	@IBAction func searchButtonPushed(sender: AnyObject) {
		
		searchText.resignFirstResponder()
		
		let request = MKLocalSearchRequest()
		request.naturalLanguageQuery = searchText.text
		request.region = mapView.region
		let search = MKLocalSearch(request: request)

		search.startWithCompletionHandler({ (response, error) -> Void in
			self.mapItems.removeAllObjects()
			self.mapView.removeAnnotations(self.mapView.annotations)
			
			for item:MKMapItem in response!.mapItems {
				let point = MKPointAnnotation()
				
				point.coordinate = item.placemark.coordinate
				point.title = item.placemark.name
				point.subtitle = item.phoneNumber
				
				self.mapView.addAnnotation(point)
				self.mapItems.addObject(item)
			}
			
			self.mapView.showAnnotations(self.mapView.annotations, animated: true)
			self.mapItemFrom = nil
			self.mapItemTo = nil
			
			self.tableView.reloadData()
		})
	}
	
	@IBAction func execNavigation(sender: AnyObject) {
		openNaviPageWithRoute()
	}

	// MARK: - TableView job

	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return mapItems.count
	}

	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 80
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Cell")
		
		let item = mapItems[indexPath.row] as! MKMapItem

		cell?.detailTextLabel?.font = UIFont.systemFontOfSize(48)
		cell?.detailTextLabel?.font = UIFont.systemFontOfSize(30)
		cell?.textLabel?.text = item.name
		cell?.detailTextLabel!.text = item.placemark.title
		
		return cell!
	}
	
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		let item = mapItems[indexPath.row] as! MKMapItem
		
		// find the POI
		let ann = mapView.annotations as! [MKPointAnnotation]
		
		for annotation:MKPointAnnotation in ann {
			if ((annotation.coordinate.latitude==item.placemark.coordinate.latitude) && (annotation.coordinate.longitude==item.placemark.coordinate.longitude)) {
				// Show annotation
				mapView.selectAnnotation(annotation, animated: true)
				
				// find route
				if mapItemFrom == nil {
					mapItemFrom = item
				}
				else {
					if mapItemTo == nil {
						mapItemTo = item
					}
					else {
						if mapItemTo == item {
							routeIndex += 1;
						}
						else {
							routeIndex = 0
							mapItemFrom = mapItemTo
							mapItemTo = item
						}
					}
					findDirectionFrom(mapItemFrom!, to: mapItemTo!, index: routeIndex)
				}
				break
			}
		}
	}
	
	// MARK: - Map job
	
	func initMapRegion() {
		let center = CLLocationCoordinate2D(latitude: 21.500353, longitude: -157.959694)
		let span = MKCoordinateSpanMake(0.520984, 0.603312)
		let region = MKCoordinateRegionMake(center, span)
		mapView.region = region
	}
	
	func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
		let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
		renderer.lineWidth = 5.0
		renderer.strokeColor = UIColor.blueColor().colorWithAlphaComponent(0.7)
		
		return renderer
	}
	
	
	// MARK: - Route job
	
	func findDirectionFrom(source:MKMapItem, to destination:MKMapItem, index routeIndex:Int) {

		let request = MKDirectionsRequest()
		request.source = source
		request.destination = destination
		request.requestsAlternateRoutes = true

		let directions = MKDirections(request: request)
		directions.calculateDirectionsWithCompletionHandler({ (response_, error) ->Void in
			if error == nil {
				self.response = response_
				print("route count \(response_!.routes.count)")
				
				// get route of index number
				let routeNo = self.routeIndex % (response_?.routes.count)!
				let route:MKRoute = (response_?.routes[routeNo])!
				self.selectedRoute = route
				
				for step:MKRouteStep in route.steps {
					print("\(step.instructions)")
					print("\(step.notice)")
				}
				
				let distanceFormat = MKDistanceFormatter()
				let distance = distanceFormat.stringFromDistance(route.distance)
				let time = String(format: "%.0lf", route.expectedTravelTime/60)
				print("via " + route.name)
				print("\(distance) - arrive in \(time) min")
				
				// drow on map
				self.mapView.removeOverlays(self.mapView.overlays)
				self.mapView.addOverlay(route.polyline, level: .AboveRoads)
				
				// display route information
				self.routeInfoLabel.text = String(format: "%@ via %@: Arrive in %@ min", distance, route.name, time)
			}
		})
		
		// TODO:
	}
	
	// MARK: - Segue job
	
	func openNaviPageWithRoute() {
		performSegueWithIdentifier("showNaviPage", sender: self)
	}
	
	func closeNaviPage() {
		dismissViewControllerAnimated(true, completion: nil)
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "showNaviPage" {
			let nextViewController = segue.destinationViewController as? NaviViewController
			nextViewController!.delegate_ = self
			nextViewController?.mapItemTo = mapItemTo
			nextViewController!.selectedRoute = selectedRoute
		}
	}


}

