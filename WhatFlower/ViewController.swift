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

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageViewML: UIImageView!
    
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
                
                let parameters = [
                    "format": "json",
                    "action": "query",
                    "prop": "extracts",
                    "exintro": "",
                    "explaintext": "",
                    "titles": "\(flowerName)"
                ]
                
                print(parameters)
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print("error do handler, \(error)")
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            imageViewML.image = editedImage
            
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

