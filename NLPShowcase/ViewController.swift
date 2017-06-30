//
//  ViewController.swift
//  NLPShowcase
//
//  Created by Martin Mitrevski on 6/27/17.
//  Copyright © 2017 Martin Mitrevski. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    private var posts: [[String : String]]!
    private let cellIdentifier = "PostCell"
    private var selectedRow: IndexPath?
    private var loadingView: LoadingView!
    private let session = URLSession.shared
    private var wordCountings = Dictionary<String, Dictionary<String, Int>>()
    private var documentSizes = [String : Int]()
    private var selectedHtml: String?
    private var keywords: [String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadPosts()
        setupLoadingView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "martinmitrevski.com"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.title = ""
    }
    
    // MARK: private
    
    private func loadPosts() {
        let fileUrl = Bundle.main.url(forResource: "posts", withExtension: "json")
        do {
            let data = try Data(contentsOf: fileUrl!)
            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                as! [String: Array<[String : String]>]
            posts = json["posts"]
            preloadSearchData()
        } catch {
            print("error loading posts")
        }
    }
    
    private func preloadSearchData() {
        for post in posts {
            let url = post["url"]!
            load(url: url)
        }
    }
    
    private func setupLoadingView() {
        loadingView = Bundle.main
            .loadNibNamed("LoadingView", owner: self, options: nil)?[0] as! LoadingView
        loadingView.frame = self.view.frame
        loadingView.isHidden = true
        self.view.addSubview(loadingView)
    }
    
    private func request(fromUrlString urlString: String) -> URLRequest {
        let url = URL(string: urlString)
        let request = URLRequest(url: url!)
        return request
    }
    
    private func load(url urlString: String){
        let task = session.dataTask(with: self.request(fromUrlString: urlString))
        { [unowned self] (data, response, error) in
            let html = String(data: data!, encoding: String.Encoding.utf8)
            var docSize = 0
            self.words(inText: removeTags(fromHtml: html!),
                       url: urlString,
                       action: { [unowned self] tag, tokenRange, stop, url in
                if let lemma = tag?.rawValue {
                    docSize += 1
                    if self.wordCountings[lemma] == nil {
                        self.wordCountings[lemma] = Dictionary<String, Int>()
                    }
                    if self.wordCountings[lemma]![url] == nil {
                        self.wordCountings[lemma]![url] = 0
                    }
                    self.wordCountings[lemma]![url] = self.wordCountings[lemma]![url]! + 1
                }
            })
            self.documentSizes[urlString] = docSize
        }
        task.resume()
    }
    
    private func words(inText text: String,
                       url: String,
                       action: @escaping (NSLinguisticTag?,
                                          NSRange,
                                          UnsafeMutablePointer<ObjCBool>,
                                          String) -> Swift.Void) {
        let tagger = NSLinguisticTagger(tagSchemes:[.lemma], options: 0)
        tagger.string = text
        let range = NSRange(location:0, length: text.utf16.count)
        let options: NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .lemma, options: options)
        { tag, tokenRange, stop in
            action(tag, tokenRange, stop, url)
        }
    }
    
    private func sort(result: [String : Double]) -> [String] {
        let sorted = result.sorted(by: { (arg0, arg1) -> Bool in
            let (_, value1) = arg0
            let (_, value2) = arg1
            return value1 > value2
        }).map({ (arg) -> String in
            let (title, _) = arg
            return title
        })
        return sorted
    }
    
    private func extractKeywordsTask(fromUrlString urlString: String) -> URLSessionDataTask {
        var result = [String : Double]()
        let task = session.dataTask(with: self.request(fromUrlString: urlString))
        { [unowned self] (data, response, error) in
            self.selectedHtml = String(data: data!, encoding: String.Encoding.utf8)
            self.words(inText: removeTags(fromHtml: self.selectedHtml!),
                       url: urlString,
                       action: { [unowned self] tag, tokenRange, stop, url in
                        if let lemma = tag?.rawValue {
                            result[lemma] = tfIdf(urlString: urlString,
                                                  word: lemma,
                                                  wordCountings: self.wordCountings,
                                                  totalWordCount: self.documentSizes[url]!,
                                                  totalDocs: self.posts.count)
                        }
            })
            
            DispatchQueue.main.sync {
                self.keywords = Array(self.sort(result: result)[0..<10])
                self.loadingView.hide()
                self.performSegue(withIdentifier: "showWebView", sender: self)
            }
        }
        return task
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        }
        let post = posts[indexPath.row]
        let title = post["title"]!
        cell?.textLabel?.text = title
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedRow = indexPath
        let post = posts[indexPath.row]
        let urlString = post["url"]!
        loadingView.show()
        extractKeywordsTask(fromUrlString: urlString).resume()
    }
    
    // MARK: Seque
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showWebView" {
            let next = segue.destination as! WebViewController
            next.postTitle = posts[selectedRow!.row]["title"]
            next.html = selectedHtml
            next.keywords = keywords
            selectedRow = nil
            selectedHtml = nil
            keywords = nil
        }
    }
}

