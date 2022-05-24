import Foundation

extension CodeArtifact
{
    func updateLayoutOfParts(forScopeSize scopeSize: CGSize,
                             ignoreSearchFilter: Bool)
    {
        let presentedParts = ignoreSearchFilter ? parts : filteredParts
        
        guard !presentedParts.isEmpty else
        {
            showsContent = false
            return
        }
        
        showsContent = prepare(parts: presentedParts,
                               forLayoutIn: .init(x: 0,
                                                  y: 0,
                                                  width: scopeSize.width,
                                                  height: scopeSize.height),
                               ignoreSearchFilter: ignoreSearchFilter)
    }
    
    @discardableResult
    private func prepare(parts: [CodeArtifact],
                         forLayoutIn availableRect: CGRect,
                         ignoreSearchFilter: Bool) -> Bool
    {
        if parts.isEmpty { return false }
        
        // base case
        if parts.count == 1
        {
            let part = parts[0]
            
            part.frameInScopeContent = .init(width: availableRect.width,
                                             height: availableRect.height,
                                             centerX: availableRect.midX,
                                             centerY: availableRect.midY)
            
            if availableRect.width > 100, availableRect.height > 100
            {
                let padding = CodeArtifact.LayoutModel.padding
                let headerHeight = part.frameInScopeContent.fontSize + 2 * padding
                
                part.contentFrame = CGRect(x: padding,
                                           y: headerHeight,
                                           width: availableRect.width - (2 * padding),
                                           height: (availableRect.height - padding) - headerHeight)
            }
            else
            {
                part.contentFrame = .init(x: (availableRect.width / 2) - 2,
                                          y: (availableRect.height / 2) - 2,
                                          width: 4,
                                          height: 4)
            }
            
            part.updateLayoutOfParts(forScopeSize: part.contentFrame.size,
                                     ignoreSearchFilter: ignoreSearchFilter)
            
            return availableRect.size.width >= CodeArtifact.LayoutModel.minWidth &&
                availableRect.size.height >= CodeArtifact.LayoutModel.minHeight
        }
        
        // tree map algorithm
        let (partsA, partsB) = split(parts)
        
        let locA = partsA.reduce(0) { $0 + $1.linesOfCode }
        let locB = partsB.reduce(0) { $0 + $1.linesOfCode }
        
        let fractionA = Double(locA) / Double(locA + locB)
        
        let properRectSplit = split(availableRect, firstFraction: fractionA)
        
        let rectSplitToUse = properRectSplit ?? forceSplit(availableRect)
        
        let successA = prepare(parts: partsA,
                               forLayoutIn: rectSplitToUse.0,
                               ignoreSearchFilter: ignoreSearchFilter)
        
        let successB = prepare(parts: partsB,
                               forLayoutIn: rectSplitToUse.1,
                               ignoreSearchFilter: ignoreSearchFilter)
        
        return properRectSplit != nil && successA && successB
    }
    
    func split(_ parts: [CodeArtifact]) -> ([CodeArtifact], [CodeArtifact])
    {
        let halfTotalLOC = (parts.reduce(0) { $0 + $1.linesOfCode }) / 2
        
        var partsALOC = 0
        var minDifferenceToHalfTotalLOC = Int.max
        var optimalEndIndexForPartsA = 0
        
        for index in 0 ..< parts.count
        {
            let part = parts[index]
            partsALOC += part.linesOfCode
            let differenceToHalfTotalLOC = abs(halfTotalLOC - partsALOC)
            if differenceToHalfTotalLOC < minDifferenceToHalfTotalLOC
            {
                minDifferenceToHalfTotalLOC = differenceToHalfTotalLOC
                optimalEndIndexForPartsA = index
            }
        }
        
        return (Array(parts[0 ... optimalEndIndexForPartsA]),
                Array(parts[optimalEndIndexForPartsA + 1 ..< parts.count]))
    }
    
    func split(_ rect: CGRect,
               firstFraction: Double) -> (CGRect, CGRect)?
    {
        let rectIsSmall = min(rect.width, rect.height) <= CodeArtifact.LayoutModel.minWidth * 5
        let rectAspectRatio = rect.width / rect.height
        let tryLeftRightSplitFirst = rectAspectRatio > (rectIsSmall ? 4 : 2)
        
        if tryLeftRightSplitFirst
        {
            let result = splitIntoLeftAndRight(rect, firstFraction: firstFraction)
            
            return result ?? splitIntoTopAndBottom(rect, firstFraction: firstFraction)
        }
        else
        {
            let result = splitIntoTopAndBottom(rect, firstFraction: firstFraction)
            
            return result ?? splitIntoLeftAndRight(rect, firstFraction: firstFraction)
        }
    }
    
    func forceSplit(_ rect: CGRect) -> (CGRect, CGRect)
    {
        if rect.width / rect.height > 1
        {
            let padding = rect.width > CodeArtifact.LayoutModel.padding ? CodeArtifact.LayoutModel.padding : 0
            
            let width = (rect.width - padding) / 2
            
            return (CGRect(x: rect.minX,
                           y: rect.minY,
                           width: width,
                           height: rect.height),
                    CGRect(x: rect.minX + width + padding,
                           y: rect.minY,
                           width: width,
                           height: rect.height))
        }
        else
        {
            let padding = rect.height > CodeArtifact.LayoutModel.padding ? CodeArtifact.LayoutModel.padding : 0
            
            let height = (rect.height - padding) / 2
            
            return (CGRect(x: rect.minX,
                           y: rect.minY,
                           width: rect.width,
                           height: height),
                    CGRect(x: rect.minX,
                           y: rect.minY + height + padding,
                           width: rect.width,
                           height: height))
        }
    }
    
    func splitIntoLeftAndRight(_ rect: CGRect, firstFraction: Double) -> (CGRect, CGRect)?
    {
        if 2 * CodeArtifact.LayoutModel.minWidth + CodeArtifact.LayoutModel.padding > rect.width
        {
            return nil
        }
        
        var widthA = (rect.width - CodeArtifact.LayoutModel.padding) * firstFraction
        var widthB = (rect.width - widthA) - CodeArtifact.LayoutModel.padding
        
        if widthA < CodeArtifact.LayoutModel.minWidth
        {
            widthA = CodeArtifact.LayoutModel.minWidth
            widthB = (rect.width - CodeArtifact.LayoutModel.minWidth) - CodeArtifact.LayoutModel.padding
        }
        else if widthB < CodeArtifact.LayoutModel.minWidth
        {
            widthB = CodeArtifact.LayoutModel.minWidth
            widthA = (rect.width - CodeArtifact.LayoutModel.minWidth) - CodeArtifact.LayoutModel.padding
        }
        
        let rectA = CGRect(x: rect.minX,
                           y: rect.minY,
                           width: widthA,
                           height: rect.height)
        
        let rectB = CGRect(x: (rect.minX + widthA) + CodeArtifact.LayoutModel.padding,
                           y: rect.minY,
                           width: widthB,
                           height: rect.height)
        
        return (rectA, rectB)
    }
    
    func splitIntoTopAndBottom(_ rect: CGRect, firstFraction: Double) -> (CGRect, CGRect)?
    {
        if 2 * CodeArtifact.LayoutModel.minHeight + CodeArtifact.LayoutModel.padding > rect.height
        {
            return nil
        }
        
        var heightA = (rect.height - CodeArtifact.LayoutModel.padding) * firstFraction
        var heightB = (rect.height - heightA) - CodeArtifact.LayoutModel.padding
        
        if heightA < CodeArtifact.LayoutModel.minHeight
        {
            heightA = CodeArtifact.LayoutModel.minHeight
            heightB = (rect.height - CodeArtifact.LayoutModel.minHeight) - CodeArtifact.LayoutModel.padding
        }
        else if heightB < CodeArtifact.LayoutModel.minHeight
        {
            heightB = CodeArtifact.LayoutModel.minHeight
            heightA = (rect.height - CodeArtifact.LayoutModel.minHeight) - CodeArtifact.LayoutModel.padding
        }
        
        let rectA = CGRect(x: rect.minX,
                           y: rect.minY,
                           width: rect.width,
                           height: heightA)
        
        let rectB = CGRect(x: rect.minX,
                           y: (rect.minY + heightA) + CodeArtifact.LayoutModel.padding,
                           width: rect.width,
                           height: heightB)

        return (rectA, rectB)
    }
}

extension CodeArtifact.LayoutModel
{
    var fontSize: Double { 1.2 * sqrt(sqrt(height * width)) }
    
    static var padding: Double = 16
    static var minWidth: Double = 30
    static var minHeight: Double = 30
}