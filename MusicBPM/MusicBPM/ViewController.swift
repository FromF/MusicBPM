//
//  ViewController.swift
//  MusicBPM
//
//  Created by 藤　治仁 on 2019/01/15.
//  Copyright © 2019 FromF.github.com. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var infomationLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        infomationLabel.text = "Please select Button."
    }

    @IBAction func BPM70ButtonAction(_ sender: Any) {
        analyze(bpmFilename: "70")
    }
    @IBAction func BPM80ButtonAction(_ sender: Any) {
        analyze(bpmFilename: "80")
    }
    @IBAction func BPM90ButtonAction(_ sender: Any) {
        analyze(bpmFilename: "90")
    }
    @IBAction func BPM100ButtonAction(_ sender: Any) {
        analyze(bpmFilename: "100")
    }
    
    private func analyze(bpmFilename:String) {
        let fileName = "BPM-\(bpmFilename)"
        let fileURL = URL(fileURLWithPath:Bundle.main.path(forResource: fileName, ofType: "mp3")!)
        let bpm = analyzeBPM().searchBPM(fileURL: fileURL)
        infomationLabel.text = "\(fileName).mp3 - BPM : \(bpm)"

    }

}

