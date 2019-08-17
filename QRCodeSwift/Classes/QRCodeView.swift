//
//  QRCodeView.swift
//  QRCodeSwift
//
//  Created by Hao Wang on 2019/1/26.
//

import UIKit

private var flag = true

open class QRCodeView: UIView {
    
    public var scanAnimationStyle: ScanAnimationStyle = .default
    public var scanImageName: String = "QRCodeScanLine"
    public var borderColor: UIColor = .white
    public var cornerLocation: CornerLoaction = .default
    public var cornerColor: UIColor = UIColor(red: 85/255.0, green: 183/255.0, blue: 55/255.0, alpha: 1.0)
    public var cornerWidth: CGFloat = 2.0
    public var backgroundAlpha: CGFloat = 0.5
    public var animationTimeInterval: TimeInterval = 0.02
    
    // MARK: - Private
    private var scanBorderW: CGFloat {
        return 0.7 * self.frame.size.width
    }
    private var scanBorderX: CGFloat {
        return 0.5 * (1 - 0.7) * self.frame.size.width
    }
    private var scanBorderY: CGFloat {
        return 0.5 * (self.frame.size.height - scanBorderW)
    }
    
    private var timer: Timer?
    private lazy var contentView: UIView = {
        let view = UIView(frame: CGRect(x: scanBorderX, y: scanBorderY, width: scanBorderW, height: scanBorderW))
        view.clipsToBounds = true
        view.backgroundColor = UIColor.clear
        return view
    }()
    private lazy var scanningline: UIImageView = {
        let view = UIImageView()
        /// 静态库 url 的获取
        var assetBundle: Bundle?
        if let url = Bundle.main.url(forResource: "QRCodeSwift", withExtension: "bundle") {
            assetBundle = Bundle(url: url)
        } else if let url = Bundle(for: type(of: self)).url(forResource: "QRCodeSwift", withExtension: "bundle") {
            assetBundle = Bundle(url: url)
        }
        if let bundle = assetBundle, let image = UIImage(named: self.scanImageName, in: bundle, compatibleWith: nil) {
            view.image = image
        } else {
            view.image = UIImage(named: self.scanImageName)
        }
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        let borderLineW: CGFloat = 0.2
        
        UIColor.black.withAlphaComponent(self.backgroundAlpha).setFill()
        UIRectFill(rect)
        
        let context = UIGraphicsGetCurrentContext()
        context?.setBlendMode(CGBlendMode.destinationOut)
        let bezierPath = UIBezierPath(rect: CGRect(x: scanBorderX + 0.5 * borderLineW, y: scanBorderY + 0.5 * borderLineW, width: scanBorderW - borderLineW, height: scanBorderW - borderLineW))
        bezierPath.fill()
        
        context?.setBlendMode(CGBlendMode.normal)
        /// 边框设置
        let borderPath = UIBezierPath(rect: CGRect(x: scanBorderX, y: scanBorderY, width: scanBorderW, height: scanBorderW))
        borderPath.lineCapStyle = CGLineCap.butt
        borderPath.lineWidth = borderLineW
        self.borderColor.set()
        borderPath.stroke()
        
        let cornerLenght: CGFloat = 20
        /// 左上角小图标
        let leftTopPath = UIBezierPath()
        leftTopPath.lineWidth = self.cornerWidth
        self.cornerColor.set()
        
        let insideExcess = CGFloat(abs(0.5 * (self.cornerWidth - borderLineW)))
        let outsideExcess = 0.5 * (borderLineW + self.cornerWidth)
        if self.cornerLocation == CornerLoaction.inside {
            leftTopPath.move(to: CGPoint(x: scanBorderX + insideExcess, y: scanBorderY + cornerLenght + insideExcess))
            leftTopPath.addLine(to: CGPoint(x: scanBorderX + insideExcess, y: scanBorderY + insideExcess))
            leftTopPath.addLine(to: CGPoint(x: scanBorderX + cornerLenght + insideExcess,y:  scanBorderY + insideExcess))
        } else if self.cornerLocation == CornerLoaction.outside {
            leftTopPath.move(to: CGPoint(x: scanBorderX - outsideExcess, y: scanBorderY + cornerLenght - outsideExcess))
            leftTopPath.addLine(to: CGPoint(x: scanBorderX - outsideExcess, y: scanBorderY - outsideExcess))
            leftTopPath.addLine(to: CGPoint(x: scanBorderX + cornerLenght - outsideExcess, y: scanBorderY - outsideExcess))
        } else {
            leftTopPath.move(to: CGPoint(x: scanBorderX, y: scanBorderY + cornerLenght))
            leftTopPath.addLine(to: CGPoint(x: scanBorderX, y: scanBorderY))
            leftTopPath.addLine(to: CGPoint(x: scanBorderX + cornerLenght, y: scanBorderY))
        }
        
        leftTopPath.stroke()
        
        /// 左下角小图标
        let leftBottomPath = UIBezierPath()
        leftBottomPath.lineWidth = self.cornerWidth
        self.cornerColor.set()
        
        if (self.cornerLocation == CornerLoaction.inside) {
            leftBottomPath.move(to: CGPoint(x: scanBorderX + cornerLenght + insideExcess, y: scanBorderY + scanBorderW - insideExcess))
            leftBottomPath.addLine(to: CGPoint(x: scanBorderX + insideExcess, y: scanBorderY + scanBorderW - insideExcess))
            leftBottomPath.addLine(to:CGPoint(x: scanBorderX + insideExcess, y: scanBorderY + scanBorderW - cornerLenght - insideExcess))
        } else if (self.cornerLocation == CornerLoaction.outside) {
            leftBottomPath.move(to: CGPoint(x: scanBorderX + cornerLenght - outsideExcess, y: scanBorderY + scanBorderW + outsideExcess))
            leftBottomPath.addLine(to: CGPoint(x: scanBorderX - outsideExcess, y: scanBorderY + scanBorderW + outsideExcess))
            leftBottomPath.addLine(to: CGPoint(x: scanBorderX - outsideExcess, y: scanBorderY + scanBorderW - cornerLenght + outsideExcess))
        } else {
            leftBottomPath.move(to: CGPoint(x: scanBorderX + cornerLenght, y: scanBorderY + scanBorderW))
            leftBottomPath.addLine(to: CGPoint(x: scanBorderX, y: scanBorderY + scanBorderW))
            leftBottomPath.addLine(to: CGPoint(x: scanBorderX, y: scanBorderY + scanBorderW - cornerLenght))
        }
        
        leftBottomPath.stroke()
        
        /// 右上角小图标
        let rightTopPath = UIBezierPath()
        rightTopPath.lineWidth = self.cornerWidth
        self.cornerColor.set()
        
        if (self.cornerLocation == CornerLoaction.inside) {
            rightTopPath.move(to: CGPoint(x: scanBorderX + scanBorderW - cornerLenght - insideExcess, y: scanBorderY + insideExcess))
            rightTopPath.addLine(to: CGPoint(x: scanBorderX + scanBorderW - insideExcess, y: scanBorderY + insideExcess))
            rightTopPath.addLine(to: CGPoint(x: scanBorderX + scanBorderW - insideExcess, y: scanBorderY + cornerLenght + insideExcess))
        } else if (self.cornerLocation == CornerLoaction.outside) {
            rightTopPath.move(to: CGPoint(x: scanBorderX + scanBorderW - cornerLenght + outsideExcess, y: scanBorderY - outsideExcess))
            rightTopPath.addLine(to: CGPoint(x: scanBorderX + scanBorderW + outsideExcess, y: scanBorderY - outsideExcess))
            rightTopPath.addLine(to: CGPoint(x: scanBorderX + scanBorderW + outsideExcess, y: scanBorderY + cornerLenght - outsideExcess))
        } else {
            rightTopPath.move(to: CGPoint(x: scanBorderX + scanBorderW - cornerLenght, y: scanBorderY))
            rightTopPath.addLine(to: CGPoint(x: scanBorderX + scanBorderW, y: scanBorderY))
            rightTopPath.addLine(to: CGPoint(x: scanBorderX + scanBorderW, y: scanBorderY + cornerLenght))
        }
        
        rightTopPath.stroke()
        
        /// 右下角小图标
        let rightBottomPath = UIBezierPath()
        rightBottomPath.lineWidth = self.cornerWidth
        self.cornerColor.set()
        
        if (self.cornerLocation == CornerLoaction.inside) {
            rightBottomPath.move(to: CGPoint(x: scanBorderX + scanBorderW - insideExcess, y: scanBorderY + scanBorderW - cornerLenght - insideExcess))
            rightBottomPath.addLine(to: CGPoint(x: scanBorderX + scanBorderW - insideExcess, y: scanBorderY + scanBorderW - insideExcess))
            rightBottomPath.addLine(to: CGPoint(x: scanBorderX + scanBorderW - cornerLenght - insideExcess, y: scanBorderY + scanBorderW - insideExcess))
        } else if (self.cornerLocation == CornerLoaction.outside) {
            rightBottomPath.move(to: CGPoint(x: scanBorderX + scanBorderW + outsideExcess, y: scanBorderY + scanBorderW - cornerLenght + outsideExcess))
            rightBottomPath.addLine(to: CGPoint(x: scanBorderX + scanBorderW + outsideExcess, y: scanBorderY + scanBorderW + outsideExcess))
            rightBottomPath.addLine(to: CGPoint(x: scanBorderX + scanBorderW - cornerLenght + outsideExcess, y: scanBorderY + scanBorderW + outsideExcess))
        } else {
            rightBottomPath.move(to: CGPoint(x: scanBorderX + scanBorderW, y: scanBorderY + scanBorderW - cornerLenght))
            rightBottomPath.addLine(to: CGPoint(x: scanBorderX + scanBorderW, y: scanBorderY + scanBorderW))
            rightBottomPath.addLine(to: CGPoint(x: scanBorderX + scanBorderW - cornerLenght, y: scanBorderY + scanBorderW))
        }
        
        rightBottomPath.stroke()
    }
    
    public func addTimer() {
        var scanninglineX: CGFloat = 0
        var scanninglineY: CGFloat = 0
        var scanninglineW: CGFloat = 0
        var scanninglineH: CGFloat = 0
        if (self.scanAnimationStyle == ScanAnimationStyle.grid) {
            self.addSubview(self.contentView)
            self.contentView.addSubview(self.scanningline)
            scanninglineW = self.scanBorderW
            scanninglineH = self.scanBorderW
            scanninglineY = -self.scanBorderW
        } else {
            self.addSubview(self.scanningline)
            scanninglineW = self.scanBorderW
            scanninglineH = 12
            scanninglineX = self.scanBorderX
            scanninglineY = self.scanBorderY
        }
        self.scanningline.frame = CGRect(x: scanninglineX, y: scanninglineY, width: scanninglineW, height: scanninglineH)
        let _timer = Timer(timeInterval: self.animationTimeInterval, target: self, selector: #selector(beginRefreshUI), userInfo: nil, repeats: true)
        RunLoop.main.add(_timer, forMode: RunLoop.Mode.common)
        self.timer = _timer
    }
    
    public func removeTimer() {
        self.timer?.invalidate()
        self.timer = nil
        self.scanningline.removeFromSuperview()
    }
    
    @objc private func beginRefreshUI() {
        var frame = self.scanningline.frame
        
        if (self.scanAnimationStyle == ScanAnimationStyle.grid) {
            if (flag) {
                frame.origin.y = -scanBorderW
                flag = false
                UIView.animate(withDuration: self.animationTimeInterval) {
                    frame.origin.y += 2
                    self.scanningline.frame = frame
                }
            } else {
                if (self.scanningline.frame.origin.y >= -scanBorderW) {
                    let scanContent_MaxY = -scanBorderW + self.frame.size.width - 2 * scanBorderX
                    if (self.scanningline.frame.origin.y >= scanContent_MaxY) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            frame.origin.y = -self.scanBorderW
                            self.scanningline.frame = frame
                            flag = true
                        }
                    } else {
                        UIView.animate(withDuration: self.animationTimeInterval) {
                            frame.origin.y += 2
                            self.scanningline.frame = frame
                        }
                    }
                } else {
                    flag = !flag
                }
            }
        } else {
            if (flag) {
                frame.origin.y = scanBorderY
                flag = false
                UIView.animate(withDuration: self.animationTimeInterval) {
                    frame.origin.y += 2
                    self.scanningline.frame = frame
                }
            } else {
                if (self.scanningline.frame.origin.y >= scanBorderY) {
                    let scanContent_MaxY = scanBorderY + self.frame.size.width - 2 * scanBorderX
                    if (self.scanningline.frame.origin.y >= scanContent_MaxY - 10) {
                        frame.origin.y = scanBorderY
                        self.scanningline.frame = frame
                        flag = true
                    } else {
                        UIView.animate(withDuration:self.animationTimeInterval) {
                            frame.origin.y += 2
                            self.scanningline.frame = frame
                        }
                    }
                } else {
                    flag = !flag
                }
            }
        }
    }
}
