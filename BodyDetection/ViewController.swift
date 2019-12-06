/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample app's main view controller.
*/

import UIKit
import RealityKit
import ARKit
import Combine

class ViewController: UIViewController, ARSessionDelegate {

    @IBOutlet var arView: ARView!
    
    // The 3D character to display.
    var character: BodyTrackedEntity?
    //var characterOffset: SIMD3<Float> = [-1.0, 0, 0] // Offset the character by one meter to the left
	var characterOffset: SIMD3<Float> = [0, 0, 0] // Offset the character by one meter to the left
	let charFrame: CGRect = CGRect(x: 0, y: 0, width: 100, height: 100)

    let characterAnchor = AnchorEntity()

	var intNum: Int = 0
	var bodyAnchorObj: ARBodyAnchor?
	var bodyAnchor2D: ARBody2D?

	let hero: UIView = {
		let heroView = UIView()
		//heroView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
		//heroView.backgroundColor = .darkGray
        /*
         Jing made change here
         */
		return heroView
	}()

	let heroBody: UIImageView = {
		let imageView = UIImageView(image: UIImage(named: "HRBody"))
		//imageView.backgroundColor = .systemRed
		imageView.contentMode = .scaleAspectFit
		return imageView
	}()

	let heroLeftArm: UIImageView = {
		let imageView = UIImageView(image: UIImage(named: "HRLeftArm"))
		//imageView.backgroundColor = .systemRed
		imageView.contentMode = .scaleAspectFit
		return imageView
	}()
	let heroRightArm: UIImageView = {
		let imageView = UIImageView(image: UIImage(named: "HRRightArm"))
		imageView.backgroundColor = .systemRed
		imageView.backgroundColor = .systemPink
		imageView.contentMode = .scaleAspectFit
		return imageView
	}()



	let resetButton: UIButton = {
		let button = UIButton()
		button.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
		button.setTitle("Reset", for: .normal)
		button.contentEdgeInsets =  UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
		button.backgroundColor = UIColor.blue
		button.layer.cornerRadius = 3.0
		button.addTarget(self, action: #selector(onReset), for: .touchDown)
		return button
	}()

	func createDisplayLink() {
		let displayLink = CADisplayLink(target: self, selector: #selector(enterFrame))
		displayLink.add(to: .current, forMode: .default)
	}

	@objc
	func enterFrame() {
		//print("update")
		//print(hero.frame, hero.bounds)
	}
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
				setupUI()
				setupARTracking()




			view.addSubview(hero)


//			UIView.animate(withDuration: 3.0, animations: {
//				self.hero.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi * 0.5))
//			})


			//heroBody.center = hero.center
			//heroBody.layer.anchorPoint = CGPoint(x: 0.5, y: 0.6)
			//heroBody.center = hero.center
			hero.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
			heroBody.frame = charFrame
			heroBody.center = hero.center
			hero.addSubview(heroBody)

			heroRightArm.frame = charFrame
			heroRightArm.center = hero.center
			heroRightArm.layer.anchorPoint = CGPoint(x: 0.8, y: 0.15)
			hero.addSubview(heroRightArm)

			UIView.animate(withDuration: 3.0, animations: {
				self.heroRightArm.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi * 0.5))
			})


			heroLeftArm.frame.size = charFrame.size
			heroLeftArm.center = hero.center
			hero.addSubview(heroLeftArm)


			hero.frame = view.frame
			print(view.frame)
			print(hero.frame)
			print(hero.center)

			print(heroBody.frame)
			print(heroRightArm.frame)


			createDisplayLink()

    }
	// MARK Setup UI
	func setupUI() {
		setupUILayout()
	}

	func setupUILayout() {
		view.addSubview(resetButton)
		resetButton.translatesAutoresizingMaskIntoConstraints = false
		resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
		resetButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100).isActive = true
	}


	func setupARTracking() {
		arView.session.delegate = self

        // If the iOS device doesn't support body tracking, raise a developer error for
        // this unhandled case.
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }

        // Run a body tracking configration.
        let configuration = ARBodyTrackingConfiguration()

        arView.session.run(configuration)

        arView.scene.addAnchor(characterAnchor)

        // Asynchronously load the 3D character.
        var cancellable: AnyCancellable? = nil
        cancellable = Entity.loadBodyTrackedAsync(named: "character/robot").sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error: Unable to load model: \(error.localizedDescription)")
                }
                cancellable?.cancel()
        }, receiveValue: { (character: Entity) in
            if let character = character as? BodyTrackedEntity {
                // Scale the character to human size
                character.scale = [1.0, 1.0, 1.0]
                self.character = character
                cancellable?.cancel()
            } else {
                print("Error: Unable to load model as BodyTrackedEntity")
            }
        })
	}



	func session(_ session: ARSession, didUpdate frame: ARFrame) {
		guard let person = frame.detectedBody else { return }

		bodyAnchor2D = person

		//let person = frame.detectedBody!
		let skelenton2D = person.skeleton
		let definition = skelenton2D.definition

		let jointLandmakrs = skelenton2D.jointLandmarks

		//print("main", jointLandmakrs)

		let root = skelenton2D.landmark(for: .root)


		for (i, joint) in jointLandmakrs.enumerated() {

			let parentIndex = definition.parentIndices[i]
			guard parentIndex != -1 else { continue }
			let parentJoint = jointLandmakrs[parentIndex]
			//print("2d things")
			//print(parentJoint)

		}
	 }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }

            // Update the position of the character anchor's position.
            let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
            characterAnchor.position = bodyPosition + characterOffset
            // Also copy over the rotation of the body anchor, because the skeleton's pose
            // in the world is relative to the body anchor's rotation.
            characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation

            if let character = character, character.parent == nil {
                // Attach the character to its anchor as soon as
                // 1. the body anchor was detected and
                // 2. the character was loaded.
				//bodyAnchor.skeleton.definition.value(forKeyPath: "a")
				var leftHandPosition = bodyAnchor.skeleton.localTransform(for: .leftHand)
				print(leftHandPosition)
				print("link in")
				self.bodyAnchorObj = bodyAnchor
				//self.bodyAnchor2D = bodyAnchor.referenceBody
                characterAnchor.addChild(character)
            }
        }
    }




	// MARK: Input Handler
	@objc func onReset() {
		print("reset")

//		var leftHandPosition = bodyAnchorObj?.skeleton.localTransform(for: .leftHand)
//		print("3d", leftHandPosition)
//		//var leftHandPosition2D = bodyAnchor2D?.skeleton.localTransform(for: .leftHand)
//		print("2d", leftHandPosition)

		let count = bodyAnchor2D?.skeleton.jointLandmarks.count
		let head = bodyAnchor2D?.skeleton.landmark(for: .head)
		let root = bodyAnchor2D?.skeleton.landmark(for: .root)
		let rightFoot = bodyAnchor2D?.skeleton.landmark(for: .rightFoot)
		let leftFoot = bodyAnchor2D?.skeleton.landmark(for: .leftFoot)

		print(head, root, rightFoot, leftFoot, count)

		setupARTracking()
		//characterOffset = [-1.0, 0, 0]
	}
}
