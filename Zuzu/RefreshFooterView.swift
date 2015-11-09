//
//  RefreshFooterView.swift
//  Zuzu
//
//  Created by eechih on 2015/10/23.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit

class RefreshFooterView: RefreshBaseView {
    
    class func footer() -> RefreshFooterView {
        let footer:RefreshFooterView  = RefreshFooterView(frame: CGRect(x: 0, y: 0, width: UIScreen.mainScreen().bounds.width,
            height: CGFloat(RefreshViewHeight)))
        
        return footer
    }
    
    var lastRefreshCount:Int = 0
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.statusLabel.frame = self.bounds
    }
    
    override func willMoveToSuperview(newSuperview: UIView!) {
        super.willMoveToSuperview(newSuperview)
        if (self.superview != nil) {
            self.superview!.removeObserver(self, forKeyPath: RefreshContentSize, context:nil)
        }
        if (newSuperview != nil) {
            newSuperview.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.New, context: nil)
            // 重新調整frame
            adjustFrameWithContentSize()
        }
    }
    
    //重寫調整frame
    func adjustFrameWithContentSize() {
        let contentHeight:CGFloat = self.scrollView.contentSize.height//
        let scrollHeight:CGFloat = self.scrollView.frame.size.height  - self.scrollViewOriginalInset.top - self.scrollViewOriginalInset.bottom
        var rect:CGRect = self.frame
        rect.origin.y = contentHeight > scrollHeight ? contentHeight : scrollHeight
        self.frame = rect
    }
    
    //監聽UIScrollView的屬性
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<()>) {
        if (!self.userInteractionEnabled || self.hidden){
            return
        }
        if RefreshContentSize == keyPath {
            adjustFrameWithContentSize()
        } else if RefreshContentOffset == keyPath {
            if self.State == RefreshState.Refreshing {
                return
            }
            adjustStateWithContentOffset()
        }
    }
    
    func adjustStateWithContentOffset() {
        let currentOffsetY:CGFloat  = self.scrollView.contentOffset.y
        let happenOffsetY:CGFloat = self.happenOffsetY()
        if currentOffsetY <= happenOffsetY {
            return
        }
        if self.scrollView.dragging {
            let normal2pullingOffsetY =  happenOffsetY + self.frame.size.height
            if self.State == RefreshState.Normal && currentOffsetY > normal2pullingOffsetY {
                self.State = RefreshState.Pulling
            } else if (self.State == RefreshState.Pulling && currentOffsetY <= normal2pullingOffsetY) {
                self.State = RefreshState.Normal
            }
        } else if (self.State == RefreshState.Pulling) {
            self.State = RefreshState.Refreshing
        }
    }
    
    
    override  var State:RefreshState {
        willSet {
            if  State == newValue {
                return
            }
            oldState = State
            setState(newValue)
        }
        didSet{
            switch State {
            case .Normal:
                self.statusLabel.text = RefreshFooterPullToRefresh
                if (RefreshState.Refreshing == oldState) {
                    self.arrowImage.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
                    UIView.animateWithDuration(RefreshSlowAnimationDuration, animations: {
                        self.scrollView.contentInset.bottom = self.scrollViewOriginalInset.bottom
                    })
                } else {
                    UIView.animateWithDuration(RefreshSlowAnimationDuration, animations: {
                        self.arrowImage.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
                    })
                }
                let deltaH:CGFloat = self.heightForContentBreakView()
                let currentCount:Int = self.totalDataCountInScrollView()
                if (RefreshState.Refreshing == oldState && deltaH > 0  && currentCount != self.lastRefreshCount) {
                    var offset:CGPoint = self.scrollView.contentOffset
                    offset.y = self.scrollView.contentOffset.y
                    self.scrollView.contentOffset = offset
                }
                
                break
            case .Pulling:
                self.statusLabel.text = RefreshFooterReleaseToRefresh
                UIView.animateWithDuration(RefreshSlowAnimationDuration, animations: {
                    self.arrowImage.transform = CGAffineTransformIdentity
                })
                break
            case .Refreshing:
                self.statusLabel.text = RefreshFooterRefreshing
                self.lastRefreshCount = self.totalDataCountInScrollView()
                UIView.animateWithDuration(RefreshSlowAnimationDuration, animations: {
                    var bottom:CGFloat = self.frame.size.height + self.scrollViewOriginalInset.bottom
                    let deltaH:CGFloat = self.heightForContentBreakView()
                    if deltaH < 0 {
                        bottom = bottom - deltaH
                    }
                    var inset:UIEdgeInsets = self.scrollView.contentInset
                    inset.bottom = bottom
                    self.scrollView.contentInset = inset
                })
                
                break
            default:
                break
                
            }
        }
    }
    
    
    func totalDataCountInScrollView() -> Int {
        var totalCount: Int = 0
        if self.scrollView is UITableView {
            let tableView:UITableView = self.scrollView as! UITableView
            
            for (var i: Int = 0; i < tableView.numberOfSections; i++) {
                totalCount = totalCount + tableView.numberOfRowsInSection(i)
            }
        } else if self.scrollView is UICollectionView {
            let collectionView:UICollectionView = self.scrollView as! UICollectionView
            for (var i: Int = 0; i < collectionView.numberOfSections(); i++){
                totalCount = totalCount + collectionView.numberOfItemsInSection(i)
            }
        }
        return totalCount
    }
    
    func heightForContentBreakView() -> CGFloat {
        let h: CGFloat = self.scrollView.frame.size.height - self.scrollViewOriginalInset.bottom - self.scrollViewOriginalInset.top
        return self.scrollView.contentSize.height - h
    }
    
    
    func happenOffsetY() -> CGFloat {
        let deltaH: CGFloat = self.heightForContentBreakView()
        if deltaH > 0 {
            return deltaH - self.scrollViewOriginalInset.top
        } else {
            return -self.scrollViewOriginalInset.top
        }
    }
    
    
    func addState(state: RefreshState) {
        self.State = state
    }
    
}
