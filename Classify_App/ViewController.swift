import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var classifyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        // フォトアルバムを開く処理
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        } else {
            // フォトアルバムが利用できない場合のエラーメッセージなど
            let alert = UIAlertController(title: "Error", message: "Photo Library not available", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            imageView.image = selectedImage
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func classifyButtonTapped(_ sender: UIButton) {
        guard let image = imageView.image else {
            resultLabel.text = "画像がありません"
            return
        }
        classifyImage(image)
    }
    
    private func classifyImage(_ image: UIImage) {
        guard let model = try? VNCoreMLModel(for: AI_human_classify_model().model) else {
            DispatchQueue.main.async {
                self.resultLabel.text = "モデルの読み込みに失敗しました"
            }
            return
        }
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                DispatchQueue.main.async {
                    self?.resultLabel.text = "分類結果がありません"
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.resultLabel.text = "結果: \(topResult.identifier) - \(topResult.confidence)"
            }
        }
        
        guard let ciImage = CIImage(image: image) else {
            resultLabel.text = "CIImageへの変換に失敗しました"
            return
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.resultLabel.text = "画像分類に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
}
