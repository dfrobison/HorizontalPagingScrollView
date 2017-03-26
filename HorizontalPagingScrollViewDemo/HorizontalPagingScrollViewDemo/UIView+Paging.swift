//
// UIView+Paging.swift
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

extension UIView {
  private struct AssociatedKeys {
    static var pagingScrollViewReuseIdentifierKey = 0
    static var pagingScrollViewPageIndexKey = 0
  }
  
  var pagingScrollViewReuseIdentifier: String? {
    get {return objc_getAssociatedObject(self, &AssociatedKeys.pagingScrollViewReuseIdentifierKey) as? String}
    set {objc_setAssociatedObject(self, &AssociatedKeys.pagingScrollViewReuseIdentifierKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_COPY_NONATOMIC)}
  }
  
  var pagingScrollViewPageIndex: Int {
    get {
      guard let pageIndex = (objc_getAssociatedObject(self, &AssociatedKeys.pagingScrollViewPageIndexKey) as? Int) else {return 0}
      return pageIndex
    }
    set {objc_setAssociatedObject(self, &AssociatedKeys.pagingScrollViewPageIndexKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
  }
}
