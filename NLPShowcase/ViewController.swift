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
    let session = URLSession.shared
    private var wordCountings = Dictionary<String, Dictionary<String, Int>>()
    private var documentSizes = [String : Int]()
    var test = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "martinmitrevski.com"
        loadPosts()
        setupLoadingView()
    }
    
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
    
    func load(url urlString: String){
        let url = URL(string: urlString)
        let request = URLRequest(url: url!)
        let task = session.dataTask(with: request) { [unowned self] (data, response, error) in
            let html = String(data: data!, encoding: String.Encoding.utf8)
            self.words(inText: self.removeTags(fromHtml: html!), url: urlString)
        }
        task.resume()
    }
    
    private func removeTags(fromHtml html: String) -> String {
        return html.replacingOccurrences(of: "<[^>]+>",
                                         with: "",
                                         options: String.CompareOptions.regularExpression,
                                         range: nil)
    }
    
    private func words(inText text: String, url: String) {
        let tagger = NSLinguisticTagger(tagSchemes:[.lemma], options: 0)
        tagger.string = text
        let range = NSRange(location:0, length: text.utf16.count)
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace]
        var docSize = 0
        test = [String]()
        tagger.enumerateTags(in: range, unit: .word, scheme: .lemma, options: options)
        { tag, tokenRange, stop in
            if let lemma = tag?.rawValue {
                test.append(lemma)
                docSize += 1
                if wordCountings[lemma] == nil {
                    wordCountings[lemma] = Dictionary<String, Int>()
                }
                if wordCountings[lemma]![url] == nil {
                    wordCountings[lemma]![url] = 0
                }
                wordCountings[lemma]![url] = wordCountings[lemma]![url]! + 1
            }
        }
        documentSizes[url] = docSize
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        }
        let post = posts[indexPath.row]
        cell?.textLabel?.text = post["title"]
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedRow = indexPath
        var result = [String : Double]()
        let url = "https://martinmitrevski.com/2016/10/12/swift-class-diagrams-and-more/"
        loadingView.show()
        for word in test {
            result[word] = tfIdf(urlString: url,
                                 word: word,
                                 wordCountings: wordCountings,
                                 totalWordCount: documentSizes[url]!,
                                 totalDocs: posts.count)
        }
        let r = result.sorted(by: { (arg0, arg1) -> Bool in
            let (_, value1) = arg0
            let (_, value2) = arg1
            return value1 > value2
        })
        
        print(r)
        //self.performSegue(withIdentifier: "showWebView", sender: self)
    }
    
    // MARK: Seque
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showWebView" {
            let next = segue.destination as! WebViewController
            next.post = posts[selectedRow!.row]
            selectedRow = nil
        }
    }
}

