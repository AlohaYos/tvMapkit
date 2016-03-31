//
//  NaviViewController.swift
//  tvMapkit
//
//  Created by Yos Hashimoto
//  Copyright © 2016年 NewtonJapan. All rights reserved.
//

import UIKit
import MapKit

class NaviViewController: UIViewController {
	
	// MARK: - Propaties
	
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var backButton: UIButton!
	@IBOutlet weak var destinationLabel: UILabel!
	
	var mapItemTo:MKMapItem?
	var selectedRoute:MKRoute?
	var delegate_:ViewController?
	var stepPoint:CLLocationCoordinate2D?

	// MARK: - View setup

    override func viewDidLoad() {
        super.viewDidLoad()

		initMapRegion()
		
		destinationLabel.text = "Destination: " + (mapItemTo?.name)!
		
		mapView.mapType = .Standard
		mapView.showsBuildings = true
		mapView.showsPointsOfInterest = true
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		let step:MKRouteStep = (selectedRoute?.steps[0])!
		moveMapCameraTo(step)

		mapView.userInteractionEnabled = false
		tableView.becomeFirstResponder()
	}
	
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
	// MARK: - User action
	
	@IBAction func backButtonPushed(sender: AnyObject) {
		delegate_?.closeNaviPage()
	}
	
	// MARK: - TableView job
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return (selectedRoute?.steps.count)!
	}
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 80
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("NaviCell")
		
		let step:MKRouteStep = (selectedRoute?.steps[indexPath.row])!

		cell?.detailTextLabel?.font = UIFont.systemFontOfSize(48)
		cell?.detailTextLabel?.font = UIFont.systemFontOfSize(30)
		cell?.textLabel?.text = step.instructions
		cell?.detailTextLabel?.text = step.notice
		
		return cell!
	}
	
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		let step:MKRouteStep = (selectedRoute?.steps[indexPath.row])!
		moveMapCameraTo(step)
	}
	
	// MARK: - Map job
	
	func initMapRegion() {
		let center = CLLocationCoordinate2D(latitude: 21.500353, longitude: -157.959694)
		let span = MKCoordinateSpanMake(0.520984, 0.603312)
		let region = MKCoordinateRegionMake(center, span)
		mapView.region = region
	}

	func moveMapCameraTo(step:MKRouteStep) {
		
		let ground:CLLocationCoordinate2D
		let eye:CLLocationCoordinate2D
		
		if tableView.indexPathsForSelectedRows == nil {
			ground = step.polyline.coordinate
			eye = ground
		}
		else {
			ground = step.polyline.coordinate
			eye = stepPoint!
		}
		
		let myCamera = MKMapCamera(lookingAtCenterCoordinate: ground, fromEyeCoordinate: eye, eyeAltitude: 100)
		mapView.setCamera(myCamera, animated: true)
		stepPoint = ground
		
		let distanceFormat = MKDistanceFormatter()
		let distance = distanceFormat.stringFromDistance(step.distance)
		
		let annotation = MKPointAnnotation()
		annotation.coordinate = ground
		annotation.title = distance
		
		mapView.removeAnnotations(mapView.annotations)
		mapView.addAnnotation(annotation)
		mapView.selectAnnotation(annotation, animated: true)
	}
	
	
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
