//
//  TransctionListView.swift
//  PDFReportApp
//
//  Created by Suresh Kumar on 24/08/25.
//

import SwiftUI
import Combine

struct TransactionListView: View {
    @StateObject private var viewModel = TransactionViewModel()
    @State private var showingPDFPreview = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading transactions...")
                } else if let error = viewModel.errorMessage {
                    ErrorView(error: error, retryAction: viewModel.fetchTransactions)
                } else {
                    transactionList
                }
            }
            .navigationTitle("Transaction Report")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Generate PDF") {
                        viewModel.generatePDF()
                        showingPDFPreview = true
                    }
                    .disabled(viewModel.transactions.isEmpty)
                }
            }
            .sheet(isPresented: $showingPDFPreview) {
                if let pdfData = viewModel.pdfData {
                    PDFPreviewView(pdfData: pdfData)
                }
            }
            .onAppear {
                viewModel.fetchTransactions()
            }
        }
    }
    
    private var transactionList: some View {
        List(viewModel.transactions) { transaction in
            TransactionRow(transaction: transaction)
        }
        .refreshable {
            viewModel.fetchTransactions()
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(transaction.narration)
                .font(.headline)
            Text("Date: \(transaction.date)")
                .font(.subheadline)
            Text("Amount: \(transaction.credit ?? transaction.debit ?? 0, format: .currency(code: "USD"))")
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}

struct ErrorView: View {
    let error: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack {
            Text("Error")
                .font(.title)
            Text(error)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Retry", action: retryAction)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
