//
//  XTIViewController+.swift
//  XTInputKit
//
//  Created by xt-input on 2018/1/19.
//  Copyright © 2018年 Input. All rights reserved.
//

import UIKit

/// 导航栏左右按钮点击回调
public protocol XTINavigationItemDelegate {
    func toucheNavigationBarButtonItem(_ position: XTINAVPOSITION)
}

// MARK: - ViewController (UINavigation)

// 导航栏左右两边枚举
public enum XTINAVPOSITION: String {
    case backLeft
    case left
    case right
}

public extension UIViewController {
    /// UnsafeRawPointer
    fileprivate struct XTIViewControllerKey {
        static var nextBackTitle = "XTInextBackTitle"
        static var nextBackColor = "XTInextBackColor"
        static var navigationTitle = "XTInavigationTitle"
        static var tabbarTitle = "XTItabbarTitle"
    }

    // MARK: - 设置下一界面的导航栏back按钮文案和颜色
    /// 下一级控制器导航栏返回按钮文案
    var xti_nextBackTitle: String? {
        set {
            if xti_nextBackTitle != newValue {
                objc_setAssociatedObject(self, &XTIViewControllerKey.nextBackTitle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_COPY_NONATOMIC)
                var backItem = navigationItem.backBarButtonItem
                if backItem == nil {
                    backItem = UIBarButtonItem()
                }
                backItem?.title = newValue
                navigationItem.backBarButtonItem = backItem
            }
        }
        get {
            let title = objc_getAssociatedObject(self, &XTIViewControllerKey.nextBackTitle)
            return title as? String
        }
    }

    /// 下一级控制器导航栏返回按钮颜色
    var xti_nextBackColor: UIColor? {
        set {
            if xti_nextBackColor != newValue {
                objc_setAssociatedObject(self, &XTIViewControllerKey.nextBackColor, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_COPY_NONATOMIC)
                var backItem = navigationItem.backBarButtonItem
                if backItem == nil {
                    backItem = UIBarButtonItem()
                    backItem?.title = xti_navigationTitle
                }
                backItem?.tintColor = newValue
                navigationItem.backBarButtonItem = backItem
            }
        }
        get {
            let color = objc_getAssociatedObject(self, &XTIViewControllerKey.nextBackColor)
            return color as? UIColor
        }
    }

    // MARK: - 设置tabbar和navigation的标题
    /// 用于tabbar标题和navigation标题不一致的时候设置tabbar的标题，需要在viewDidLoad之前设置
    var xti_tabbarTitle: String? {
        set {
            if xti_tabbarTitle != newValue {
                objc_setAssociatedObject(self, &XTIViewControllerKey.tabbarTitle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_COPY_NONATOMIC)
                tabBarItem.title = newValue
            }
        }
        get {
            let title = objc_getAssociatedObject(self, &XTIViewControllerKey.tabbarTitle)
            return title as? String ?? self.title
        }
    }

    /**
     用于tabbar标题和navigation标题不一致的时候设置navigation的标题
     */
    var xti_navigationTitle: String? {
        set {
            if xti_navigationTitle != newValue {
                objc_setAssociatedObject(self, &XTIViewControllerKey.navigationTitle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_COPY_NONATOMIC)
                navigationItem.title = newValue
            }
        }
        get {
            let title = objc_getAssociatedObject(self, &XTIViewControllerKey.navigationTitle)
            return title as? String ?? self.title
        }
    }

    // MARK: - 通过StoryBoard初始化控制器
    /// 通过storyboard文件名字初始化控制器
    /// - Parameters:
    ///   - name: storyboard文件的名字
    ///   - withIdentifier: 控制器的storyboard id (默认，self.className)
    static func initwithstoryboard(_ name: String, withIdentifier: String? = nil) -> UIViewController {
        return UIStoryboard(name: name, bundle: nil).instantiateViewController(withIdentifier: withIdentifier ?? self.className)
    }

    fileprivate var navTitleColor: UIColor {
        return navigationController?.navigationBar.tintColor ?? UIColor.black
    }

    // MARK: - 设置导航栏的左右两个按钮
    @objc private func toucheLeftBarButtonItem() {
        (self as? XTINavigationItemDelegate)?.toucheNavigationBarButtonItem(.left)
    }

    @objc private func toucheRightBarButtonItem() {
        (self as? XTINavigationItemDelegate)?.toucheNavigationBarButtonItem(.right)
    }

    func xti_setBarButtonItem(_ position: XTINAVPOSITION,
                              title: String? = nil,
                              img: UIImage? = nil,
                              titleColor: UIColor? = nil) {
        if position == .left {
            self.xti_setBarButtonItem(position, title: title, img: img, titleColor: titleColor, action: #selector(toucheLeftBarButtonItem))
        } else {
            self.xti_setBarButtonItem(position, title: title, img: img, titleColor: titleColor, action: #selector(toucheRightBarButtonItem))
        }
    }

    /// 设置导航栏左右两边的按钮
    ///     图片和文字两个参数至少需要一个
    /// - Parameters:
    ///   - position: 位置
    ///   - title: 标题
    ///   - img: 图片
    ///   - titleColor: 文字颜色
    ///   - action: 响应的方法
    func xti_setBarButtonItem(_ position: XTINAVPOSITION,
                              title: String? = nil,
                              img: UIImage? = nil,
                              titleColor: UIColor? = nil,
                              action: Selector) {
        let color = titleColor ?? navTitleColor
        let navItem = navigationItem
        let navBtn = UIButton(type: .custom)
        let tempTitle = title ?? position.rawValue
        navBtn.setTitle(tempTitle, for: .normal)
        navBtn.setTitle(tempTitle, for: .highlighted)

        navBtn.setTitleColor(color, for: .normal)
        navBtn.setTitleColor(color, for: .highlighted)

        navBtn.xti.titleFont(UIFont.systemFont(ofSize: 15))

        navBtn.setImage(img, for: .normal)
        navBtn.setImage(img, for: .highlighted)
        navBtn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        navBtn.sizeToFit()

        let btnItem = UIBarButtonItem(customView: navBtn)
        if position != .right {
            navItem.leftItemsSupplementBackButton = position == .backLeft
            navItem.leftBarButtonItem = btnItem
        } else {
            navItem.rightBarButtonItem = btnItem
        }

        if responds(to: action) {
            navBtn.addTarget(self, action: action, for: .touchUpInside)
        }
    }

    // MARK: - ViewController (push、present, pop、dismiss)
    /// 跳转到VC，自动选择push或present
    /// 如果能push，就使用push
    /// - Parameters:
    ///   - VC: 要跳转的VC
    ///   - animated: 是否执行过渡动画
    func xti_pushOrPresentVC(_ VC: UIViewController, animated: Bool = true) {
        if let navVC = self.navigationController {
            navVC.pushViewController(VC, animated: animated)
        } else {
            present(VC, animated: animated, completion: nil)
        }
    }

    /// 关闭当前控制器，无需考虑当前控制器出现的方式(push or present)
    /// - Parameters:
    ///   - animated: 是否执行过渡动画
    ///   - completion: 如果是dismiss支持页面消失后闭包回调
    func xti_popOrDismiss(_ animated: Bool = true, completion: (() -> Void)? = nil) {
        if let navVC = self.navigationController {
            navVC.popViewController(animated: animated)
        } else {
            dismiss(animated: animated, completion: completion)
        }
    }

    // MARK: - 弹窗alertController
    func showMessage(title: String! = "提示", message: String! = nil, cancelTitle: String! = nil, confirmTitle: String! = "确认", action: ((_ index: Int) -> Void)! = nil) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        if cancelTitle != nil {
            alertController.addAction(UIAlertAction(title: confirmTitle, style: .cancel) { _ in
                if action != nil {
                    action(1)
                }
            })
        }
        alertController.addAction(UIAlertAction(title: confirmTitle, style: .default) { _ in
            var index = 1
            if cancelTitle != nil {
                index = 2
            }
            if action != nil {
                action(index)
            }
        })
        present(alertController, animated: true, completion: nil)
    }
}
