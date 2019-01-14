//
//  analyzeBPM.swift
//  MusicBPM
//
//  Created by 藤　治仁 on 2019/01/15.
//  Copyright © 2019 FromF.github.com. All rights reserved.
//

import UIKit
import AVFoundation

class analyzeBPM: NSObject {
    
    public let errorBPM = -1
    
    @objc public func searchBPM(fileURL:URL) -> Int {
        
        if !loadAudioData(fileURL: fileURL) {
            return errorBPM
        }
        
        if !calculateFrameVolume() {
            return errorBPM
        }
        if !caculateDiffVolume() {
            return errorBPM
        }
        
        return searchTempo()
    }
    
    // MARK: - オーディオデータ読み込み
    //参考サイト
    //https://qiita.com/programanx1/items/8912e60843bd824d74ce

    //object for audio file
    private var audioFile:AVAudioFile?
    //buffer for PCM data 便宜上AVAudioPCMBuffer型の変数を用意
    //クラス外から実際にバイナリデータにアクセスする際はbufferプロパティを使う。
    private var PCMBuffer:AVAudioPCMBuffer!
    //オーディオのバイナリデータを格納するためのbuffer, マルチチャンネルに対応するため、二次元配列になっています。
    private var buffer:[[Float]]! = Array<Array<Float>>()
    //オーディオデータの情報
    private var samplingRate:Double?
    private var nChannel:Int?
    private var nframe:Int?
    
    ///オーディオデータ読み込み
    ///
    /// - Parameter fileURL: オーディオのファイルパス
    /// - Returns: 実行結果
    private func loadAudioData(fileURL:URL) -> Bool {
        do {
            audioFile = try AVAudioFile(forReading: fileURL)
            samplingRate = audioFile?.fileFormat.sampleRate
            nChannel = Int(audioFile?.fileFormat.channelCount ?? 0)
        } catch {
            print("Error : loading audio file failed.")
        }
        
        guard let audioFile = audioFile else {
            return false
        }
        
        guard let nChannel = nChannel else {
            return false
        }
        
        nframe = Int(audioFile.length)
        
        guard let nframe = nframe else {
            return false
        }
        
        PCMBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(nframe))
        
        guard let floatChannelData = PCMBuffer.floatChannelData else {
            return false
        }
        
        do {
            try audioFile.read(into: PCMBuffer)
            
            buffer.removeAll()
            for i in 0 ..< nChannel {
                let buf:[Float] = Array(UnsafeMutableBufferPointer(start: floatChannelData[i], count: nframe))
                buffer.append(buf)
            }
        }catch{
            print("loading audio data failed.")
        }
        
        return true
    }
    
    
    // MARK: - 音楽のBPMを調べる
    //参考サイト
    //https://qiita.com/music431per/items/8d687b49afee0d7ccfdf

    private let frameLength = 512
    private var vols:[Double] = []
    
    ///フレームごとの音量を求める
    ///
    /// - Returns: 実行結果
    private func calculateFrameVolume() -> Bool {
        
        guard let nframe = nframe else {
            return false
        }
        
        // フレームの数
        let n = nframe / frameLength
        
        vols.removeAll()
        
        for i in 0 ..< n {
            var vol:Double = 0
            for j in 0 ..< frameLength {
                let idx = i * frameLength + j
                let sound = Double(buffer[0][idx])
                vol += pow(sound, 2)
            }
            let vol2 = sqrt((1.0 / Double(frameLength)) * vol)
            vols.append(vol2)
        }
        
        return true
    }
    
    private var diffs:[Double] = []
    
    ///隣り合うフレームの音量の増加分を求める
    ///
    /// - Returns: 実行結果
    private func caculateDiffVolume() -> Bool {
        guard let nframe = nframe else {
            return false
        }
        
        // フレームの数
        let n = nframe / frameLength
        
        diffs.removeAll()
        
        for i in 0 ..< n - 1 {
            let value = vols[i] - vols[ i + 1]
            let diff = value > 0 ? value : 0
            diffs.append(diff)
        }
        diffs.append(0)
        
        return true
    }
    
    ///どのテンポがマッチするかを求める
    ///
    /// - Returns: BPM
    private func searchTempo() -> Int {
        guard let nframe = nframe else {
            return errorBPM
        }
        guard let samplingRate = samplingRate else {
            return errorBPM
        }
        
        // 最大最小テンポ
        let minBPM = 60
        let maxBPM = 240
        
        // フレームの数
        let n = nframe / frameLength
        
        let s = samplingRate / Double(frameLength)
        
        var a:[Double] = []
        var b:[Double] = []
        var r:[Double] = []
        
        for bpm in minBPM ... maxBPM {
            var aSum:Double = 0
            var bSum:Double = 0
            let f = Double(bpm) / Double(60)
            for i in 0 ..< n {
                aSum += diffs[i] * cos(2.0 * Double.pi * f * Double(i) / s)
                bSum += diffs[i] * sin(2.0 * Double.pi * f * Double(i) / s)
            }
            let aTMP = aSum / Double(n)
            let bTMP = bSum / Double(n)
            a.append(aTMP)
            b.append(bTMP)
            r.append(sqrt(pow(aTMP, 2) + pow(bTMP, 2)))
        }
        
        var maxIndex = errorBPM
        
        // 一番マッチするインデックスを求める
        var dy:Double = 0
        for i in 1 ..< (maxBPM - minBPM + 1) {
            let dyPre = dy
            dy = r[i] - r[i - 1]
            if dyPre > 0 && dy <= 0 {
                if maxIndex < 0 || r[i - 1] > r[maxIndex] {
                    maxIndex = i - 1
                }
            }
        }
        
        if maxIndex < 0 {
            return errorBPM
        }
        
        return maxIndex + minBPM
    }
    
}
