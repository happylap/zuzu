//
//  CarouselView.swift
//  Youli
//
//  Created by JERRY LIU on 9/11/2015.
//  Copyright © 2015 ONTHETALL. All rights reserved.
//
import UIKit
import Foundation
import Alamofire
import AlamofireImage


private let Log = Logger.defaultLogger

class CarouselView: UIView {
    
    let pageControllHeight: CGFloat = 20
    
    var scrollView: UIScrollView!
    var pageControl: UIPageControl!
    var pageNumberLabel: UILabel!
    
    var tapHandler: (() -> Void)?
    var showPageNumber: Bool = true
    
    var placeholderImage: UIImage = UIImage(named: "house_img")!
    
    var imageUrls = [String]()
    var imageViews = [UIImageView]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    private func setup() {
        Log.enter()
        
        scrollView = UIScrollView()
        scrollView.pagingEnabled = true
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        
        pageControl = UIPageControl()
        pageControl.currentPage = 0
        pageControl.center = CGPointMake(self.center.x, pageControl.center.y)
        pageControl.pageIndicatorTintColor = UIColor.whiteColor()
        pageControl.currentPageIndicatorTintColor = UIColor.yellowColor()
        
        if self.showPageNumber {
            pageNumberLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 56, height: 28))
            pageNumberLabel.textColor = UIColor.colorWithRGB(0xFFFFFF, alpha: 1)
            pageNumberLabel.textAlignment = .Center
            pageNumberLabel.font = UIFont.systemFontOfSize(16.0) //.boldSystemFontOfSize(17.0)
        }
        
        Log.exit()
    }
    
    override func layoutSubviews() {
        Log.enter()
        if let superView = self.superview {
            self.frame = superView.frame
        }
        setupScrollView()
        //setupPageControl()
        if self.showPageNumber {
            setupPageNumber()
        }
        
        setupPhotos()
        
        Log.exit()
    }
    
    func setupScrollView() {
        Log.enter()
        scrollView.frame = CGRect(origin: CGPointZero, size: self.frame.size)
        self.addSubview(scrollView)
        Log.exit()
    }
    
    func setupPageControl() {
        Log.enter()
        pageControl.frame = CGRect(x: 0, y: scrollView.frame.size.height - 28, width: 28, height: 28)
        self.addSubview(pageControl)
        Log.exit()
    }
    
    func setupPageNumber() {
        Log.enter()
        pageNumberLabel.frame = CGRect(x: (scrollView.frame.size.width - 56) / 2, y: scrollView.frame.size.height - 28, width: 56, height: 28)
        self.addSubview(pageNumberLabel)
        Log.exit()

    }
    
    func addPlaceholderImage() {
        let imageView = UIImageView(frame: scrollView.frame)
        imageView.clipsToBounds = true
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        imageView.image = placeholderImage
        let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:Selector("imageTapped:"))
        imageView.userInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
        
        self.scrollView.addSubview(imageView)
    }
    
    func setupPhotos() {
        Log.enter()
        let n = self.imageUrls.count
        let screenWidth = self.scrollView!.frame.width
        let screenHeight = self.scrollView!.frame.height
        
        // reset
        self.imageViews = [UIImageView]()
        
        if imageUrls.isEmpty {
            addPlaceholderImageView(CGRectMake(0, 0, screenWidth, screenHeight))
            self.scrollView.contentSize = CGSizeMake(screenWidth, 0)
            
        } else {
            
            for i in 0..<n {
                let imageViewFrame = CGRect(x: screenWidth * CGFloat(i), y: 0, width: screenWidth, height: screenHeight)
                let imageUrl = self.imageUrls[i]
                addSubImageView(imageViewFrame, imageURL: imageUrl)
            }
            
            self.scrollView.contentSize = CGSizeMake(screenWidth * CGFloat(imageUrls.count), 0)
            self.pageControl.numberOfPages = imageUrls.count
        }

        self.addTitleOverlay(self.scrollView)
        
        if self.showPageNumber {
            self.addPageOverlay(self.scrollView)
            updatePageNumber()
        }
    }
    
    func addSubImageView(imageViewFrame: CGRect, imageURL: String) {
        let url = NSURL(string: imageURL)!
        let size = imageViewFrame.size
        let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:Selector("imageTapped:"))
        let imageView = UIImageView(frame: imageViewFrame)
        imageView.clipsToBounds = true
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        imageView.userInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
        imageView.af_setImageWithURL(url, placeholderImage: self.placeholderImage, filter: AspectScaledToFillSizeFilter(size: size), imageTransition: .None)
        
        self.imageViews.append(imageView)
        self.scrollView!.addSubview(imageView)
    }
    
    func addPlaceholderImageView(imageViewFrame: CGRect) {
        let imageView = UIImageView(frame: imageViewFrame)
        imageView.clipsToBounds = true
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        imageView.image = placeholderImage
        
        self.imageViews.append(imageView)
        self.scrollView!.addSubview(imageView)
    }
    
    let titleBackground = CAGradientLayer()
    
    private func addTitleOverlay(view: UIScrollView) {
        ///Gradient layer
        let gradientColors = [UIColor.blackColor().CGColor, UIColor.clearColor().CGColor]
        let gradientLocations = [0.0, 1.0]
        
        let layerRect = CGRect(x: view.bounds.origin.x, y: view.bounds.origin.y, width: view.contentSize.width, height: view.bounds.width * 188/1441)
        titleBackground.frame = layerRect
        titleBackground.colors = gradientColors
        titleBackground.locations = gradientLocations
        titleBackground.opacity = 0.7
        
        view.layer.addSublayer(titleBackground)
    }
    
    let pageBackground = CAGradientLayer()
    
    private func addPageOverlay(view: UIScrollView) {
        ///Gradient layer
        let gradientColors = [UIColor.clearColor().CGColor, UIColor.blackColor().CGColor]
        let gradientLocations = [0.0, 1.0]
        
        let layerRect = CGRect(x: view.bounds.origin.x, y: view.bounds.height - (view.bounds.width * 148/1441), width: view.contentSize.width, height: view.bounds.width * 148/1441)
        pageBackground.frame = layerRect
        pageBackground.colors = gradientColors
        pageBackground.locations = gradientLocations
        pageBackground.opacity = 0.1
        
        view.layer.addSublayer(pageBackground)
    }
    
    func updatePageNumber() {
        if self.imageUrls.isEmpty {
            pageNumberLabel.text = ""
            return
        }
        
        if let pageNumberLabel = self.pageNumberLabel {
            let pageNumber = self.pageControl.currentPage + 1
            pageNumberLabel.text = "\(pageNumber)/\(pageControl.numberOfPages)"
        }
    }
}

extension CarouselView  {
    
    @objc private func imageTapped(img: UIImageView) {
        
        print("imageTapped---")
        
        if let tapHandler = tapHandler {
            tapHandler()
        }
    }
}

extension CarouselView: UIScrollViewDelegate  {
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        self.pageControl.currentPage = Int(scrollView.contentOffset.x / self.scrollView.frame.size.width + 0.5)
        
        if self.showPageNumber {
            updatePageNumber()
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
    }
    
}