//
//  ViewController.swift
//  WhatFlower
//
//  Created by Fadli Baihaqi on 19/08/19.
//  Copyright © 2019 Fadli Al Baihaqi. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageViewML: UIImageView!
    @IBOutlet weak var extractInfo: UILabel!
    
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Failed load model")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            if let error = error {
                print("error request, \(error)")
            }
            
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed process image")
            }
            
            if let flowerName = results.first?.identifier {
                self.navigationItem.title = flowerName.capitalized
                
                self.requestInfo(flowerName: flowerName)
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print("error do handler, \(error)")
        }
    }
    
    func requestInfo (flowerName: String) {
        
        let parameters: [String: String] = [
            "format": "json",
            "action": "query",
            "prop": "extracts|pageimages",
            "exintro": "",
            "explaintext": "",
            "titles": "\(flowerName)",
            "indexpageids": "",
            "redirects": "1",
            "pithumbsize": "500"
        ]
        
        Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                
                let result: JSON = JSON(response.result.value)
                
                let indexpage = result["query"]["pageids"][0].stringValue
                let extracts = result["query"]["pages"][indexpage]["extract"]
                let flowerURL = result["query"]["pages"][indexpage]["thumbnail"]["source"].stringValue
                
                
                self.imageViewML.sd_setImage(with: URL(string: flowerURL))
                self.extractInfo.text = extracts.stringValue
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
            guard let ciImage = CIImage(image: editedImage) else {
                fatalError("Failed convert image to CIImage")
            }
            
            detect(image: ciImage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }


    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
}

