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
            
            part.frameInScopeContent = .init(centerX: availableRect.midX,
                                             centerY: availableRect.midY,
                                             width: availableRect.width,
                                             height: availableRect.height)
            
            if availableRect.width > 100, availableRect.height > 100
            {
                let padding = CodeArtifact.padding
                let headerHeight = part.fontSize + 2 * padding
                
                part.contentFrame = .init(x: padding,
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
            
            part.updateLayoutOfParts(forScopeSize: .init(width: part.contentFrame.width,
                                                         height: part.contentFrame.height),
                                     ignoreSearchFilter: ignoreSearchFilter)
            
            return availableRect.size.width >= CodeArtifact.minWidth &&
                availableRect.size.height >= CodeArtifact.minHeight
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
        let rectIsSmall = min(rect.width, rect.height) <= CodeArtifact.minWidth * 5
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
            let padding = rect.width > CodeArtifact.padding ? CodeArtifact.padding : 0
            
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
            let padding = rect.height > CodeArtifact.padding ? CodeArtifact.padding : 0
            
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
        if 2 * CodeArtifact.minWidth + CodeArtifact.padding > rect.width
        {
            return nil
        }
        
        var widthA = (rect.width - CodeArtifact.padding) * firstFraction
        var widthB = (rect.width - widthA) - CodeArtifact.padding
        
        if widthA < CodeArtifact.minWidth
        {
            widthA = CodeArtifact.minWidth
            widthB = (rect.width - CodeArtifact.minWidth) - CodeArtifact.padding
        }
        else if widthB < CodeArtifact.minWidth
        {
            widthB = CodeArtifact.minWidth
            widthA = (rect.width - CodeArtifact.minWidth) - CodeArtifact.padding
        }
        
        let rectA = CGRect(x: rect.minX,
                           y: rect.minY,
                           width: widthA,
                           height: rect.height)
        
        let rectB = CGRect(x: (rect.minX + widthA) + CodeArtifact.padding,
                           y: rect.minY,
                           width: widthB,
                           height: rect.height)
        
        return (rectA, rectB)
    }
    
    func splitIntoTopAndBottom(_ rect: CGRect, firstFraction: Double) -> (CGRect, CGRect)?
    {
        if 2 * CodeArtifact.minHeight + CodeArtifact.padding > rect.height
        {
            return nil
        }
        
        var heightA = (rect.height - CodeArtifact.padding) * firstFraction
        var heightB = (rect.height - heightA) - CodeArtifact.padding
        
        if heightA < CodeArtifact.minHeight
        {
            heightA = CodeArtifact.minHeight
            heightB = (rect.height - CodeArtifact.minHeight) - CodeArtifact.padding
        }
        else if heightB < CodeArtifact.minHeight
        {
            heightB = CodeArtifact.minHeight
            heightA = (rect.height - CodeArtifact.minHeight) - CodeArtifact.padding
        }
        
        let rectA = CGRect(x: rect.minX,
                           y: rect.minY,
                           width: rect.width,
                           height: heightA)
        
        let rectB = CGRect(x: rect.minX,
                           y: (rect.minY + heightA) + CodeArtifact.padding,
                           width: rect.width,
                           height: heightB)

        return (rectA, rectB)
    }
}

extension CodeArtifact
{
    var fontSize: Double
    {
        1.2 * sqrt(sqrt(frameInScopeContent.height * frameInScopeContent.width))
    }
    
    static var padding: Double = 16
    static var minWidth: Double = 30
    static var minHeight: Double = 30
}
