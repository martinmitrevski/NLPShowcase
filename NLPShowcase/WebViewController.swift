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
    var keywords: [String]!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var tags: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = postTitle
        tags.text = keywords.joined(separator: " ")
        webView.loadHTMLString(html, baseURL: nil)
    }

}
