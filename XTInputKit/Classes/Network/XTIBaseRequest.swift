//
//  XTIBaseRequest.swift
//  XTInputKit
//
//  Created by xt-input on 2018/3/16.
//  Copyright © 2018年 input. All rights reserved.
//

import Alamofire

/// 网络请求成功的回调
public typealias XTIRequestSuccessCallback = (Any?) -> Void
/// 网络请求失败的回调
public typealias XTIRequestErrorCallback = (Error?) -> Void
/// 网络请求完成的回调
public typealias XTIRequestCompleteCallback = (Any?, Error?) -> Void
/// 文件上传下载进度的回调
public typealias XTIProgressCallback = (Progress) -> Void

open class XTIBaseRequest: RequestInterceptor, XTISharedProtocol {
    fileprivate var _iSLogRawData: Bool {
        return iSLogRawData ?? XTINetWorkConfig.iSLogRawData
    }

    /// 是否打印接口响应的原始数据
    public var iSLogRawData: Bool?

    /// 是否需要签名
    public var isNeedSign: Bool = true

    fileprivate var _httpMethod: HTTPMethod {
        return httpMethod ?? HTTPMethod.post
    }

    /// HttpMethod，仅支持post or get，默认post
    public var httpMethod: HTTPMethod?

    fileprivate var _encoding: ParameterEncoding {
        return encoding ?? XTINetWorkConfig.defaultEncoding
    }

    public var encoding: ParameterEncoding?

    fileprivate var _httpScheme: XTIHttpScheme {
        return httpScheme ?? XTINetWorkConfig.defaultHttpScheme
    }

    /// http or https
    public var httpScheme: XTIHttpScheme?

    fileprivate var _hostName: String {
        if hostName == nil || hostName?.count == 0 {
            if XTINetWorkConfig.defaultHostName == nil || XTINetWorkConfig.defaultHostName.isEmpty {
                fatalError("服务器地址不能为空！")
            }
            return XTINetWorkConfig.defaultHostName
        }
        return hostName ?? ""
    }

    /// 服务器域名，包括端口号，80、443可以忽略
    public var hostName: String?

    /// 具体服务，域名后面的那一串
    public var serviceName: String?

    fileprivate var _serviceName: String {
        return serviceName ?? ""
    }

    fileprivate static var _httpManager: Session!
    fileprivate static var httpManager: Session {
        if _httpManager == nil {
            let configuration = URLSessionConfiguration.default
            configuration.headers = HTTPHeaders.default
            configuration.timeoutIntervalForRequest = XTINetWorkConfig.defaultTimeoutInterval
            configuration.httpMaximumConnectionsPerHost = XTINetWorkConfig.defaultHttpMaximumConnectionsPerHost
            _httpManager = Session(configuration: configuration)
        }
        return _httpManager
    }

    fileprivate var _httpManager: Session!
    fileprivate var httpManager: Session {
        if isUserSharedSession {
            return XTIBaseRequest.httpManager
        } else {
            return _httpManager
        }
    }

    fileprivate var parameters: XTIParameters?

    public var resultType: XTIBaseModelProtocol.Type?

    public var result: DataResponse<String>!

    public static var isUserSharedSession: Bool = true
    public var isUserSharedSession: Bool! {
        didSet {
            if !oldValue && isUserSharedSession {
                let configuration = URLSessionConfiguration.default
                configuration.headers = HTTPHeaders.default
                configuration.timeoutIntervalForRequest = XTINetWorkConfig.defaultTimeoutInterval
                configuration.httpMaximumConnectionsPerHost = XTINetWorkConfig.defaultHttpMaximumConnectionsPerHost
                _httpManager = Session(configuration: configuration)
            }
        }
    }

    public var fileType: String?
    public required init() {
        self.isUserSharedSession = XTIBaseRequest.isUserSharedSession
    }

    deinit {
        #if DEBUG
            XTILoger.default.info(self)
        #endif
    }

    /// 构造请求参数，如果是POST则放在body里面，如果是GET则拼接在URL后面
    ///
    /// - Returns: 参数字典
    open func buildParameters() -> XTIParameters {
        if parameters == nil {
            parameters = XTIParameters()
        }
        return parameters ?? XTIParameters()
    }

    /// 上传文件请求时重写它，
    /// 有 application/atom+xml, application/ecmascript, application/EDI-X12, application/EDIFACT, application/json, application/javascript, application/octet-stream, application/ogg, application/pdf, application/postscript, application/rdf+xml, application/rss+xml, application/soap+xml, application/font-woff, application/xhtml+xml, application/xml, application/xml-dtd, application/xop+xml, application/zip, application/gzip, audio/mp4, audio/mpeg, audio/ogg, audio/vorbis, audio/vnd.rn-realaudio, audio/vnd.wave, audio/webm, audio/x-flac, image/gif, image/jpeg, image/png, image/webp, image/svg+xml, image/tiff, model/example, model/iges, model/mesh, model/vrml, model/x3d+binary, model/x3d+vrml, model/x3d+xml, text/css, text/csv, text/html, text/plain, text/vcard, text/xml, video/mpeg, video/mp4, video/ogg, video/quicktime, video/webm, video/x-matroska, video/x-ms-wmv, video/x-flv ···等类型
    /// - Returns: 返回文件类型
    open func getFileType() -> String {
        return fileType ?? "image/jpeg"
    }

    /// 签名，如果继承，可以为每个请求实现不同的签名方式
    ///     该函数根据自己的需求实现，建议将参数字典转换成json字符串然后取这段字符串的签名
    /// 公共参数放置在请求头里面
    /// - Returns: 返回签名，格式："sign=sign"
    open func signature(_ parameters: XTIParameters?) -> String {
        if XTINetWorkConfig.defaultSignature != nil && isNeedSign {
            return XTINetWorkConfig.defaultSignature(parameters ?? XTIParameters())
        }
        return ""
    }
}

// MARK: - post请求

extension XTIBaseRequest {
    /// post网络请求，域名等信息使用XTINetWorkConfig的配置，只需要传入服务名和参数及回调的闭包，适用于一个方法管理一个网络请求
    ///
    /// - Parameters:
    ///   - serviceName: 服务名
    ///   - parameters: 参数
    ///   - resultType: 返回数据的模型，如果没有该参数则返回数据类型将优先解析成JSON对象，解析失败则是字符串
    ///   - errorCallback: 失败的回调
    ///   - successCallBack: 成功的回调XTIBaseModelProtocol>
    ///   - completedCallback: 请求完成的回调
    open func post(serviceName: String,
                   parameters: XTIParameters? = nil,
                   resultType: XTIBaseModelProtocol.Type? = nil,
                   success successCallBack: XTIRequestSuccessCallback? = nil,
                   error errorCallback: XTIRequestErrorCallback? = nil,
                   completed completedCallback: XTIRequestCompleteCallback? = nil) {
        send(.post, httpScheme: nil, hostName: nil, serviceName: serviceName, parameters: parameters, resultType: resultType, success: successCallBack, error: errorCallback, completed: completedCallback)
    }

    /// post网络请求，不使用XTINetWorkConfig的域名信息，适用于多台服务器网络请求
    ///
    /// - Parameters:
    ///   - url: 网络请求的地址
    ///   - parameters: 参数
    ///   - resultType: 返回数据的模型，如果没有该参数则返回数据类型将优先解析成JSON对象，解析失败则是字符串
    ///   - successCallBack: 成功的回调
    ///   - completedCallback: 请求完成的回调
    ///   - errorCallback: 失败的回调
    open func post(url: String,
                   parameters: XTIParameters? = nil,
                   resultType: XTIBaseModelProtocol.Type? = nil,
                   success successCallBack: XTIRequestSuccessCallback? = nil,
                   error errorCallback: XTIRequestErrorCallback? = nil,
                   completed completedCallback: XTIRequestCompleteCallback? = nil) {
        send(.post, url: url, parameters: parameters, resultType: resultType, success: successCallBack, error: errorCallback, completed: completedCallback)
    }
}

// MARK: - get请求

extension XTIBaseRequest {
    /// get网络请求，域名等信息使用XTINetWorkConfig的配置，只需要传入服务名和参数及回调的闭包，适用于一个方法管理一个网络请求
    ///
    /// - Parameters:
    ///   - serviceName: 服务名
    ///   - parameters: 参数
    ///   - resultType: 返回数据的模型，如果没有该参数则返回数据类型将优先解析成JSON对象，解析失败则是字符串
    ///   - errorCallback: 失败的回调
    ///   - successCallBack: 成功的回调
    ///   - completedCallback: 请求完成的回调
    open func get(serviceName: String? = nil,
                  parameters: XTIParameters? = nil,
                  resultType: XTIBaseModelProtocol.Type? = nil,
                  success successCallBack: XTIRequestSuccessCallback? = nil,
                  error errorCallback: XTIRequestErrorCallback? = nil,
                  completed completedCallback: XTIRequestCompleteCallback? = nil) {
        send(.get, httpScheme: nil, hostName: nil, serviceName: serviceName, parameters: parameters, resultType: resultType, success: successCallBack, error: errorCallback, completed: completedCallback)
    }

    /// get网络请求，不使用XTINetWorkConfig的域名信息，适用于多台服务器网络请求
    ///
    /// - Parameters:
    ///   - url: 网络请求的地址
    ///   - parameters: 参数
    ///   - resultType: 返回数据的模型，如果没有该参数则返回数据类型将优先解析成JSON对象，解析失败则是字符串
    ///   - errorCallback: 失败的回调
    ///   - completedCallback: 请求完成的回调
    open func get(url: String,
                  parameters: XTIParameters? = nil,
                  resultType: XTIBaseModelProtocol.Type? = nil,
                  success successCallBack: XTIRequestSuccessCallback? = nil,
                  error errorCallback: XTIRequestErrorCallback? = nil,
                  completed completedCallback: XTIRequestCompleteCallback? = nil) {
        send(.get, url: url, parameters: parameters, resultType: resultType, success: successCallBack, error: errorCallback, completed: completedCallback)
    }
}

// MARK: - 发出网络请求

extension XTIBaseRequest {
    /// 汇总的网络请求，除了回调都有默认参数，默认参数取XTINetWorkConfig里的配置，默认参数可以在初始化对象的时候设置，如果一个类管理一个接口可以在子类里设置所有的默认参数
    ///
    /// - Parameters:
    ///   - method: HttpMethod，仅支持post or get
    ///   - scheme: HttpScheme, http or https
    ///   - host: 域名    非约定端口的请求请带上端口号
    ///   - service: 服务名
    ///   - parameters: 参数，可以传递进去，如果使用一个类管理一个接口请在buildParameters方法里构造参数
    ///   - result: 返回数据的模型，如果没有该参数则返回数据类型将优先解析成JSON对象，解析失败则是字符串
    ///   - errorCallback: 失败的回调
    ///   - successCallBack: 成功的回调
    ///   - completedCallback: 请求完成的回调
    open func send(_ method: HTTPMethod? = nil,
                   httpScheme scheme: XTIHttpScheme? = nil,
                   hostName host: String? = nil,
                   serviceName service: String? = nil,
                   parameters: XTIParameters? = nil,
                   resultType: XTIBaseModelProtocol.Type? = nil,
                   success successCallBack: XTIRequestSuccessCallback? = nil,
                   error errorCallback: XTIRequestErrorCallback? = nil,
                   completed completedCallback: XTIRequestCompleteCallback? = nil) {
        let tempScheme = scheme ?? _httpScheme
        let tempHost = host ?? _hostName
        var tempServiceName = service ?? _serviceName
        if tempServiceName.first == "/" {
            tempServiceName.removeFirst()
        }
        let url = tempScheme.rawValue + tempHost.replacingOccurrences(of: "/", with: "") + "/" + tempServiceName
        send(method, url: url, parameters: parameters, resultType: resultType, success: successCallBack, error: errorCallback, completed: completedCallback)
    }

    /// 汇总的网络请求，默认参数取XTINetWorkConfig里的配置
    ///
    /// - Parameters:
    ///   - method: HttpMethod，仅支持post or get
    ///   - url: 网络地址
    ///   - parameters: 参数
    ///   - resultType: 返回数据的模型，如果没有该参数则返回数据类型将优先解析成JSON对象，解析失败则是字符串
    ///   - errorCallback: 失败的回调
    ///   - successCallBack: 成功的回调
    ///   - completedCallback: 请求完成的回调
    public func send(_ method: HTTPMethod? = nil,
                     url: String? = nil,
                     parameters: XTIParameters? = nil,
                     resultType: XTIBaseModelProtocol.Type? = nil,
                     success successCallBack: XTIRequestSuccessCallback? = nil,
                     error errorCallback: XTIRequestErrorCallback? = nil,
                     completed completedCallback: XTIRequestCompleteCallback? = nil) {
        guard let tempUrl = url else {
            xtiloger.warning("链接为空")
            return
        }
        let tempMethod = method ?? _httpMethod
        let tempParameters = parameters ?? buildParameters()
        var tempHeaders = XTINetWorkConfig.defaultopenHttpHeader
        let sign = signature(tempParameters)
        if sign != "" {
            tempHeaders["sign"] = sign
        }
        httpManager.request(tempUrl,
                            method: tempMethod,
                            parameters: tempParameters,
                            encoding: _encoding,
                            headers: tempHeaders).validate(statusCode: 200 ..< 300)
            .responseString { [weak self] res in
                if let strongSelf = self {
                    strongSelf.handleRequest(res, resultType: resultType, success: successCallBack, error: errorCallback, completed: completedCallback)
                }
            }
    }
}

// MARK: - 文件上传
extension XTIBaseRequest {
    /// 文件上传，适用于一个类管理一个接口，可以在子类里设置所有的默认参数
    ///
    /// - Parameters:
    ///   - resultType: 返回数据的模型，如果没有该参数则返回数据类型将优先解析成JSON对象，解析失败则是字符串
    ///   - progressCallback: 进度
    ///   - errorCallback: 失败的回调
    ///   - successCallBack: 成功的回调
    ///   - completedCallback: 请求完成的回调
    open func upload(_ resultType: XTIBaseModelProtocol.Type,
                     progressCallback: XTIProgressCallback? = nil,
                     successCallBack: XTIRequestSuccessCallback? = nil,
                     errorCallback: XTIRequestErrorCallback? = nil,
                     completed completedCallback: XTIRequestCompleteCallback? = nil) {
        let url = _httpScheme.rawValue + _hostName + _serviceName
        upload(url, parameters: buildParameters(), resultType: resultType, progress: progressCallback, success: successCallBack, error: errorCallback, completed: completedCallback)
    }

    /// 文件上传，适用于用单例一个方法管理一个请求
    ///     文件上传时请将文件转成Data放置在parameters里
    /// - Parameters:
    ///   - url: 上传的地址
    ///   - parameters: 参数
    ///   - resultType: 返回数据的模型，如果没有该参数则返回数据类型将优先解析成JSON对象，解析失败则是字符串
    ///   - progressCallback: 进度
    ///   - errorCallback: 失败的回调
    ///   - successCallBack: 成功的回调
    ///   - completedCallback: 请求完成的回调
    open func upload(_ url: String,
                     parameters: XTIParameters?,
                     resultType: XTIBaseModelProtocol.Type? = nil,
                     progress progressCallback: XTIProgressCallback? = nil,
                     success successCallBack: XTIRequestSuccessCallback? = nil,
                     error errorCallback: XTIRequestErrorCallback? = nil,
                     completed completedCallback: XTIRequestCompleteCallback? = nil) {
        let sign = signature(parameters)
        var tempHeaders = XTINetWorkConfig.defaultopenHttpHeader
        if sign != "" {
            tempHeaders["sign"] = sign
        }
        tempHeaders["Content-Type"] = "application/x-www-form-urlencoded; charset=utf-8"
        httpManager.upload(multipartFormData: { [weak self] data in
            if let strongSelf = self {
                parameters?.forEach { key, value in
                    if (value as? Data) == nil {
                        data.append("\(value)".data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: key)
                    } else {
                        data.append(value as! Data, withName: key, fileName: key, mimeType: strongSelf.getFileType())
                    }
                }
            }
        }, to: url, method: .post, headers: tempHeaders, interceptor: self)
            .uploadProgress(closure: progressCallback ?? { _ in }).validate(statusCode: 200 ..< 300)
            .responseString { [weak self] response in
                if let strongSelf = self {
                    strongSelf.handleRequest(response, resultType: resultType, success: successCallBack, error: errorCallback, completed: completedCallback)
                }
            }
    }
}

// MARK: - 请求结果处理
fileprivate extension XTIBaseRequest {
    func handleRequest(_ result: DataResponse<String>,
                       resultType: XTIBaseModelProtocol.Type? = nil,
                       success successCallBack: XTIRequestSuccessCallback? = nil,
                       error errorCallback: XTIRequestErrorCallback? = nil,
                       completed completedCallback: XTIRequestCompleteCallback? = nil) {
        outRawData(result)
        self.result = result
        var tempError: Error?
        var resultValue: Any?
        switch result.result {
        case let .success(value):
            if let tempResultType = (resultType ?? self.resultType) {
                resultValue = tempResultType.handleResult(value)
            } else {
                do {
                    resultValue = try JSONSerialization.jsonObject(with: value.data(using: String.Encoding.utf8) ?? Data(), options: JSONSerialization.ReadingOptions.mutableContainers)
                } catch {
                    resultValue = value
                }
            }
            break
        case let .failure(error):
            tempError = error
            break
        }
        requestCallback(resultValue, error: tempError, success: successCallBack, error: errorCallback, completed: completedCallback)
    }

    /// 网络请求结束后的结果处理
    ///
    /// - Parameters:
    ///   - result: 响应数据
    ///   - resultType: 返回数据的模型，如果没有该参数则返回数据类型将优先解析成JSON对象，解析失败则是字符串
    ///   - errorCallback: 失败的回调
    ///   - successCallBack: 成功的回调
    ///   - completedCallback: 请求完成的回调
    func requestCallback(_ result: Any?,
                         error: Error?,
                         success successCallBack: XTIRequestSuccessCallback? = nil,
                         error errorCallback: XTIRequestErrorCallback? = nil,
                         completed completedCallback: XTIRequestCompleteCallback? = nil) {
        if let tempCompletedCallback = completedCallback {
            tempCompletedCallback(result, error)
        }
        if let tempError = error {
            if let tempErrorCallback = errorCallback {
                tempErrorCallback(tempError)
            }
        } else {
            if let tempSuccessCallBack = successCallBack {
                tempSuccessCallBack(result)
            }
        }
    }
}

// MARK: - 文件下载
extension XTIBaseRequest {
    /// 文件下载(该方法仅适用于单个文件，如果文件很多推荐使用TYDownloadManager) <比较鸡肋>
    ///
    /// - Parameters:
    ///   - url: 文件地址
    ///   - filePath: 文件存放路径，如果为空则放置在/Library/Caches
    ///   - progressCallback: 下载进度回调
    ///   - errorCallback: 失败的回调
    ///   - successCallBack: 下载成功的回调
    ///   - errorCallback: 下载失败的回调
    public static func download(_ url: String,
                                filePath: URL? = nil,
                                progressCallback: XTIProgressCallback? = nil,
                                successCallBack: XTIRequestSuccessCallback? = nil,
                                error errorCallback: XTIRequestErrorCallback? = nil,
                                completed completedCallback: XTIRequestCompleteCallback? = nil) {
        let downloadManager = Session.default.download(url) { (_, response) -> (destinationURL: URL, options: DownloadRequest.Options) in
            var flieURL: URL
            let documentsURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            flieURL = documentsURL.appendingPathComponent(response.suggestedFilename!)
            if filePath != nil {
                flieURL = filePath!
            }
            return (flieURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        downloadManager.downloadProgress { progress in
            if let tempProgressCallback = progressCallback {
                tempProgressCallback(progress)
            }
        }.validate(statusCode: 200 ..< 300).responseString { result in
            let code = result.response?.statusCode ?? 0
            if code == 200 {
                if let tempSuccessCallBack = successCallBack {
                    tempSuccessCallBack(result)
                }
                if let tempCompletedCallback = completedCallback {
                    tempCompletedCallback(result, nil)
                }
            } else {
                let domain = HTTPURLResponse.localizedString(forStatusCode: code)
                let error = NSError(domain: domain, code: code, userInfo: nil)
                if let tempErrorCallback = errorCallback {
                    tempErrorCallback(error)
                }
                if let tempCompletedCallback = completedCallback {
                    tempCompletedCallback(nil, error)
                }
            }
        }
    }
}

// MARK: - 打印日志
extension XTIBaseRequest {
    /// 打印原始数据，可以在该函数里面读取Cookie的值
    ///
    /// - Parameter result: 原始数据
    open func outRawData(_ result: DataResponse<String>) {
        if _iSLogRawData {
            XTILoger.default.debug(result)
        }
    }
}
