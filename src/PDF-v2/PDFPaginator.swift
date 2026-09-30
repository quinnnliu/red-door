//
//  PDFPaginator.swift
//  RedDoor
//
//  Created by Quinn Liu on 09/30/26.
//

import SwiftUI

/// One measurable unit of PDF content.
///
/// The paginator never inspects `view` — it packs by measured height alone, so
/// redesigning a document means changing the blocks it emits, not this file.
///
/// A block's height must depend only on its width. `Spacer()` or
/// `maxHeight: .infinity` inside one makes it measure taller than it renders,
/// which shows up as content running off the bottom of a page.
struct PDFBlock {
    let view: AnyView

    /// Keeps this block on the same page as the one that follows it: a room
    /// title should not land as the last line of a page with its items
    /// orphaned overleaf. Ignored when the run is taller than a whole page.
    let keepWithNext: Bool

    init<V: View>(keepWithNext: Bool = false, @ViewBuilder view: () -> V) {
        self.view = AnyView(view())
        self.keepWithNext = keepWithNext
    }
}

@MainActor
struct PDFPaginator {
    var pageSize: CGSize = PDFWriter.letter
    var margin: CGFloat = 36

    /// The width every block is measured and laid out at.
    var contentWidth: CGFloat { pageSize.width - margin * 2 }

    // MARK: - Measure

    /// Natural height of a view laid out at `contentWidth` with unbounded
    /// height. Proposing a nil height makes `render` report the size SwiftUI
    /// actually chose; not invoking the draw closure means nothing rasterizes,
    /// so this costs layout only.
    func height<V: View>(of view: V) -> CGFloat {
        let renderer = ImageRenderer(content: view.frame(width: contentWidth))
        renderer.proposedSize = .init(width: contentWidth, height: nil)
        var measured: CGFloat = 0
        renderer.render { size, _ in measured = size.height }
        return measured
    }

    // MARK: - Paginate

    /// Packs blocks into pages, wrapping each in repeated chrome.
    /// `chrome` receives the 1-based page number and the final page count.
    ///
    /// Always returns at least one page, so an empty document still produces a
    /// valid PDF carrying its header rather than an unopenable file.
    func paginate(
        _ blocks: [PDFBlock],
        chrome: (Int, Int) -> AnyView = { _, _ in AnyView(EmptyView()) }
    ) -> [AnyView] {
        let available = pageSize.height - margin * 2 - height(of: chrome(1, 1))
        let measured = blocks.map { (block: $0, height: height(of: $0.view)) }

        var pages: [[PDFBlock]] = []
        var current: [PDFBlock] = []
        var used: CGFloat = 0
        var index = 0

        while index < measured.count {
            // A keepWithNext chain has to be placed as a single unit.
            var run = [measured[index]]
            while run.last?.block.keepWithNext == true, index + run.count < measured.count {
                run.append(measured[index + run.count])
            }
            let runHeight = run.reduce(0) { $0 + $1.height }

            // `used > 0` lets an over-tall run overflow its own page rather
            // than loop forever looking for one it fits.
            if used > 0, used + runHeight > available {
                pages.append(current)
                current = []
                used = 0
            }

            current.append(contentsOf: run.map(\.block))
            used += runHeight
            index += run.count
        }
        if !current.isEmpty || pages.isEmpty { pages.append(current) }

        return pages.enumerated().map { pageIndex, pageBlocks in
            page(pageBlocks, chrome: chrome(pageIndex + 1, pages.count))
        }
    }

    private func page(_ blocks: [PDFBlock], chrome: AnyView) -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 0) {
                chrome
                ForEach(Array(blocks.enumerated()), id: \.offset) { $0.element.view }
                Spacer(minLength: 0)
            }
            .frame(width: contentWidth, alignment: .topLeading)
            .padding(margin)
            .frame(width: pageSize.width, height: pageSize.height, alignment: .topLeading)
            .background(Color.white)
        )
    }
}
