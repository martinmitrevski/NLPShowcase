//
//  WebViewController.swift
//  NLPShowcase
//
//  Created by Martin Mitrevski on 6/27/17.
//  Copyright © 2017 Martin Mitrevski. All rights reserved.
//

import UIKit

class WebViewController: UIViewController {
    
    var post: [String: String]!
    @IBOutlet weak var webView: UIWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let title = post["title"]
        self.title = title
        let url = post["url"]
        let request = URLRequest(url: URL(string: url!)!)
        webView.loadRequest(request)
    }

}
