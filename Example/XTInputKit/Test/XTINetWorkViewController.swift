//
//  XTINetWorkViewController.swift
//  XTInputKit
//
//  Created by Input on 2018/3/19.
//  Copyright © 2018年 input. All rights reserved.
//

import UIKit
import XTInputKit
import HandyJSON

class XTINetWorkViewController: UIViewController, UITextViewDelegate {
    var request: XTITestRequest!

    @IBOutlet var resultTextView: UITextView!
    var resultString: String! {
        didSet {
            resultTextView.text = resultTextView.text + resultString
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        xti_navigationTitle = "网络请求"
        XTINetWorkConfig.iSLogRawData = false
        XTINetWorkConfig.defaultHostName = "design.tcoding.cn" // 设置默认的网络请求域名
        XTINetWorkConfig.defaultHttpScheme = .http
        XTINetWorkConfig.defaultSignature = { (parameters) -> String in // 设置所有的接口的签名方法
            loger.debug(parameters)
            return "signature=signature"
        }
        resultTextView.delegate = self
//        loger.debug(XTITool.compareAppVersion("2.1.0"))
//        loger.debug(XTITool.compareAppVersion("1.12.0"))
//        loger.debug(XTITool.compareAppVersion("1.21.1"))
//        loger.debug(XTITool.compareAppVersion("1.1.1"))
//        loger.debug(XTITool.compareAppVersion("1.1"))
//        loger.debug(XTITool.compareAppVersion("1.1.0"))
        resultTextView.addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        loger.debug(keyPath)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func clickRequestButton(_ sender: UIButton) {
        request = XTITestRequest()
        request.bundelID = "1234567890"
        DispatchQueue.XTI.mainAsyncAfter(3) {
            self.request.send(success: {[weak self] _, result in
                self?.resultString = loger.debug(result)
                if let res = result as? XTITestResult {
                    self?.resultString = loger.debug(res.toJSON()!)
                }
            }) { [weak self] _, error in
                if let strongSelf = self {
                    strongSelf.resultString = loger.warning(error?.localizedDescription)
                }
            }
            self.request.send(success: {[weak self] _, result in
                if let res = result as? HandyJSON {
                    self?.resultString = loger.debug(res.toJSON()!)
                }
            }) { [weak self] _, error in
                if let strongSelf = self {
                    strongSelf.resultString = loger.warning(error?.localizedDescription)
                }
            }
            self.request.send(success: {[weak self] _, result in
                if let res = result as? XTITestResult {
                    self?.resultString = loger.debug(res.toJSONString()!)
                }
            }) { [weak self] _, error in
                if let strongSelf = self {
                    strongSelf.resultString = loger.warning(error?.localizedDescription)
                }
            }
            self.request.send(success: {[weak self] _, result in
                if let res = result as? XTITestResult {
                    self?.resultString = loger.debug(res.toJSON()!)
                }
            }) { [weak self] _, error in
                if let strongSelf = self {
                    strongSelf.resultString = loger.warning(error?.localizedDescription)
                }
            }
        }
        
        let p1: [String: Any] = ["test": "\([11111,12312312])"]
        XTITest1Request.shared.post(serviceName:XTINetWorkServer.User.login.value, parameters: p1, resultClass: XTITestResult.self, success: { [weak self] _, result in
            if let res = result as? XTITestResult {
                if let strongSelf = self {
                    strongSelf.resultString = loger.debug(res.toJSON()!)
                }
            }
        }) { [weak self] _, error in
            if let strongSelf = self {
                strongSelf.resultString = loger.warning(error?.localizedDescription)
            }
        }

        let p2: [String: Any] = ["bundelID": "22222"]

        XTIBaseRequest().get(url: "http://design.tcoding.cn/rxswift/login/index", parameters: p2, resultClass: XTITestResult.self, success: { [weak self] request, result in
            if let res = result as? XTITestResult {
                if let strongSelf = self {
                    strongSelf.resultString = loger.debug(res.toJSON()!)
                }
            }
        }) { [weak self] _, error in
            if let strongSelf = self {
                strongSelf.resultString = loger.warning(error?.localizedDescription)
            }
        }

        XTIBaseRequest().get(url: "http://design.21321tcoding.cn/123123123", parameters: p2, resultClass: XTITestResult.self, completed: { [weak self] _, result, error in
            if let res = result as? XTITestResult {
                if let strongSelf = self {
                    strongSelf.resultString = loger.debug(res.toJSON()!)
                }
            } else {
                if let strongSelf = self {
                    strongSelf.resultString = loger.warning(error?.localizedDescription)
                }
            }
        })
    }

    // MARK: -UITextViewDelegate

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return false
    }

    deinit {
        loger.debug(self)
    }
}
