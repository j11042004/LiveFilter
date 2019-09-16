//
//  SetViewController.swift
//  FilterLive
//
//  Created by Uran on 2019/6/25.
//  Copyright © 2019 Uran. All rights reserved.
//

import UIKit
import CoreImage
class SetViewController: UIViewController {
    @IBOutlet weak var vectorXSlider: UISlider!
    @IBOutlet weak var vectorYSlider: UISlider!
    @IBOutlet weak var vectorZSlider: UISlider!
    @IBOutlet weak var vectorWSlider: UISlider!
    
    private var matrixType : ColorMatrixInfo = .red
    private let filterManager = FilterManager.shared
    private var selectVector : CIVector = CIVector(x: 0, y: 0, z: 0, w: 0)
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let swipGesture = UISwipeGestureRecognizer(target: self, action: #selector(removeSelf))
        swipGesture.direction = .down
        self.view.addGestureRecognizer(swipGesture)
        
        self.selectVector = self.filterManager.redVector
        
        self.vectorXSlider.value = Float(selectVector.x)
        self.vectorYSlider.value = Float(selectVector.y)
        self.vectorZSlider.value = Float(selectVector.z)
        self.vectorWSlider.value = Float(selectVector.w)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    @objc fileprivate func removeSelf(){
        self.dismiss(animated: true, completion: nil
        )
    }
    @IBAction func done(_ sender: Any) {
        self.removeSelf()
    }
    
    @IBAction func changeVector(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            matrixType = .red
            self.selectVector = self.filterManager.redVector
            break
        case 1:
            matrixType = .green
            self.selectVector = self.filterManager.greenVector
            break
        case 2:
            matrixType = .blue
            self.selectVector = self.filterManager.blueVector
            break
        case 3:
            matrixType = .alpha
            self.selectVector = self.filterManager.alphaVector
            break
        default:
            matrixType = .bias
            self.selectVector = self.filterManager.biasVector
            break
        }
        
        self.vectorXSlider.value = Float(selectVector.x)
        self.vectorYSlider.value = Float(selectVector.y)
        self.vectorZSlider.value = Float(selectVector.z)
        self.vectorWSlider.value = Float(selectVector.w)
    }
    
    
    @IBAction func valueChanged(_ sender: UISlider) {
        var x = selectVector.x
        var y = selectVector.y
        var w = selectVector.w
        var z = selectVector.z
        switch sender {
        case vectorXSlider:
            x = CGFloat(sender.value)
            break
        case vectorYSlider:
            y = CGFloat(sender.value)
            break
        case vectorZSlider:
            z = CGFloat(sender.value)
            break
        case vectorWSlider:
            w = CGFloat(sender.value)
            break
        default:
            break
        }
        self.selectVector = CIVector(x: x, y: y, z: z, w: w)
        self.filterManager.changeVector(type: self.matrixType, x: x, y: y, z: z, w: w)
    }
}
