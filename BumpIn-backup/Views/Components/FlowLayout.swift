import SwiftUI

struct FlowLayout: Layout {
    let spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        return CGSize(
            width: proposal.width ?? .zero,
            height: rows.last?.maxY ?? .zero
        )
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        
        for row in rows {
            let rowXOffset = (bounds.width - row.width) / 2
            var xOffset = rowXOffset
            
            for viewIndex in row.range {
                let view = subviews[viewIndex]
                let viewSize = view.sizeThatFits(.unspecified)
                
                view.place(
                    at: CGPoint(
                        x: xOffset + bounds.minX,
                        y: row.minY + bounds.minY
                    ),
                    proposal: ProposedViewSize(viewSize)
                )
                
                xOffset += viewSize.width + spacing
            }
        }
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row(range: 0..<0, minY: 0, maxY: 0, width: 0)
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxY: CGFloat = 0
        
        for (index, view) in subviews.enumerated() {
            let viewSize = view.sizeThatFits(.unspecified)
            
            if x + viewSize.width > (proposal.width ?? .zero) {
                rows.append(currentRow)
                currentRow = Row(range: index..<index, minY: maxY + spacing, maxY: maxY + spacing + viewSize.height, width: 0)
                y = maxY + spacing
                x = 0
            }
            
            if currentRow.range.isEmpty {
                currentRow.range = index..<(index + 1)
            } else {
                currentRow.range = currentRow.range.lowerBound..<(index + 1)
            }
            
            x += viewSize.width + spacing
            maxY = max(maxY, y + viewSize.height)
            currentRow.maxY = maxY
            currentRow.width = x - spacing
        }
        
        if !currentRow.range.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    struct Row {
        var range: Range<Int>
        var minY: CGFloat
        var maxY: CGFloat
        var width: CGFloat
    }
} 