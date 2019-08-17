//
//  QRCodeManager.swift
//  QRCodeSwift
//
//  Created by Hao Wang on 2019/1/25.
//

import UIKit
import AVFoundation
import Photos

public enum QRError: Error {
    case noDevice
}

public enum CornerLoaction: UInt {
    case `default`      ///< 默认与边框线同中心点
    case inside         ///< 在边框线内部
    case outside        ///< 在边框线外部
}

public enum ScanAnimationStyle: UInt {
    case `default`      ///< 单线扫描样式
    case grid           ///< 网格扫描样式
}

public struct QRCodeObtainConfigure {
    public var sessionPreset = AVCaptureSession.Preset.hd1920x1080
    public var metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
    public var rectOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
    public var sampleBufferDelegate: Bool = false
    public var debug: Bool = false
    
    public static var `default` = QRCodeObtainConfigure()
}

public typealias QRCodeObtainScanResultBlock = (QRCodeManager, String?) -> Void
public typealias QRCodeObtainScanBrightnessBlock = (QRCodeManager, CGFloat) -> Void
public typealias QRCodeObtainAlbumDidCancelImagePickerControllerBlock = (QRCodeManager) -> Void
public typealias QRCodeObtainAlbumResultBlock = (QRCodeManager, String?) -> Void

open class QRCodeManager: NSObject {
    
    deinit {
        if self.configure.debug {
            NSLog("QRCodeManager - - dealloc")
        }
    }
    
    private weak var controller: UIViewController?
    private var configure = QRCodeObtainConfigure.default
    private lazy var captureSession: AVCaptureSession = AVCaptureSession()
    
    /** 创建相册并获取相册授权方法 */
    public var scanResultBlock: QRCodeObtainScanResultBlock?
    /** 扫描二维码光线强弱回调方法；调用之前配置属性 sampleBufferDelegate 必须为 YES */
    public var scanBrightnessBlock: QRCodeObtainScanBrightnessBlock?
    /** 图片选择控制器取消按钮的点击回调方法 */
    public var albumDidCancelImagePickerControllerBlock: QRCodeObtainAlbumDidCancelImagePickerControllerBlock?
    /** 相册中读取图片二维码信息回调方法 */
    public var albumResultBlock: QRCodeObtainAlbumResultBlock?
    
    private var detectorString: String?
    /** 判断相机访问权限是否授权 */
    public var isCameraAuthorization: Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
    /** 判断相册访问权限是否授权 */
    public var isPHAuthorization: Bool {
        let status = PHPhotoLibrary.authorizationStatus()
        return  status == .authorized
    }
    
    /** 创建扫描二维码方法 */
    public func establishQRCodeObtainScanWith(controller: UIViewController, configure: QRCodeObtainConfigure) throws {
        self.controller = controller
        self.configure = configure
        guard let device = AVCaptureDevice.default(for: .video) else {
            throw QRError.noDevice
        }
        // 1、捕获设备输入流
        let deviceInput = try AVCaptureDeviceInput(device: device)
        // 2、捕获元数据输出流
        let metadataOutput = AVCaptureMetadataOutput()
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        // 设置扫描范围（每一个取值 0 ～ 1，以屏幕右上角为坐标原点）
        // 注：微信二维码的扫描范围是整个屏幕，这里并没有做处理（可不用设置）
        metadataOutput.rectOfInterest = configure.rectOfInterest
        // 3、设置会话采集率
        self.captureSession.sessionPreset = configure.sessionPreset
        // 4(1)、添加捕获元数据输出流到会话对象
        if self.captureSession.canAddOutput(metadataOutput) {
            self.captureSession.addOutput(metadataOutput)
        }
        // 4(2)、添加捕获输出流到会话对象；构成识别光线强弱
        if self.configure.sampleBufferDelegate {
            let videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
            if self.captureSession.canAddInput(deviceInput) {
                captureSession.addOutput(videoDataOutput)
            }
        }
        // 4(3)、添加捕获设备输入流到会话对象
        if self.captureSession.canAddInput(deviceInput) {
            self.captureSession.addInput(deviceInput)
        }
        // 5、设置数据输出类型，需要将数据输出添加到会话后，才能指定元数据类型，否则会报错
        metadataOutput.metadataObjectTypes = configure.metadataObjectTypes
        // 6、预览图层
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        // 保持纵横比，填充层边界
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = controller.view.frame
        controller.view.layer.insertSublayer(videoPreviewLayer, at: 0)
    }
    
    /** 开启扫描回调方法 */
    public func startRunningWithBefore(before: (() -> Void)?, completion: (() -> Void)?) {
        before?()
        DispatchQueue.global().async { [weak self] in
            self?.captureSession.startRunning()
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    /** 停止扫描方法 */
    public func stopRunning() {
        if self.captureSession.isRunning {
            self.captureSession.stopRunning()
        }
    }
    
    /** 播放音效文件 */
    public func playSound(name: String) {
        var fileUrl: URL?
        if let path = Bundle.main.path(forResource: name, ofType: nil) { /// 静态库 path 的获取
            fileUrl = URL(fileURLWithPath: path)
        } else if let path = Bundle(for: type(of: self)).path(forResource: name, ofType: nil) { /// 动态库 path 的获取
            fileUrl = URL(fileURLWithPath: path)
        }
        
        if let _fileUrl = fileUrl {
            var soundID: SystemSoundID = 0
            _ = withUnsafeMutablePointer(to: &soundID) { (soundIDPointer) -> OSStatus in
                AudioServicesCreateSystemSoundID(_fileUrl as CFURL, soundIDPointer)
            }
            _ = withUnsafeMutablePointer(to: &soundID) { (soundIDPointer) -> OSStatus in
                AudioServicesCreateSystemSoundID(_fileUrl as CFURL, soundIDPointer)
            }
            AudioServicesAddSystemSoundCompletion(soundID, nil, nil, { (_, _) in }, nil)
            AudioServicesPlaySystemSound(soundID)
        }
    }
    
    // MARK: - 相册中读取二维码相关方法
    
    public func establishAuthorizationQRCodeObtainAlbumWith(controller: UIViewController) {
        self.controller = controller
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        controller.present(imagePicker, animated: true, completion: nil)
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRCodeManager: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let obj = metadataObjects.compactMap({ $0 as? AVMetadataMachineReadableCodeObject }).first {
            scanResultBlock?(self, obj.stringValue)
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension QRCodeManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let metadata = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate) as? [String: Any],
            let exifMetadata = metadata[kCGImagePropertyExifDictionary as String] as? NSDictionary,
            let brightnessValue = exifMetadata[kCGImagePropertyExifBrightnessValue as String] as? CGFloat else {
                scanBrightnessBlock?(self, 0)
                return
        }
        scanBrightnessBlock?(self, brightnessValue)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension QRCodeManager: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.controller?.dismiss(animated: true, completion: nil)
        albumDidCancelImagePickerControllerBlock?(self)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage,
            let ciImage = CIImage(image: image),
            let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) else {
                albumResultBlock?(self, nil)
                return
        }
        // 获取识别结果
        let features = detector.features(in: ciImage)
        if features.count == 0 {
            self.controller?.dismiss(animated: true, completion: {
                self.albumResultBlock?(self, nil)
            })
        } else {
            features.compactMap({ $0 as? CIQRCodeFeature }).forEach { (feature) in
                self.detectorString = feature.messageString
                if self.configure.debug {
                    NSLog("相册中读取二维码数据信息 - - \(self.detectorString ?? "null")")
                }
            }
            self.controller?.dismiss(animated: true, completion: {
                self.albumResultBlock?(self, self.detectorString)
            })
        }
    }
}

// MARK: - 手电筒相关

extension QRCodeManager {
    /** 打开手电筒 */
    public func openFlashlight() throws {
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video), captureDevice.hasTorch else { return }
        try captureDevice.lockForConfiguration()
        captureDevice.torchMode = .on
        captureDevice.unlockForConfiguration()
    }
    /** 关闭手电筒 */
    public func closeFlashlight() throws {
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video), captureDevice.hasTorch else { return }
        try captureDevice.lockForConfiguration()
        captureDevice.torchMode = .off
        captureDevice.unlockForConfiguration()
    }
}

// MARK - 生成二维码相关方法
extension QRCodeManager {
    /// 生成(带 logo 的)二维码
    ///
    /// - Parameters:
    ///   - data: 二维码数据
    ///   - size: 二维码大小
    ///   - color: 二维码颜色
    ///   - backgroundColor: 二维码背景颜色
    ///   - logoImage: logo
    ///   - ratio: logo 相对二维码的比例（取值范围 0.0 ～ 0.5f）
    ///   - logoImageCornerRadius: logo 外边框圆角（取值范围 0.0 ～ 10.0f）
    ///   - logoImageBorderWidth: logo 外边框宽度（取值范围 0.0 ～ 10.0f）
    ///   - logoImageBorderColor: logo 外边框颜色
    /// - Returns: 二维码图片
    public class func generateQRCodeWith(data: String, size: CGFloat, color: UIColor = .black, backgroundColor: UIColor = .white, logoImage: UIImage? = nil, ratio: CGFloat = 0.25, logoImageCornerRadius: CGFloat = 5, logoImageBorderWidth:CGFloat = 5, logoImageBorderColor: UIColor = .white) -> UIImage? {
        guard let string_data = data.data(using: String.Encoding.utf8) else { return nil }
        // 1、二维码滤镜
        let fileter = CIFilter(name: "CIQRCodeGenerator", parameters: ["inputMessage": string_data,
                                                                       "inputCorrectionLevel": "H"])
        guard let ciImage = fileter?.outputImage else { return nil }
        // 2、颜色滤镜
        let color_filter = CIFilter(name: "CIFalseColor")
        color_filter?.setDefaults()
        color_filter?.setValue(ciImage, forKey: "inputImage")
        color_filter?.setValue(CIColor(color: color), forKey: "inputColor0")
        color_filter?.setValue(CIColor(color: backgroundColor), forKey: "inputColor1")
        // 3、生成处理
        guard var outImage = color_filter?.outputImage else { return nil }
        let scale = size / outImage.extent.size.width
        outImage = outImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let image = UIImage(ciImage: outImage)
        // logo
        guard let logoImage = logoImage else { return image }
        var _ratio = ratio
        if _ratio < 0.0 || _ratio > 0.5 {
            _ratio = 0.25
        }
        var _logoImageCornerRadius = logoImageCornerRadius
        if (_logoImageCornerRadius < 0.0 || _logoImageCornerRadius > 10) {
            _logoImageCornerRadius = 5
        }
        var _logoImageBorderWidth = logoImageBorderWidth
        if (_logoImageBorderWidth < 0.0 || _logoImageBorderWidth > 10) {
            _logoImageBorderWidth = 5
        }
        
        let logoImageW = _ratio * size
        let logoImageH = logoImageW
        let logoImageX = 0.5 * (image.size.width - logoImageW)
        let logoImageY = 0.5 * (image.size.height - logoImageH)
        let logoImageRect = CGRect(x: logoImageX, y: logoImageY, width: logoImageW, height: logoImageH)
        // 绘制logo
        UIGraphicsBeginImageContextWithOptions(image.size, false, UIScreen.main.scale)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        
        let path = UIBezierPath(roundedRect: logoImageRect, cornerRadius: _logoImageCornerRadius)
        path.lineWidth = _logoImageBorderWidth
        logoImageBorderColor.setStroke()
        path.stroke()
        path.addClip()
        logoImage.draw(in: logoImageRect)
        let qrCodeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return qrCodeImage
    }
}
