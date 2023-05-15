//
//  ViewController.swift
//  SeeFood
//
//  Created by Mac on 6.05.2023.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    let wikipediaUrl = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController()
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }
    
    func requestInfo(name: String) {
        let parameters : [String:String] = ["format" : "json", "action" : "query", "prop" : "extracts|pageimages", "exintro" : "", "explaintext" : "", "titles" : name, "redirects" : "1", "pithumbsize" : "500", "indexpageids" : ""]
               
        AF.request(wikipediaUrl, method: .get, parameters: parameters).responseJSON { (response) in
            if case .success(let value) = response.result {
                let itemJSON : JSON = JSON(value)
               
                let pageid = itemJSON["query"]["pageids"][0].stringValue
                print(response)
                let itemDescription = itemJSON["query"]["pages"][pageid]["extract"].stringValue
                let itemImageURL = itemJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                self.infoLabel.text = itemDescription
                self.imageView.sd_setImage(with: URL(string: itemImageURL))
                print(itemImageURL)
                print(self.imageView.sd_setImage(with: URL(string: itemImageURL)))
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickerImage = info[.editedImage] as? UIImage{
           
            
            guard let ciimage = CIImage(image: userPickerImage) else {
                fatalError("You have an error in ciimage!")
            }
            detect(image: ciimage)
            
        }
        imagePicker.dismiss(animated: true)
        
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else {
            fatalError("Loading CoreML Model Failed!")
        }
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image")
            }
            if let firstResult = results.first {
                
                let labels = firstResult.identifier.components(separatedBy: ",")
                if let mainLabel = labels.first {
                    self.navigationItem.title = mainLabel
                    self.requestInfo(name: mainLabel)
                }
            }
        }
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true)
    }
}

