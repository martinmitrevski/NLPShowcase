//
//  WebViewController.swift
//  NLPShowcase
//
//  Created by Martin Mitrevski on 6/27/17.
//  Copyright © 2017 Martin Mitrevski. All rights reserved.
//

import UIKit

class WebViewController: UIViewController {
    
    var postTitle: String!
    var html: String!
    @IBOutlet weak var webView: UIWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = title
        webView.loadHTMLString(html, baseURL: nil)
    }

}
