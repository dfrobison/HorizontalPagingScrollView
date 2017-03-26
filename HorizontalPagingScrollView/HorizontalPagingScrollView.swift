//
// HorizontalPagingScrollView.swift
//
// Copyright(c) 2017 Doug Robison
// Copyright (c) 2013 Hilton Campbell (Objective C version)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
import UIKit

//
// Protocols
//
@objc protocol HorizontalPagingScrollViewDelegate: NSObjectProtocol, UIScrollViewDelegate {
  @objc optional func pagingScrollView(pagingScrollView: HorizontalPagingScrollView, didScrollToPageAtIndex index: Int)
  @objc optional func pagingScrollViewWillBeginDragging(_ pagingScrollView: HorizontalPagingScrollView)
  @objc optional func pagingScrollViewDidScroll(_ pagingScrollView: HorizontalPagingScrollView)
  @objc optional func pagingScrollViewDidFinishScrolling(_ pagingScrollView: HorizontalPagingScrollView)
  @objc optional func pagingScrollView(_ pagingScrollView: HorizontalPagingScrollView, layoutPageAtIndex index: Int)
  @objc optional func pagingScrollView(_ pagingScrollView: HorizontalPagingScrollView, didEndDisplayingPage page: UIView, atIndex index: Int)
}

protocol HorizontalPagingScrollViewDataSource: NSObjectProtocol {
  func numberOfPagesInPagingScrollView(_ pagingScrollView: HorizontalPagingScrollView) -> Int
  func pagingScrollView(_ pagingScrollView: HorizontalPagingScrollView, pageForIndex index: Int) -> UIView
}

//
// Classes
//
class HorizontalPagingScrollView: UIView {
  typealias HorizontalPagingInternalScrollViewLayoutSubviewsDelegate = () -> Void
  
  class HorizontalPagingInternalScrollView: UIScrollView {
    
    var _layoutSubviewsDelegate: HorizontalPagingInternalScrollViewLayoutSubviewsDelegate?
    
    override func layoutSubviews() {
      super.layoutSubviews()
      _layoutSubviewsDelegate?()
    }
  }
  
  private enum Constants {
    static let interpageSpacing: CGFloat = 0
  }
  
  weak var _delegate: HorizontalPagingScrollViewDelegate?
  weak var _dataSource: HorizontalPagingScrollViewDataSource?
  var _interpageSpacing = Constants.interpageSpacing
  var _pageInsets = UIEdgeInsets()
  var _numberOfPreloadedPagesOnEachSide = 0
  var _isInfiniteScroll = false
  var _currentPageIndex = 0
  var _scrollView: HorizontalPagingInternalScrollView!
  var _visiblePageSet = Set<UIView>()
  var _classByReuseIdentifier = [String:UIView.Type]()
  var _reusablePageSetByReuseIdentifier = [String:Set<UIView>]()
  var _isInLayoutSubviews = false
  
  var dataSource: HorizontalPagingScrollViewDataSource? {
    get {return _dataSource}
    set {_dataSource = newValue}
  }
  
  var delegate: HorizontalPagingScrollViewDelegate? {
    get {return _delegate}
    set {_delegate = newValue}
  }
  
  var interpageSpacing: CGFloat {
    get {return _interpageSpacing}
    set {
      _interpageSpacing = (newValue < 0) ? 0 : newValue
      setNeedsLayout()
    }
  }
  
  var pageInsets: UIEdgeInsets {
    get {return _pageInsets}
    set {_pageInsets = newValue}
  }
  
  var numberOfPreloadedPagesOnEachSide: Int {
    get {return _numberOfPreloadedPagesOnEachSide}
    set {_numberOfPreloadedPagesOnEachSide = (newValue < 0) ? 0 : newValue}
  }
  
  var isInfiniteScroll: Bool {
    get {return _isInfiniteScroll}
    set {_isInfiniteScroll = newValue}
  }
  
  var currentPageIndex: Int {
    get {return _currentPageIndex}
    set {_currentPageIndex = (newValue < 0) ? 0 : newValue}
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }
  
  override init(frame aRect: CGRect) {
    super.init(frame: aRect)
    initialize()
  }
  
  func initialize() {
    clipsToBounds = true
    autoresizingMask = [.flexibleWidth, .flexibleHeight]
    
    _scrollView = HorizontalPagingInternalScrollView(frame: frameForScrollView())
    _scrollView.scrollsToTop = false
    _scrollView.isPagingEnabled = true
    _scrollView.showsVerticalScrollIndicator = false
    _scrollView.showsHorizontalScrollIndicator = false
    _scrollView.delegate = self
    _scrollView.clipsToBounds = false
    _scrollView._layoutSubviewsDelegate = {self.performInfiniteScrollJumpIfNecessary()}
    
    addSubview(_scrollView)
  }
  
  func frameForScrollView() -> CGRect {
    var frame = bounds
    
    frame.origin.x += pageInsets.left - interpageSpacing / 2
    frame.size.width += interpageSpacing - pageInsets.left - pageInsets.right
    
    return frame
  }
  
  func performInfiniteScrollJumpIfNecessary() {
    guard let dataSource = _dataSource else {
      return
    }
    
    if isInfiniteScroll {
      let numberOfPages = dataSource.numberOfPagesInPagingScrollView(self)
      let numberOfActualPages = numberOfPages + numberOfInfiniteScrollPages()
      let currentPageIndex = Int(Float(_scrollView.contentOffset.x / _scrollView.bounds.size.width).rounded())
      let numberOfPagesInPagingScrollView = dataSource.numberOfPagesInPagingScrollView(self)
      
      if currentPageIndex < numberOfInfiniteScrollPages() / 2 {
        // Perform an "infinite scroll" jump
        let pageIndex = numberOfPagesInPagingScrollView + currentPageIndex % numberOfPagesInPagingScrollView
        let pageDifference = pageIndex - currentPageIndex;
        _scrollView.contentOffset = CGPoint(x: _scrollView.contentOffset.x + CGFloat(pageDifference) * _scrollView.bounds.size.width, y: _scrollView.contentOffset.y)
        
      } else if currentPageIndex > numberOfActualPages - 1 - numberOfInfiniteScrollPages() / 2 {
        let pageIndex = currentPageIndex % numberOfPagesInPagingScrollView
        let pageDifference = currentPageIndex - pageIndex;
        _scrollView.contentOffset = CGPoint(x: _scrollView.contentOffset.x - CGFloat(pageDifference) * _scrollView.bounds.size.width, y: _scrollView.contentOffset.y)
      }
    }
  }
  
  func frameForPageAtActualIndex(index: Int) -> CGRect {
    var pageFrame = UIEdgeInsetsInsetRect(self.bounds, self.pageInsets)
    
    pageFrame.origin.x = (frameForScrollView().size.width * CGFloat(index)) + interpageSpacing / 2
    
    return pageFrame
  }
  
  override func layoutSubviews() {
    // Guard against unwanted reentrant behavior
    _isInLayoutSubviews = true
    
    super.layoutSubviews()
    
    let frameForScrollView = self.frameForScrollView()
    
    if !_scrollView.frame.equalTo(frameForScrollView) {
      let currentPageIndex = _currentPageIndex
      let numberOfPages = _dataSource?.numberOfPagesInPagingScrollView(self) ?? 0
      let numberOfActualPages = numberOfPages + numberOfInfiniteScrollPages()
      
      _scrollView.frame = frameForScrollView
      _scrollView.contentSize = CGSize(width: frameForScrollView.size.width * CGFloat(numberOfActualPages), height: frameForScrollView.size.height)
      _scrollView.contentOffset = CGPoint(x: frameForScrollView.size.width * CGFloat(currentPageIndex), y: 0)
      
      for page in _visiblePageSet {
        let index = indexOfPage(page)
        
        page.frame = frameForPageAtActualIndex(index: index)
        _delegate?.pagingScrollView?(self, layoutPageAtIndex: index)
      }
    }
    _isInLayoutSubviews = false
  }
  
  func numberOfInfiniteScrollPages() -> Int {
    guard let dataSource = _dataSource else {
      return 0
    }
    
    return isInfiniteScroll && dataSource.numberOfPagesInPagingScrollView(self) > 0 ? 2 : 0
  }
  
  func register(_ forClass: UIView.Type, forReuseIdentifier reuseIdentifier: String) {
    _classByReuseIdentifier[reuseIdentifier] = forClass
  }
  
  func dequeueReusablePageWithIdentifier(reuseIdentifier: String) -> UIView {
    var page = popPageFromReusablePageSetForReuseIdentifier(reuseIdentifier: reuseIdentifier)
    
    if page == nil {
      page = _classByReuseIdentifier[reuseIdentifier]!.init(frame: bounds)
      page?.pagingScrollViewReuseIdentifier = reuseIdentifier
    }
    return page!
  }
  
  func initReusablePageSetForReuseIdentifier(reuseIdentifier: String) {
    if _reusablePageSetByReuseIdentifier[reuseIdentifier] == nil {
      _reusablePageSetByReuseIdentifier[reuseIdentifier] = Set<UIView>()
    }
  }
  
  func addPageToReusablePageSetForReuseIdentifier(page: UIView, reuseIdentifier: String) {
    initReusablePageSetForReuseIdentifier(reuseIdentifier: reuseIdentifier)
    _reusablePageSetByReuseIdentifier[reuseIdentifier]?.insert(page)
  }
  
  func popPageFromReusablePageSetForReuseIdentifier(reuseIdentifier: String) -> UIView? {
    initReusablePageSetForReuseIdentifier(reuseIdentifier: reuseIdentifier)
    return _reusablePageSetByReuseIdentifier[reuseIdentifier]?.popFirst()
  }
  
  func pageAtIndex(index: Int) -> UIView? {
    guard let pageIndex = _visiblePageSet.index(where: { (page) -> Bool in
      return indexOfPage(page) == index
    }) else {
      return nil
    }
    
    return _visiblePageSet[pageIndex]
  }
  
  func indexOfPage(_ page: UIView) -> Int {
    return page.pagingScrollViewPageIndex
  }
  
  func visiblePages() -> Array<UIView> {
    return Array(_visiblePageSet)
  }
  
  func isDisplayingPageForIndex(index: Int) -> Bool {
    return _visiblePageSet.contains{ (page) -> Bool in
      return indexOfPage(page) == index
    }
  }
  
  func tilePages() {
    // Calculate which pages are visible
    let numberOfPages = _dataSource != nil ? _dataSource!.numberOfPagesInPagingScrollView(self) : 0
    let numberOfActualPages = numberOfPages + numberOfInfiniteScrollPages()
    let firstNeededActualPageIndex = Int(max(floor(Float(_scrollView.bounds.minX) / Float(_scrollView.bounds.width)) - Float(numberOfPreloadedPagesOnEachSide), 0))
    let lastNeededActualPageIndex =  Int(min(floor((Float(_scrollView.bounds.maxX) - 1) / Float(_scrollView.bounds.width)) + Float(numberOfPreloadedPagesOnEachSide), Float(numberOfActualPages - 1)))
    
    if _isInfiniteScroll && numberOfPages > 0 {
      // Move visible pages that are in the wrong place due to an "infinite scroll" jump
      for actualPageIndex in firstNeededActualPageIndex...lastNeededActualPageIndex {
        let index = actualPageIndex % numberOfPages
        
        if let page = pageAtIndex(index: index) {
          page.frame = frameForPageAtActualIndex(index: actualPageIndex)
        }
      }
    }
    
    // Recycle no-longer-visible pages
    var neededPageIndexes = Set<Int>()
    
    if (numberOfPages > 0) {
      for actualPageIndex in firstNeededActualPageIndex...lastNeededActualPageIndex {
        neededPageIndexes.insert(actualPageIndex % numberOfPages)
      }
    }
    
    var reusablePages = Set<UIView>()
    
    for page in _visiblePageSet {
      if numberOfPages == 0 || neededPageIndexes.contains(indexOfPage(page)) == false {
        let reuseIdentifier = page.pagingScrollViewReuseIdentifier
        
        if let reuseIdentifier = reuseIdentifier {
          addPageToReusablePageSetForReuseIdentifier(page: page, reuseIdentifier: reuseIdentifier)
        }
        
        reusablePages.insert(page)
        page.removeFromSuperview()
        _delegate?.pagingScrollView?(self, didEndDisplayingPage: page, atIndex: indexOfPage(page))
      }
    }
    
    _visiblePageSet.subtract(reusablePages)
    
    // Add missing pages
    if numberOfPages > 0 {
      for actualPageIndex in firstNeededActualPageIndex...lastNeededActualPageIndex {
        let index = actualPageIndex % numberOfPages
        
        if isDisplayingPageForIndex(index: index) == false {
          if let page = _dataSource?.pagingScrollView(self, pageForIndex: Int(index)) {
            _scrollView.addSubview(page)
            _visiblePageSet.insert(page)
            page.pagingScrollViewPageIndex = index
            page.frame = frameForPageAtActualIndex(index: actualPageIndex)
            _delegate?.pagingScrollView?(self, layoutPageAtIndex: index)
          }
        }
      }
    }
  }
  
  func reloadDataWithCurrentPageIndex(currentPageIndex: Int) {
    for page in _visiblePageSet {
      page.removeFromSuperview()
      _delegate?.pagingScrollView?(self, didEndDisplayingPage: page, atIndex: page.pagingScrollViewPageIndex)
    }
    
    _visiblePageSet.removeAll()
    _reusablePageSetByReuseIdentifier.removeAll()
    
    let frameForScrollView = self.frameForScrollView()
    let numberOfPagesInPagingScrollView = _dataSource?.numberOfPagesInPagingScrollView(self) ?? 0
    
    // No need to relayout everything just yet
    _isInLayoutSubviews = true
    _scrollView.contentSize = CGSize(width: frameForScrollView.size.width * CGFloat(numberOfPagesInPagingScrollView), height: frameForScrollView.size.height)
    _isInLayoutSubviews = false
    
    // Unset the delegate temporarily so that the current page index can be updated without triggering any page loading
    let previousDelegate = _scrollView.delegate
    _scrollView.delegate = nil
    setCurrentPageIndex(index: currentPageIndex, animated: false);
    _currentPageIndex = Int(currentPageIndex)
    _scrollView.delegate = previousDelegate
    
    tilePages()
  }
  
  func reloadData() {
    for page in _visiblePageSet {
      page.removeFromSuperview()
      _delegate?.pagingScrollView?(self, didEndDisplayingPage: page, atIndex: indexOfPage(page))
    }
    
    _visiblePageSet.removeAll()
    _reusablePageSetByReuseIdentifier.removeAll()
    
    let numberOfPages = _dataSource?.numberOfPagesInPagingScrollView(self) ?? 0
    let numberOfActualPages = numberOfPages + numberOfInfiniteScrollPages()
    let frameForScrollView = self.frameForScrollView()
    
    _scrollView.contentSize = CGSize(width: frameForScrollView.size.width * CGFloat(numberOfActualPages), height: frameForScrollView.size.height)
    tilePages()
  }
  
  func setCurrentPageIndex(index: Int, animated: Bool) {
    _scrollView.setContentOffset(CGPoint(x: CGFloat(index) * _scrollView.bounds.size.width, y: 0), animated: animated)
  }
  
  func setCurrentPageIndex(index: Int) {
    setCurrentPageIndex(index: index, animated: false)
  }
  
  func setCurrentPageIndex(index: Int, reloadData:Bool) {
    if reloadData {
      reloadDataWithCurrentPageIndex(currentPageIndex: Int(index))
    } else {
      setCurrentPageIndex(index: _currentPageIndex, animated: false)
    }
  }
  
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    let view = super.hitTest(point, with: event)
    
    return view == self ? _scrollView : view
  }
  
  func isDragging() -> Bool {
    return _scrollView.isDragging
  }
  
  func contentOffset() -> CGPoint {
    return _scrollView.contentOffset
  }
  
  func setContentOffset(contentOffset: CGPoint) {
    _scrollView.contentOffset = contentOffset
  }
}

extension HorizontalPagingScrollView: UIScrollViewDelegate {
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    _delegate?.pagingScrollViewWillBeginDragging?(self)
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if _isInLayoutSubviews == false {
      _delegate?.pagingScrollViewDidScroll?(self)
      
      let numberOfPages = _dataSource?.numberOfPagesInPagingScrollView(self) ?? 0
      let numberOfActualPages = numberOfPages + numberOfInfiniteScrollPages()
      let currentPageIndex = Int(numberOfPages > 0 ? max(min(Int(Float(_scrollView.contentOffset.x / _scrollView.bounds.size.width).rounded()), numberOfActualPages - 1), 0) % numberOfPages : 0)
      
      if _currentPageIndex != currentPageIndex {
        _currentPageIndex = currentPageIndex
        _delegate?.pagingScrollView?(pagingScrollView: self, didScrollToPageAtIndex: _currentPageIndex)
      }
      
      tilePages()
    }
  }
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    _delegate?.pagingScrollViewDidFinishScrolling?(self)
  }
}


