# Ghostty, Abstruct, and bitmap strikes on macOS

Research date: 2026-08-17. Tested Ghostty version: 1.3.1. Ghostty source:
[`v1.3.1`](https://github.com/ghostty-org/ghostty/tree/v1.3.1).
Abstruct source: commit
[`b07a1f5`](https://codeberg.org/axseem/abstruct/src/commit/b07a1f509f62f64a5126961a446c9b169aa719d1).

## Conclusion

Do **not** rely on Ghostty/macOS selecting Abstruct's EBDT strikes. Ghostty hands
the font to CoreText, and neither Apple's API contract nor Ghostty selects an
EBDT strike explicitly. A local CoreText test on macOS 26.3 showed CoreText
rendering the outline even at exact EBDT sizes.

Abstruct may still look pixel-perfect at exact integer scales because its
fallback outlines are constructed on the same pixel grid. In direct CoreText
tests, all 107 non-empty glyphs produced only fully off/on pixels at 12, 24,
36, and 48 pixels per em. All 107 had grayscale edge pixels at 16 ppem. This is
practical evidence, not a cross-version guarantee or a full Ghostty rendering
test.

## Verified facts

### Font contents

- Abstruct is a 6×12 BDF family. Its standard TTF contains outlines plus
  one-bit EBDT strikes at 12, 24, 36, 48, 60, 72, 84, and 96 ppem
  ([README lines 5–9](https://codeberg.org/axseem/abstruct/src/commit/b07a1f509f62f64a5126961a446c9b169aa719d1/README.md#L5-L9)).
- The build imports those scaled BDFs with FontForge and generates EBDT/EBLC
  ([flake lines 141–156](https://codeberg.org/axseem/abstruct/src/commit/b07a1f509f62f64a5126961a446c9b169aa719d1/flake.nix#L141-L156)).
  Its check asserts the eight strikes' `ppemX`, `ppemY`, and one-bit depth
  ([lines 97–110](https://codeberg.org/axseem/abstruct/src/commit/b07a1f509f62f64a5126961a446c9b169aa719d1/flake.nix#L97-L110)).
- The OpenType specification defines `ppemX` and `ppemY` as pixels per em and
  says ppem equals point size only at 72 dpi
  ([EBLC specification](https://learn.microsoft.com/en-us/typography/opentype/spec/eblc#table-structure)).

### Ghostty's macOS size conversion

Ghostty uses 72 as macOS's base DPI and computes:

```text
requested pixel size = configured points × backing scale
```

This follows directly from its `points × ydpi / 72` conversion
([`face.zig` lines 30, 48–60](https://github.com/ghostty-org/ghostty/blob/v1.3.1/src/font/face.zig#L30-L60))
and its `backing scale × base DPI` update
([`Surface.zig` lines 3647–3669](https://github.com/ghostty-org/ghostty/blob/v1.3.1/src/Surface.zig#L3647-L3669)).
The AppKit frontend obtains the scale by converting the view to backing
coordinates
([`SurfaceView_AppKit.swift` lines 890–896](https://github.com/ghostty-org/ghostty/blob/v1.3.1/macos/Sources/Ghostty/Surface%20View/SurfaceView_AppKit.swift#L890-L896)).

Apple documents a backing scale of 2 for high-resolution scaled modes and 1
otherwise, while warning that this is not physical pixel density
([`backingScaleFactor`](https://developer.apple.com/documentation/appkit/nswindow/backingscalefactor)).
Therefore:

| Display backing scale | Point sizes matching Abstruct's ppem strikes |
|---|---|
| 2× | 6, 12, 18, 24, 30, 36, 42, 48 pt |
| 1× | 12, 24, 36, 48, 60, 72, 84, 96 pt |

Ghostty passes that computed pixel value as the CoreText font size
([`coretext.zig` lines 76–87](https://github.com/ghostty-org/ghostty/blob/v1.3.1/src/font/face/coretext.zig#L76-L87)).
Apple calls this argument a point size
([`CTFontCreateCopyWithAttributes`](https://developer.apple.com/documentation/coretext/ctfontcreatecopywithattributes(_:_:_:_:))).
The numeric value nevertheless maps to pixels in Ghostty's pixel-backed glyph
atlas, as Ghostty's own source comment explains.

### Rasterization path

Ghostty renders through `CTFontDrawGlyphs`; Apple's contract says this renders
the supplied CTFont into the supplied graphics context, but does not promise
which embedded strike is chosen
([Apple documentation](https://developer.apple.com/documentation/coretext/ctfontdrawglyphs(_:_:_:_:_:))).

Ghostty enables antialiasing and subpixel positioning
([`coretext.zig` lines 478–498](https://github.com/ghostty-org/ghostty/blob/v1.3.1/src/font/face/coretext.zig#L478-L498)).
It rounds position and size only for `sbix` color bitmaps, not EBDT
([lines 303–306 and 382–390](https://github.com/ghostty-org/ghostty/blob/v1.3.1/src/font/face/coretext.zig#L303-L390)).
Consequently an EBDT glyph receives no explicit pixel-alignment protection in
Ghostty.

A first-party Ghostty issue also reports that bitmap-bearing TTFs can work,
while `.otb` fonts do not. It does not establish EBDT selection behavior
([issue #2168](https://github.com/ghostty-org/ghostty/issues/2168)).

## Practical CoreText test

I built `abstruct-regular.ttf`, confirmed its EBLC records as
`(12…96, 12…96, bitDepth=1)`, and rendered every non-empty glyph with the same
CoreGraphics antialiasing and subpixel flags used by Ghostty. Results:

| CTFont size | Glyphs with grayscale edge pixels |
|---|---|
| 12, 24, 36, 48 | 0 of 107 |
| 16 | 107 of 107 |

The aligned sizes also have integral advances, bounding boxes, ascents, and
descents. Ghostty's primary-face centering and baseline calculations therefore
introduce no fractional offset at those sizes. A forced half-pixel offset made
all 107 glyphs grayscale, confirming that alignment matters.

To distinguish an EBDT strike from the matching outline, I replaced only the
outline for `A` with a filled rectangle while retaining EBDT/EBLC. CoreText
rendered the rectangle at 12, 24, and 36 ppem. This demonstrates that this
macOS/CoreText version ignored those EBDT glyphs. It does not prove all macOS
versions behave identically.

## Zoom configuration

Ghostty supports fractional or integer point deltas and absolute point sizes:
`increase_font_size`, `decrease_font_size`, `set_font_size`, and
`reset_font_size`
([`Binding.zig` lines 388–407](https://github.com/ghostty-org/ghostty/blob/v1.3.1/src/input/Binding.zig#L388-L407)).
The handlers apply the requested point values directly; reset returns to the
configured original size
([`Surface.zig` lines 5121–5169](https://github.com/ghostty-org/ghostty/blob/v1.3.1/src/Surface.zig#L5121-L5169)).

Thus a 6 pt step is configurable. For a Retina-only setup, use an aligned base:

```ini
font-size = 12
keybind = super+equal=increase_font_size:6
keybind = super+minus=decrease_font_size:6
keybind = super+digit_0=reset_font_size
```

This visits 24, 36, 48, … ppem at 2×. The checked-out stale branch's 8 pt value
maps to 16 ppem at 2×, but `origin/main` already uses the aligned 12 pt value.

Prefer `set_font_size:<points>` bindings when sizes may also change through
other shortcuts or configuration reloads: absolute sizes cannot accumulate
drift. Prefer a 12 pt base and 12 pt steps if the same sequence must remain
aligned after moving between 1× and 2× displays. A 6 pt sequence is aligned at
2× only on every other step at 1×.

This Mac currently has both a 2× built-in Retina display and a 1× external
display. There is no single relative step that both increments the source-pixel
scale by exactly one on both displays: that requires 6 pt at 2× and 12 pt at
1×. A 12 pt step remains sharp on both, but jumps by two source-pixel scale
units on Retina.

## Remaining validation

For the exact deployed Ghostty/macOS versions, capture Ghostty's glyph atlas or
a lossless screenshot at the intended sizes and check that every non-background
pixel has full coverage and that stems occupy exact integer multiples of the
6×12 source. This is still needed because Ghostty permits fractional glyph
placement and CoreText behavior is not contractually fixed.
