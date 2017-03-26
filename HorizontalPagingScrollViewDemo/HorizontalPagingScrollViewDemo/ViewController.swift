//
//  ViewController.swift
//  HorizontalPagingScrollViewDemo
//
import UIKit

class ViewController: UIViewController, HorizontalPagingScrollViewDataSource {
  
  var pagingScrollView: HorizontalPagingScrollView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    pagingScrollView = HorizontalPagingScrollView(frame: view.bounds)
    pagingScrollView.dataSource = self
    pagingScrollView.isInfiniteScroll = true
    pagingScrollView.register( UIView.self, forReuseIdentifier: "Page")
    
    view.addSubview(pagingScrollView)
    
    pagingScrollView.reloadData()
  }
  
  
  func numberOfPagesInPagingScrollView(_ pagingScrollView: HorizontalPagingScrollView) -> Int {
    return 3;
  }
  
  func pagingScrollView(_ pagingScrollView:HorizontalPagingScrollView, pageForIndex index: Int) -> UIView {
    let page = pagingScrollView.dequeueReusablePageWithIdentifier(reuseIdentifier: "Page")
    
    switch(index) {
    case 0: page.backgroundColor = UIColor.red
    case 1: page.backgroundColor = UIColor.green
    case 2: page.backgroundColor = UIColor.blue
      
    default: page.backgroundColor = UIColor.white
    }
    
    return page
  }
}


