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
    
    var placeholderImage: UIImage = UIImage(named: "house_img")!
    
    var imageUrls = [String]()
    
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
        
        pageNumberLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 56, height: 28))
        pageNumberLabel.textColor = UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
        pageNumberLabel.textAlignment = .Right
        pageNumberLabel.font = UIFont.boldSystemFontOfSize(18.0)
        
        Log.exit()
    }
    
    override func layoutSubviews() {
        Log.enter()
        if let superView = self.superview {
            self.frame = superView.frame
        }
        setupScrollView()
        //setupPageControl()
        setupPageNumber()
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
        pageNumberLabel.frame = CGRect(x: scrollView.frame.size.width - 68, y: scrollView.frame.size.height - 40, width: 56, height: 28)
        self.addSubview(pageNumberLabel)
        Log.exit()

    }
    
    func setupPhotos() {
        Log.enter()
        
        let scrollViewWidth = scrollView.frame.size.width
        let scrollViewHeight = scrollView.frame.size.height
        let size = self.scrollView.frame.size
        
        for (var i = 0; i < imageUrls.count; i++){
            
            let imageView = UIImageView(frame: CGRectMake(CGFloat(i) * scrollViewWidth, 0, scrollViewWidth, scrollViewHeight))
            imageView.tag = i
            imageView.clipsToBounds = true
            imageView.contentMode = UIViewContentMode.ScaleAspectFill
            imageView.af_setImageWithURL(NSURL(string: imageUrls[i])!, placeholderImage: self.placeholderImage, filter: AspectScaledToFillSizeFilter(size: size), imageTransition: .None)
            let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:Selector("imageTapped:"))
            imageView.userInteractionEnabled = true
            imageView.addGestureRecognizer(tapGestureRecognizer)
            
            self.scrollView.addSubview(imageView)
        }
        
        self.scrollView.contentSize = CGSizeMake(scrollViewWidth * CGFloat(imageUrls.count), 0)
        self.pageControl.numberOfPages = imageUrls.count
        
        let pageNumber = self.pageControl.currentPage + 1
        pageNumberLabel.text = "\(pageNumber)/\(pageControl.numberOfPages)"
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
        
        let pageNumber = self.pageControl.currentPage + 1
        pageNumberLabel.text = "\(pageNumber)/\(pageControl.numberOfPages)"
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
    }
    
}