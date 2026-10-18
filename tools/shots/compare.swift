// Screenshot comparison for the regression shots (plan chapter 11, 19.6; roadmap RT-04).
// Compares each candidate PNG with its reference in CIE Lab (D65) and fails a pair when more than
// --max-fraction of its pixels differ by more than --threshold ΔE (ΔE76). Writes a side-by-side image
// (reference | candidate | difference) for every failing pair, or for every pair with --always-write.
// Written in Swift because the Mac's Python has no Pillow or NumPy (docs/DECISIONS.md, 25 Sep 2026).
//
// Build: swiftc -O -o tools/bin/shots-compare tools/shots/compare.swift   (tools/shots/compare does it for you)
// Use:   shots-compare <reference.png|dir> <candidate.png|dir> [--out dir] [--threshold 8] [--max-fraction 0.01] [--always-write]
// Exit:  0 all pass, 1 any fail, 2 usage or file error.

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

struct Options {
    var reference = ""
    var candidate = ""
    var outDir: String? = nil
    var threshold = 8.0
    var maxFraction = 0.01
    var alwaysWrite = false
}

func parseArgs() -> Options? {
    var o = Options()
    var positional: [String] = []
    var it = CommandLine.arguments.dropFirst().makeIterator()
    while let a = it.next() {
        switch a {
        case "--out": o.outDir = it.next()
        case "--threshold": o.threshold = Double(it.next() ?? "") ?? o.threshold
        case "--max-fraction": o.maxFraction = Double(it.next() ?? "") ?? o.maxFraction
        case "--always-write": o.alwaysWrite = true
        default: positional.append(a)
        }
    }
    guard positional.count == 2 else { return nil }
    o.reference = positional[0]
    o.candidate = positional[1]
    return o
}

struct RGBAImage {
    let width: Int
    let height: Int
    var pixels: [UInt8]  // RGBA, 8 bits per channel, sRGB
}

func loadPNG(_ path: String) -> RGBAImage? {
    let url = URL(fileURLWithPath: path) as CFURL
    guard let src = CGImageSourceCreateWithURL(url, nil),
          let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return nil }
    let w = img.width, h = img.height
    var buf = [UInt8](repeating: 0, count: w * h * 4)
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    let ok = buf.withUnsafeMutableBytes { raw -> Bool in
        guard let ctx = CGContext(data: raw.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                  space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
        ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
        return true
    }
    return ok ? RGBAImage(width: w, height: h, pixels: buf) : nil
}

func savePNG(_ img: RGBAImage, _ path: String) -> Bool {
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    var px = img.pixels
    return px.withUnsafeMutableBytes { raw -> Bool in
        guard let ctx = CGContext(data: raw.baseAddress, width: img.width, height: img.height, bitsPerComponent: 8,
                                  bytesPerRow: img.width * 4, space: cs,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let cg = ctx.makeImage(),
              let dst = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL,
                                                        UTType.png.identifier as CFString, 1, nil) else { return false }
        CGImageDestinationAddImage(dst, cg, nil)
        return CGImageDestinationFinalize(dst)
    }
}

// sRGB 8-bit to linear, precomputed.
let linearTable: [Double] = (0..<256).map { i in
    let c = Double(i) / 255.0
    return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
}

@inline(__always) func labOf(_ r: UInt8, _ g: UInt8, _ b: UInt8) -> (Double, Double, Double) {
    let rl = linearTable[Int(r)], gl = linearTable[Int(g)], bl = linearTable[Int(b)]
    // sRGB (D65) to XYZ, normalised by the D65 white point.
    let x = (0.4124564 * rl + 0.3575761 * gl + 0.1804375 * bl) / 0.95047
    let y = (0.2126729 * rl + 0.7151522 * gl + 0.0721750 * bl)
    let z = (0.0193339 * rl + 0.1191920 * gl + 0.9503041 * bl) / 1.08883
    @inline(__always) func f(_ t: Double) -> Double { t > 216.0 / 24389.0 ? cbrt(t) : (24389.0 / 27.0 * t + 16.0) / 116.0 }
    let fx = f(x), fy = f(y), fz = f(z)
    return (116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz))
}

struct Result {
    let name: String
    let fraction: Double
    let maxDE: Double
    let meanDE: Double
    let pass: Bool
    let note: String
}

func compare(refPath: String, candPath: String, name: String, o: Options) -> Result {
    guard let ref = loadPNG(refPath) else { return Result(name: name, fraction: 1, maxDE: 0, meanDE: 0, pass: false, note: "cannot read reference") }
    guard let cand = loadPNG(candPath) else { return Result(name: name, fraction: 1, maxDE: 0, meanDE: 0, pass: false, note: "cannot read candidate") }
    guard ref.width == cand.width && ref.height == cand.height else {
        return Result(name: name, fraction: 1, maxDE: 0, meanDE: 0, pass: false,
                      note: "size differs: \(ref.width)x\(ref.height) vs \(cand.width)x\(cand.height)")
    }
    let n = ref.width * ref.height
    var over = 0
    var maxDE = 0.0, sumDE = 0.0
    var diff = RGBAImage(width: ref.width, height: ref.height, pixels: [UInt8](repeating: 255, count: n * 4))
    for i in 0..<n {
        let k = i * 4
        let a = labOf(ref.pixels[k], ref.pixels[k + 1], ref.pixels[k + 2])
        let b = labOf(cand.pixels[k], cand.pixels[k + 1], cand.pixels[k + 2])
        let de = ((a.0 - b.0) * (a.0 - b.0) + (a.1 - b.1) * (a.1 - b.1) + (a.2 - b.2) * (a.2 - b.2)).squareRoot()
        sumDE += de
        if de > maxDE { maxDE = de }
        // Difference map: grey reference luminance, red where over the threshold, orange where noticeable.
        let grey = UInt8(max(0.0, min(255.0, a.0 * 2.55 * 0.35 + 150.0)))
        if de > o.threshold {
            over += 1
            diff.pixels[k] = 230; diff.pixels[k + 1] = 30; diff.pixels[k + 2] = 30
        } else if de > o.threshold / 4.0 {
            diff.pixels[k] = 240; diff.pixels[k + 1] = 160; diff.pixels[k + 2] = 60
        } else {
            diff.pixels[k] = grey; diff.pixels[k + 1] = grey; diff.pixels[k + 2] = grey
        }
    }
    let fraction = Double(over) / Double(n)
    let pass = fraction <= o.maxFraction
    if (!pass || o.alwaysWrite), let outDir = o.outDir {
        try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
        // Side by side: reference | candidate | difference.
        let w = ref.width, h = ref.height
        var side = RGBAImage(width: w * 3, height: h, pixels: [UInt8](repeating: 0, count: w * 3 * h * 4))
        for y in 0..<h {
            for (panel, img) in [ref, cand, diff].enumerated() {
                let srcRow = y * w * 4
                let dstRow = (y * w * 3 + panel * w) * 4
                side.pixels.replaceSubrange(dstRow..<(dstRow + w * 4), with: img.pixels[srcRow..<(srcRow + w * 4)])
            }
        }
        let base = (name as NSString).deletingPathExtension
        _ = savePNG(side, (outDir as NSString).appendingPathComponent(base + "_compare.png"))
    }
    return Result(name: name, fraction: fraction, maxDE: maxDE, meanDE: sumDE / Double(n), pass: pass, note: "")
}

guard let o = parseArgs() else {
    FileHandle.standardError.write("usage: shots-compare <reference.png|dir> <candidate.png|dir> [--out dir] [--threshold 8] [--max-fraction 0.01] [--always-write]\n".data(using: .utf8)!)
    exit(2)
}

var pairs: [(String, String, String)] = []
var isDir: ObjCBool = false
if FileManager.default.fileExists(atPath: o.reference, isDirectory: &isDir), isDir.boolValue {
    let names = ((try? FileManager.default.contentsOfDirectory(atPath: o.reference)) ?? []).filter { $0.hasSuffix(".png") }.sorted()
    for name in names {
        pairs.append(((o.reference as NSString).appendingPathComponent(name), (o.candidate as NSString).appendingPathComponent(name), name))
    }
} else {
    pairs.append((o.reference, o.candidate, (o.candidate as NSString).lastPathComponent))
}
if pairs.isEmpty { print("no reference PNGs found in \(o.reference)"); exit(2) }

var failures = 0
for (r, c, name) in pairs {
    let res = compare(refPath: r, candPath: c, name: name, o: o)
    if !res.pass { failures += 1 }
    let pct = String(format: "%.3f", res.fraction * 100)
    let line = res.note.isEmpty
        ? "\(res.pass ? "PASS" : "FAIL")  \(name): \(pct)% of pixels over \(Int(o.threshold)) ΔE (mean \(String(format: "%.2f", res.meanDE)), max \(String(format: "%.1f", res.maxDE)))"
        : "FAIL  \(name): \(res.note)"
    print(line)
}
print("\(pairs.count - failures) of \(pairs.count) pass")
exit(failures == 0 ? 0 : 1)
