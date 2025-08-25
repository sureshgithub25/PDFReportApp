//
//  TransactionModel.swift
//  PDFReportApp
//
//  Created by Suresh Kumar on 24/08/25.
//


struct Transaction: Codable, Identifiable {
    let id: String
    let transactionDate: String
    let transactionCategory: String
    let status: String
    let amount: String
    let transactionType: String
    
    var date: String {
        return transactionDate
    }
    
    var narration: String {
        return transactionCategory
    }
    
    var credit: Double? {
        return transactionType == "CREDIT" ? Double(amount) : nil
    }
    
    var debit: Double? {
        return transactionType == "DEBIT" ? Double(amount) : nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "transactionID"
        case transactionDate
        case transactionCategory
        case status
        case amount
        case transactionType
    }
}

struct TransactionResponse: Codable {
    let transactions: [Transaction]
    let totalCount: Int
}
