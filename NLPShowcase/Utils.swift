//
//  Utils.swift
//  NLPShowcase
//
//  Created by Martin Mitrevski on 6/28/17.
//  Copyright © 2017 Martin Mitrevski. All rights reserved.
//

import Foundation

func tf(urlString: String,
        word: String,
        wordCountings: Dictionary<String, Dictionary<String, Int>>,
        totalWordCount: Int)
    -> Double {
    
    guard let wordCounting = wordCountings[word] else {
        return Double(Int.min)
    }
    
    guard let occurrences = wordCounting[urlString] else {
        return Double(Int.min)
    }
    
    return Double(occurrences) / Double(totalWordCount)
}

func idf(urlString: String,
         word: String,
         wordCountings: Dictionary<String, Dictionary<String, Int>>,
         totalDocs: Int)
    -> Double {
    
    guard let wordCounting = wordCountings[word] else {
        return 1
    }
    
    var sum = 0
    for (url, count) in wordCounting {
        if url != urlString {
            sum += count
        }
    }
    
    let factor = Double(totalDocs) / Double(sum)
    return log(factor)
}

func tfIdf(urlString: String,
           word: String,
           wordCountings: Dictionary<String, Dictionary<String, Int>>, 
           totalWordCount: Int,
           totalDocs: Int)
    -> Double {
    return tf(urlString: urlString,
              word: word,
              wordCountings: wordCountings,
              totalWordCount: totalWordCount)
        * idf(urlString: urlString,
              word: word, wordCountings: wordCountings,
              totalDocs: totalDocs)
}
