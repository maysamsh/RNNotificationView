//
//  RNNotificationView.swift
//
//  Created by Romilson Nunes on 21/10/16.
//
//

import UIKit

public class RNNotificationView: UIToolbar {
    
    // MARK: - Properties
    private static var sharedNotification = RNNotificationView()

    public var titleFont = Notification.titleFont {
        didSet {
            titleLabel.font = titleFont
        }
    }
    public var titleTextColor = UIColor.whiteColor() {
        didSet {
            titleLabel.textColor = titleTextColor
        }
    }
    public var subtitleFont = Notification.subtitleFont {
        didSet {
            subtitleLabel.font = subtitleFont
        }
    }
    public var subtitleTextColor = UIColor.whiteColor() {
        didSet {
            subtitleLabel.textColor = subtitleTextColor
        }
    }
    public var duration: NSTimeInterval = 2.5
    
    public private(set) var isAnimating = false
    public private(set) var isDragging = false
    
//    public private(set) var title: String?
//    public private(set) var message: String?
//    public private(set) var accessoryType: NotificationViewAccessoryType = .None
    
    private var dismissTimer: NSTimer? {
        didSet {
            if oldValue?.valid == true {
                oldValue?.invalidate()
            }
        }
    }
    private var verticalPositionConstraint: NSLayoutConstraint!
//    private var tapAction = #selector(NotificationView.notificationViewTapped)

    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
//        imageView.translatesAutoresizingMaskIntoConstraints = false // auto-layout only
        imageView.layer.cornerRadius = 3
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    private lazy var titleLabel: UILabel = { [unowned self] in
        let titleLabel = UILabel()
//        titleLabel.translatesAutoresizingMaskIntoConstraints = false // auto-layout only
        titleLabel.backgroundColor = UIColor.clearColor()
        titleLabel.textAlignment = .Left
        titleLabel.numberOfLines = 1
        titleLabel.font = self.titleFont
        titleLabel.textColor = self.titleTextColor
        return titleLabel
        }()
    private lazy var subtitleLabel: UILabel = { [unowned self] in
        let subtitleLabel = UILabel()
//        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false // auto-layout only
        subtitleLabel.backgroundColor = UIColor.clearColor()
        subtitleLabel.textAlignment = .Left
        subtitleLabel.numberOfLines = 2
        subtitleLabel.font = self.subtitleFont
        subtitleLabel.textColor = self.subtitleTextColor
        return subtitleLabel
        }()
    
    
    private var imageViewFrame: CGRect {
        return CGRect(x: 15.0, y: 8.0, width: 20.0, height: 20.0)
    }

    private var titleLabelFrame: CGRect {
        if self.imageView.image == nil {
            return CGRect(x: 5.0, y: 3.0, width: NotificationLayout.width - 5.0, height: 26.0)
        }
        return CGRect(x: 45.0, y: 3.0, width: NotificationLayout.width - 45.0, height: 26.0)
    }
    
    private var messageLabelFrame: CGRect {
        if self.imageView.image == nil {
            return CGRect(x: 5, y: 25, width: NotificationLayout.width - 5, height: NotificationLayout.labelMessageHeight)
        }
        return CGRect(x: 45, y: 25, width: NotificationLayout.width - 45.0, height: NotificationLayout.labelMessageHeight)
    }

    
    
   
    // MARK: - Initialization
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    public init() {
        super.init(frame: CGRect(x: 0, y: 0, width: NotificationLayout.width, height: NotificationLayout.height))
        
        startNotificationObservers()
        setupUI()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Override Toolbar
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        setupFrames()
    }
    
    public override func intrinsicContentSize() -> CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: NotificationLayout.height)
    }
    
    
    // MARK: - Observers
    
    private func startNotificationObservers() {
        /// Enable orientation tracking
        if !UIDevice.currentDevice().generatesDeviceOrientationNotifications {
            UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
        }
        
        /// Add Orientation notification
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RNNotificationView.orientationStatusDidChange(_:)), name: UIDeviceOrientationDidChangeNotification, object: nil)
        
    }
    
    
    // MARK: - Orientation Observer
    
    @objc private func orientationStatusDidChange(notification: NSNotification) {
        setupUI()
    }
    
    
    // MARK: - Setups
    
    private func setupFrames() {
        
        var frame = self.frame
        frame.size.width = NotificationLayout.width
        self.frame = frame
        
        self.titleLabel.frame = self.titleLabelFrame
        self.imageView.frame = self.imageViewFrame
        self.subtitleLabel.frame = self.messageLabelFrame

        fixLabelMessageSize()
    }

    private func setupUI() {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        // Bar style
        self.barTintColor = nil
        self.translucent = true
        self.barStyle = UIBarStyle.Black
        
        self.tintColor = UIColor(red: 5, green: 31, blue: 75, alpha: 1)
        
        self.layer.zPosition = CGFloat.max
        self.backgroundColor = UIColor.clearColor()
        self.multipleTouchEnabled = false
        self.exclusiveTouch = true
        
        self.frame = CGRect(x: 0, y: 0, width: NotificationLayout.width, height: NotificationLayout.height)
        self.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleTopMargin, UIViewAutoresizing.FlexibleRightMargin, UIViewAutoresizing.FlexibleLeftMargin]
        
        // Add subviews
        self.addSubview(self.titleLabel)
        self.addSubview(self.subtitleLabel)
        self.addSubview(self.imageView)
        
        // Setup frames
        self.setupFrames()
    }
    
    
    // MARK: - Helper
    
    private func fixLabelMessageSize() {
        let size = self.subtitleLabel.sizeThatFits(CGSize(width: NotificationLayout.width - NotificationLayout.labelPadding, height: CGFloat.max))
        var frame = self.subtitleLabel.frame
        frame.size.height = size.height > NotificationLayout.labelMessageHeight ? NotificationLayout.labelMessageHeight : size.height
        self.subtitleLabel.frame = frame;
    }
    
    // MARK: - Public Methods
    
    public func show(withImage image: UIImage?, title: String?, message: String?) {
        
        /// Invalidate dismissTimer
        self.dismissTimer = nil
        
        // Tap action
        //        self.sharedNotification.tapAction
        
        /// Image
        self.imageView.image = image
        self.titleLabel.text = title
        self.subtitleLabel.text = message
        
        /// Prepare frame
        var frame = self.frame
        frame.origin.y = -frame.size.height
        self.frame = frame
        
        self.setupFrames()
        
        self.userInteractionEnabled = true
        self.isAnimating = true
        
        /// Add to window
        if let window = UIApplication.sharedApplication().delegate?.window {
            window?.windowLevel = UIWindowLevelStatusBar
            window?.addSubview(self)
        }
        
        /// Show animation
        UIView.animateWithDuration(Notification.showAnimationDuration, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            
            var frame = self.frame
            frame.origin.y += frame.size.height
            self.frame = frame
            
        }) { (finished) in
            self.isAnimating = false
        }
        
        // Schedule to hide
        if self.duration > 0 {
            self.dismissTimer = NSTimer.scheduledTimerWithTimeInterval(Notification.notificationDuration, target: self, selector: #selector(RNNotificationView.scheduledDismiss), userInfo: nil, repeats: false)
        }
        
        
    }
    
    // MARK: - Actions
    
    @objc private func scheduledDismiss() {
        self.hide(completion: nil)
    }

    
    dynamic internal func hide(completion completion: (() -> ())?) {
        
        guard !self.isDragging else {
            self.dismissTimer = nil
            return
        }
        
        
        if self.superview == nil {
            isAnimating = false
            return
        }
        
        // Case are in animation of the hide
        if (isAnimating) {
            return
        }
        isAnimating = true
        
        // Invalidate timer auto close
        self.dismissTimer = nil
        
        /// Show animation
        UIView.animateWithDuration(Notification.showAnimationDuration, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            
            var frame = self.frame
            frame.origin.y -= frame.size.height
            self.frame = frame
            
        }) { (finished) in
            
            self.removeFromSuperview()
            UIApplication.sharedApplication().delegate?.window??.windowLevel = UIWindowLevelNormal
            
            self.isAnimating = false
            
            completion?()

        }
        
    }
    
}


public extension RNNotificationView {
    public static func show(image image: UIImage?, title: String?, message: String?) {
        self.sharedNotification.show(withImage: image, title: title, message: message)
    }
}
