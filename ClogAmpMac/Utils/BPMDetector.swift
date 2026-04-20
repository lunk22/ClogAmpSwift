//
//  BPMDetector.swift
//  ClogAmpSwift
//  Generated with AI
//
//  Pure Swift BPM detector using AVFoundation + Accelerate.
//
//  Algorithm: 3-stage beat tracker
//    Stage 0 — Audio ingestion: mono Float32 @ 4410 Hz via AVAudioConverter
//    Stage 1 — Onset strength envelope: blended STE + spectral flux
//    Stage 2 — Autocorrelation tempo estimation
//    Stage 3 — Dynamic programming beat tracker (Ellis 2007), median IBI → BPM
//

import AVFoundation
import Accelerate

enum BPMDetectionError: Error {
    case fileNotReadable
    case audioConversionFailed
    case insufficientAudioData
    case noTempoFound
}

enum BPMDetector {

    // MARK: - Constants

    private static let processingRate: Double = 4410.0
    private static let hopSize: Int           = 64
    private static let fftSize: Int           = 256
    private static let tightness: Double      = 400.0
    private static let alpha: Float           = 0.5
    private static let silenceThresholdRMS: Float = 0.001995  // ≈ −54 dBFS

    // MARK: - Public entry point

    /// Detect BPM from an audio file.
    /// - Parameters:
    ///   - fileURL: Path to the audio file (file:// URL).
    ///   - lowerBound: Minimum expected BPM.
    ///   - upperBound: Maximum expected BPM.
    /// - Returns: Detected BPM as Int.
    static func detect(fileURL: URL, lowerBound: Int, upperBound: Int) throws -> Int {
        let (samples, _) = try loadMonoDownsampled(fileURL: fileURL)

        let fps = processingRate / Double(hopSize)

        let lagMax = Int(ceil(fps * 60.0 / Double(max(1, lowerBound))))

        guard samples.count >= lagMax * hopSize * 2 else {
            throw BPMDetectionError.insufficientAudioData
        }

        let onset = computeOnsetEnvelope(samples: samples, fps: fps)

        guard onset.count >= 2 * lagMax else {
            throw BPMDetectionError.insufficientAudioData
        }

        let (lagHops, bpmCandidate) = autocorrelationTempo(
            onset: onset,
            fps: fps,
            lowerBound: lowerBound,
            upperBound: upperBound
        )

        if lagHops <= 0 { throw BPMDetectionError.noTempoFound }

        let dpBpm = dpBeatTracker(onset: onset, period: lagHops, fps: fps)
        let finalBpm = dpBpm > 0 ? dpBpm : bpmCandidate

        return resolveOctave(bpm: finalBpm, candidate: bpmCandidate, lowerBound: lowerBound, upperBound: upperBound)
    }

    // MARK: - Stage 0: Audio ingestion

    private static func loadMonoDownsampled(fileURL: URL) throws -> (samples: [Float], sampleRate: Double) {
        guard let audioFile = try? AVAudioFile(forReading: fileURL) else {
            throw BPMDetectionError.fileNotReadable
        }

        let targetFormat: AVAudioFormat
        if let layout = AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_Mono) {
            targetFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: processingRate,
                interleaved: false,
                channelLayout: layout
            )
        } else {
            guard let fmt = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: processingRate,
                channels: 1,
                interleaved: false
            ) else {
                throw BPMDetectionError.audioConversionFailed
            }
            targetFormat = fmt
        }

        guard let converter = AVAudioConverter(from: audioFile.processingFormat, to: targetFormat) else {
            throw BPMDetectionError.audioConversionFailed
        }

        let sourceRate = audioFile.processingFormat.sampleRate
        let sourceFrameCapacity: AVAudioFrameCount = 65536
        let targetFrameCapacity = AVAudioFrameCount(
            ceil(Double(sourceFrameCapacity) * processingRate / sourceRate)
        )

        guard
            let sourceBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: sourceFrameCapacity),
            let targetBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: targetFrameCapacity)
        else {
            throw BPMDetectionError.audioConversionFailed
        }

        let estimatedTargetFrames = Int(ceil(Double(audioFile.length) * processingRate / sourceRate))
        var result = [Float]()
        result.reserveCapacity(estimatedTargetFrames)

        var reachedEnd = false
        while !reachedEnd {
            var conversionError: NSError?
            let status = converter.convert(to: targetBuffer, error: &conversionError) { _, outStatus in
                do {
                    try audioFile.read(into: sourceBuffer)
                    outStatus.pointee = .haveData
                    return sourceBuffer
                } catch {
                    outStatus.pointee = .endOfStream
                    return nil
                }
            }

            if status == .error || conversionError != nil {
                break
            }
            if status == .endOfStream {
                reachedEnd = true
            }

            let frameCount = Int(targetBuffer.frameLength)
            if frameCount == 0 { break }

            if let data = targetBuffer.floatChannelData?[0] {
                result.append(contentsOf: UnsafeBufferPointer(start: data, count: frameCount))
            }
        }

        guard !result.isEmpty else {
            throw BPMDetectionError.audioConversionFailed
        }

        // Trim leading silence
        let windowSize = Int(processingRate * 0.05) // 50ms windows
        var silenceEnd = 0
        var i = 0
        while i + windowSize <= result.count {
            var rms: Float = 0
            vDSP_measqv(result[i...].withUnsafeBufferPointer { $0.baseAddress! }, 1, &rms, vDSP_Length(windowSize))
            rms = sqrt(rms)
            if rms >= silenceThresholdRMS {
                silenceEnd = i
                break
            }
            i += windowSize
        }

        return (Array(result[silenceEnd...]), processingRate)
    }

    // MARK: - Stage 1: Onset strength envelope

    private static func computeOnsetEnvelope(samples: [Float], fps: Double) -> [Float] {
        let steOnset  = shortTimeEnergyOnset(samples: samples)
        let fluxOnset = spectralFluxOnset(samples: samples)

        let count = min(steOnset.count, fluxOnset.count)
        guard count > 0 else { return [] }

        // Normalise each sub-signal
        func normalise(_ s: [Float]) -> [Float] {
            var maxVal: Float = 0
            vDSP_maxv(s, 1, &maxVal, vDSP_Length(s.count))
            guard maxVal > 0 else { return s }
            var scale = 1.0 / maxVal
            var out = [Float](repeating: 0, count: s.count)
            vDSP_vsmul(s, 1, &scale, &out, 1, vDSP_Length(s.count))
            return out
        }

        let normSTE  = normalise(Array(steOnset[..<count]))
        let normFlux = normalise(Array(fluxOnset[..<count]))

        // Blend: alpha * STE + (1-alpha) * flux
        var blended = [Float](repeating: 0, count: count)
        var a = alpha
        var b = 1.0 - alpha
        vDSP_vsmul(normSTE,  1, &a, &blended, 1, vDSP_Length(count))
        var temp = [Float](repeating: 0, count: count)
        vDSP_vsmul(normFlux, 1, &b, &temp,    1, vDSP_Length(count))
        vDSP_vadd(blended, 1, temp, 1, &blended, 1, vDSP_Length(count))

        // Subtract local running mean (~1 second window)
        let meanWindowHops = max(1, Int(fps))
        let subtracted = localAverageSubtract(signal: blended, windowHops: meanWindowHops)

        // Half-wave rectify
        var rectified = [Float](repeating: 0, count: count)
        var zero: Float = 0
        vDSP_vthres(subtracted, 1, &zero, &rectified, 1, vDSP_Length(count))

        // 3-tap smoothing
        guard count >= 3 else { return rectified }
        var kernel: [Float] = [1.0/3, 1.0/3, 1.0/3]
        var smoothed = [Float](repeating: 0, count: count)
        vDSP_conv(rectified, 1, &kernel, 1, &smoothed, 1, vDSP_Length(count - 2), 3)

        return smoothed
    }

    private static func shortTimeEnergyOnset(samples: [Float]) -> [Float] {
        let windowSize = hopSize * 2
        let n = samples.count
        var energies = [Float]()
        energies.reserveCapacity(n / hopSize)

        var pos = 0
        while pos + windowSize <= n {
            var ms: Float = 0
            vDSP_measqv(samples[pos...].withUnsafeBufferPointer { $0.baseAddress! }, 1, &ms, vDSP_Length(windowSize))
            energies.append(sqrt(ms))
            pos += hopSize
        }

        // Half-wave rectified first difference
        var onset = [Float](repeating: 0, count: energies.count)
        for i in 1..<energies.count {
            onset[i] = max(0, energies[i] - energies[i - 1])
        }
        return onset
    }

    private static func spectralFluxOnset(samples: [Float]) -> [Float] {
        let n = samples.count
        let log2n = vDSP_Length(log2(Float(fftSize)))
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(FFT_RADIX2)) else { return [] }
        defer { vDSP_destroy_fftsetup(fftSetup) }

        // Hann window
        var hannWindow = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&hannWindow, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))

        let halfFFT = fftSize / 2
        var prevMag  = [Float](repeating: 0, count: halfFFT)
        var flux     = [Float]()
        flux.reserveCapacity(n / hopSize)

        var pos = 0
        while pos + fftSize <= n {
            // Apply Hann window
            var windowed = [Float](repeating: 0, count: fftSize)
            vDSP_vmul(samples[pos...].withUnsafeBufferPointer { $0.baseAddress! }, 1,
                      hannWindow, 1, &windowed, 1, vDSP_Length(fftSize))

            // Pack into split-complex and compute FFT
            var real = [Float](repeating: 0, count: halfFFT)
            var imag = [Float](repeating: 0, count: halfFFT)
            var mag  = [Float](repeating: 0, count: halfFFT)
            real.withUnsafeMutableBufferPointer { realBuf in
                imag.withUnsafeMutableBufferPointer { imagBuf in
                    var splitComplex = DSPSplitComplex(realp: realBuf.baseAddress!, imagp: imagBuf.baseAddress!)
                    windowed.withUnsafeBytes { ptr in
                        let floatPtr = ptr.bindMemory(to: DSPComplex.self).baseAddress!
                        vDSP_ctoz(floatPtr, 2, &splitComplex, 1, vDSP_Length(halfFFT))
                    }
                    vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
                    vDSP_zvabs(&splitComplex, 1, &mag, 1, vDSP_Length(halfFFT))
                }
            }

            // Positive spectral flux
            var diff = [Float](repeating: 0, count: halfFFT)
            vDSP_vsub(prevMag, 1, mag, 1, &diff, 1, vDSP_Length(halfFFT))
            var zerof: Float = 0
            var posFlux = [Float](repeating: 0, count: halfFFT)
            vDSP_vthres(diff, 1, &zerof, &posFlux, 1, vDSP_Length(halfFFT))
            var sum: Float = 0
            vDSP_sve(posFlux, 1, &sum, vDSP_Length(halfFFT))
            flux.append(sum)

            prevMag = mag
            pos += hopSize
        }

        return flux
    }

    private static func localAverageSubtract(signal: [Float], windowHops: Int) -> [Float] {
        let count = signal.count
        guard count > 0 else { return signal }

        let half = windowHops / 2
        var result = [Float](repeating: 0, count: count)

        for i in 0..<count {
            let lo = max(0, i - half)
            let hi = min(count - 1, i + half)
            let len = hi - lo + 1
            var mean: Float = 0
            vDSP_meanv(signal[lo...].withUnsafeBufferPointer { $0.baseAddress! }, 1, &mean, vDSP_Length(len))
            result[i] = signal[i] - mean
        }
        return result
    }

    // MARK: - Stage 2: Autocorrelation tempo estimation

    private static func autocorrelationTempo(
        onset: [Float],
        fps: Double,
        lowerBound: Int,
        upperBound: Int
    ) -> (lagHops: Int, bpmCandidate: Int) {

        let n = onset.count
        // Zero-pad to next power of two >= 2*n
        var fftN = 1
        while fftN < 2 * n { fftN <<= 1 }

        let log2n = vDSP_Length(log2(Float(fftN)))
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(FFT_RADIX2)) else {
            return (0, 0)
        }
        defer { vDSP_destroy_fftsetup(fftSetup) }

        let halfN = fftN / 2
        let padded = onset + [Float](repeating: 0, count: fftN - n)

        var real = [Float](repeating: 0, count: halfN)
        var imag = [Float](repeating: 0, count: halfN)
        var power = [Float](repeating: 0, count: halfN)

        real.withUnsafeMutableBufferPointer { realBuf in
            imag.withUnsafeMutableBufferPointer { imagBuf in
                var splitComplex = DSPSplitComplex(realp: realBuf.baseAddress!, imagp: imagBuf.baseAddress!)
                padded.withUnsafeBytes { ptr in
                    let floatPtr = ptr.bindMemory(to: DSPComplex.self).baseAddress!
                    vDSP_ctoz(floatPtr, 2, &splitComplex, 1, vDSP_Length(halfN))
                }
                vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
                // Power spectrum
                vDSP_zvmags(&splitComplex, 1, &power, 1, vDSP_Length(halfN))
            }
        }

        // Inverse FFT of power spectrum to get autocorrelation
        var realPow = power
        var imagPow = [Float](repeating: 0, count: halfN)
        var R = [Float](repeating: 0, count: fftN)

        realPow.withUnsafeMutableBufferPointer { realBuf in
            imagPow.withUnsafeMutableBufferPointer { imagBuf in
                var acSplit = DSPSplitComplex(realp: realBuf.baseAddress!, imagp: imagBuf.baseAddress!)
                vDSP_fft_zrip(fftSetup, &acSplit, 1, log2n, FFTDirection(FFT_INVERSE))
                R.withUnsafeMutableBytes { ptr in
                    let floatPtr = ptr.bindMemory(to: DSPComplex.self).baseAddress!
                    vDSP_ztoc(&acSplit, 1, floatPtr, 2, vDSP_Length(halfN))
                }
            }
        }

        // Normalise by R[0]
        let r0 = R[0]
        guard r0 > 0 else { return (0, 0) }
        var scale = 1.0 / r0
        vDSP_vsmul(R, 1, &scale, &R, 1, vDSP_Length(fftN))

        let lagMax = Int(ceil(fps * 60.0 / Double(max(1, lowerBound))))
        let lagMin = max(1, Int(floor(fps * 60.0 / Double(upperBound))))

        guard lagMax < fftN else { return (0, 0) }

        // Apply Gaussian tempo prior centred on 125 BPM, σ=30 BPM
        let centerLag = fps * 60.0 / 125.0
        let sigmaLag  = fps * 60.0 / 30.0
        var weighted = [Float](repeating: 0, count: lagMax - lagMin + 1)
        for lag in lagMin...lagMax {
            let d = Double(lag) - centerLag
            let w = Float(exp(-0.5 * (d / sigmaLag) * (d / sigmaLag)))
            weighted[lag - lagMin] = R[lag] * w
        }

        // Find best lag
        var bestVal: Float = 0
        var bestIdx: vDSP_Length = 0
        vDSP_maxvi(weighted, 1, &bestVal, &bestIdx, vDSP_Length(weighted.count))
        let bestLag = Int(bestIdx) + lagMin

        // Confidence check
        guard R[bestLag] > 0.05 else { return (0, 0) }

        // Sub-harmonic check: compare tau, tau/2, 2*tau
        var finalLag = bestLag
        let halfLag   = bestLag / 2
        let doubleLag = bestLag * 2
        var bestScore = R[bestLag]

        if halfLag >= lagMin && halfLag < fftN && R[halfLag] > bestScore {
            finalLag  = halfLag
            bestScore = R[halfLag]
        }
        if doubleLag <= lagMax && doubleLag < fftN && R[doubleLag] > bestScore {
            finalLag = doubleLag
        }

        let bpmCandidate = Int(round(fps * 60.0 / Double(finalLag)))
        return (finalLag, bpmCandidate)
    }

    // MARK: - Stage 3: DP beat tracker

    private static func dpBeatTracker(onset: [Float], period: Int, fps: Double) -> Int {
        let n = onset.count
        guard n > period * 2 else { return 0 }

        // Search window: 50% to 200% of nominal period
        let minLag = max(1, period / 2)
        let maxLag = period * 2
        let lagRange = maxLag - minLag + 1

        // Pre-compute log-Gaussian penalty table for lags [minLag...maxLag]
        var penalty = [Float](repeating: 0, count: lagRange)
        let periodD = Double(period)
        let tightnessF = Float(tightness)
        for i in 0..<lagRange {
            let lag = Double(i + minLag)
            let logRatio = Float(log(lag / periodD))
            penalty[i] = tightnessF * logRatio * logRatio
        }

        var score = onset  // initialise score with onset strength
        var prev  = [Int](repeating: -1, count: n)

        for t in maxLag..<n {
            // Extract score window: score[t-maxLag ... t-minLag]
            let windowStart = t - maxLag
            let windowEnd   = t - minLag

            var candidates = Array(score[windowStart...windowEnd])

            // Subtract penalty (reversed, since lag 0 in candidates = maxLag)
            let revPenalty = penalty.reversed() as [Float]
            let windowLen = windowEnd - windowStart + 1
            let usedLen = min(windowLen, revPenalty.count)

            var penalised = [Float](repeating: 0, count: usedLen)
            vDSP_vsub(revPenalty, 1, candidates, 1, &penalised, 1, vDSP_Length(usedLen))
            candidates = penalised

            var bestVal: Float = -Float.infinity
            var bestIdx: vDSP_Length = 0
            vDSP_maxvi(candidates, 1, &bestVal, &bestIdx, vDSP_Length(usedLen))

            let bestPrev = windowStart + Int(bestIdx)
            score[t] += max(0, bestVal)
            prev[t]   = bestPrev
        }

        // Traceback from best endpoint in last 25% of signal
        let searchStart = n - n / 4
        let endSlice = Array(score[searchStart...])
        var endBestVal: Float = 0
        var endBestIdx: vDSP_Length = 0
        vDSP_maxvi(endSlice, 1, &endBestVal, &endBestIdx, vDSP_Length(endSlice.count))

        var beats = [Int]()
        var t = searchStart + Int(endBestIdx)
        while t >= 0 && prev[t] >= 0 && prev[t] < t {
            beats.append(t)
            t = prev[t]
        }

        guard beats.count >= 8 else { return 0 }

        // Median IBI
        var ibis = [Float]()
        for i in 1..<beats.count {
            ibis.append(Float(beats[i - 1] - beats[i]))  // beats are in reverse order
        }
        ibis.sort()
        let medianIBI = ibis[ibis.count / 2]
        guard medianIBI > 0 else { return 0 }

        return Int(round(fps * 60.0 / Double(medianIBI)))
    }

    // MARK: - Octave resolution

    private static func resolveOctave(bpm: Int, candidate: Int, lowerBound: Int, upperBound: Int) -> Int {
        var result = bpm
        var iterations = 0
        while result > upperBound && iterations < 4 { result /= 2; iterations += 1 }
        iterations = 0
        while result < lowerBound && iterations < 4 { result *= 2; iterations += 1 }

        if result >= lowerBound && result <= upperBound {
            return result
        }

        // Fall back to Stage 2 candidate, apply same correction
        var fallback = candidate
        iterations = 0
        while fallback > upperBound && iterations < 4 { fallback /= 2; iterations += 1 }
        iterations = 0
        while fallback < lowerBound && iterations < 4 { fallback *= 2; iterations += 1 }

        return fallback >= lowerBound && fallback <= upperBound ? fallback : bpm
    }
}
