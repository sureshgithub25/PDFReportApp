//
//  PDFService.swift
//  PDFReportApp
//
//  Created by Suresh Kumar on 24/08/25.
//

import PDFKit
import SwiftUI

final class PDFService {
    private let pageWidth: CGFloat = 8.5 * 72.0
    private let pageHeight: CGFloat = 11.0 * 72.0
    private let margin: CGFloat = 50.0
    private let rowHeight: CGFloat = 20.0
    private let headerHeight: CGFloat = 25.0
    
    func generatePDF(transactions: [Transaction], userDetails: UserDetails) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "PDF Report App",
            kCGPDFContextAuthor: "iOS Developer",
            kCGPDFContextTitle: "Transaction Report"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            var currentY: CGFloat = margin
            
            context.beginPage()
            
            // Add logo
            currentY = addLogo(context: context, currentY: currentY)
            
            // Add user details
            currentY = addUserDetails(context: context, userDetails: userDetails, currentY: currentY)
            
            // Add report heading
            currentY = addReportHeading(context: context, currentY: currentY)
            
            // Add table headers
            currentY = addTableHeaders(context: context, startY: currentY)
            
            // Add table rows
            addTableRows(context: context, transactions: transactions, startY: currentY)
            
            // Add page number
            addPageNumber(context: context, page: 1, totalPages: 1)
        }
        
        print("PDF generated with size: \(data.count) bytes")
        return data
    }
        
    private func addLogo(context: UIGraphicsPDFRendererContext, currentY: CGFloat) -> CGFloat {
          // Method 1: Using UIImage from Assets
          if let logoImage = UIImage(named: "CompanyLogo") {
              // Resize image if needed (maintain aspect ratio)
              let maxWidth: CGFloat = 100
              
              let aspectRatio = logoImage.size.width / logoImage.size.height
              let newWidth = min(maxWidth, logoImage.size.width)
              let newHeight = newWidth / aspectRatio
              
              let logoRect = CGRect(x: margin, y: currentY, width: newWidth, height: newHeight)
              logoImage.draw(in: logoRect)
              
              return currentY + newHeight + 20
          }
          else {
              let logoRect = CGRect(x: margin, y: currentY, width: 100, height: 50)
              UIColor.lightGray.setFill()
              context.fill(logoRect)
              
              let logoText = "Company Logo"
              let logoAttributes: [NSAttributedString.Key: Any] = [
                  .font: UIFont.systemFont(ofSize: 10),
                  .foregroundColor: UIColor.darkGray
              ]
              logoText.draw(at: CGPoint(x: margin + 25, y: currentY + 20), withAttributes: logoAttributes)
              
              return currentY + 70
          }
      }
    
    private func addUserDetails(context: UIGraphicsPDFRendererContext,
                              userDetails: UserDetails,
                              currentY: CGFloat) -> CGFloat {
        var y = currentY
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        let details = [
            "Name: \(userDetails.name)",
            "Email: \(userDetails.email)",
            "Mobile: \(userDetails.mobile)",
            "Card Number: \(userDetails.cardNumber)",
            "Card Type: \(userDetails.cardType)",
            "Address: \(userDetails.address)"
        ]
        
        for detail in details {
            detail.draw(at: CGPoint(x: margin, y: y), withAttributes: attributes)
            y += 18
        }
        
        return y + 25
    }
    
    private func addReportHeading(context: UIGraphicsPDFRendererContext, currentY: CGFloat) -> CGFloat {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MMM-yyyy"
        let dateRange = "\(dateFormatter.string(from: Date()))"
        
        let heading = "Transaction Report: \(dateRange)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        
        heading.draw(at: CGPoint(x: margin, y: currentY), withAttributes: attributes)
        
        return currentY + 30
    }
    
    private func addTableHeaders(context: UIGraphicsPDFRendererContext, startY: CGFloat) -> CGFloat {
        let columnWidths: [CGFloat] = [80, 100, 120, 70, 60, 60]
        let headers = ["Date", "Narration", "Transaction ID", "Status", "Credit", "Debit"]
        var currentX = margin
        
        //header background
        let headerRect = CGRect(x: margin, y: startY, width: columnWidths.reduce(0, +), height: headerHeight)
        UIColor(white: 0.9, alpha: 1.0).setFill()
        context.fill(headerRect)
        
        //header text
        for (index, header) in headers.enumerated() {
            let cellRect = CGRect(x: currentX, y: startY, width: columnWidths[index], height: headerHeight)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 10),
                .foregroundColor: UIColor.black
            ]
            
            let textRect = cellRect.insetBy(dx: 4, dy: (cellRect.height - 12) / 2)
            header.draw(in: textRect, withAttributes: attributes)
            
            // border
            UIColor.lightGray.setStroke()
            context.stroke(cellRect)
            
            currentX += columnWidths[index]
        }
        
        return startY + headerHeight
    }
    
    private func addTableRows(context: UIGraphicsPDFRendererContext, transactions: [Transaction], startY: CGFloat) {
        let columnWidths: [CGFloat] = [80, 100, 120, 70, 60, 60]
        var currentY = startY
        
        for transaction in transactions {
            let values = [
                formatDate(transaction.transactionDate),
                transaction.transactionCategory,
                transaction.id,
                transaction.status,
                transaction.transactionType == "CREDIT" ? transaction.amount : "",
                transaction.transactionType == "DEBIT" ? transaction.amount : ""
            ]
            
            var currentX = margin
            
            // cell background
            let cellRect = CGRect(x: margin, y: currentY, width: columnWidths.reduce(0, +), height: rowHeight)
            UIColor.white.setFill()
            context.fill(cellRect)
            
            // cell content
            for (index, value) in values.enumerated() {
                let cellRect = CGRect(x: currentX, y: currentY, width: columnWidths[index], height: rowHeight)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9),
                    .foregroundColor: UIColor.darkGray
                ]
                
                let textRect = cellRect.insetBy(dx: 4, dy: (cellRect.height - 12) / 2)
                value.draw(in: textRect, withAttributes: attributes)
                
                // border
                UIColor.lightGray.setStroke()
                context.stroke(cellRect)
                
                currentX += columnWidths[index]
            }
            
            currentY += rowHeight
            
            // Simple pagination - if we reach bottom, start new page
            if currentY > pageHeight - margin - 30 {
                context.beginPage()
                currentY = margin
                addPageNumber(context: context, page: 2, totalPages: 2)
            }
        }
    }
    
    private func addPageNumber(context: UIGraphicsPDFRendererContext, page: Int, totalPages: Int) {
        let pageText = "Page \(page) of \(totalPages)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray
        ]
        
        let textSize = pageText.size(withAttributes: attributes)
        let textX = pageWidth - margin - textSize.width
        let textY = pageHeight - margin + 10
        
        pageText.draw(at: CGPoint(x: textX, y: textY), withAttributes: attributes)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd MMM yyyy"
        return outputFormatter.string(from: date)
    }
}
