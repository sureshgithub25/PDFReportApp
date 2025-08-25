//
//  TransactionViewModel.swift
//  PDFReportApp
//
//  Created by Suresh Kumar on 24/08/25.
//

import Combine
import SwiftUI

final class TransactionViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var pdfData: Data?
    
    private let networkService: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }
    
    func fetchTransactions() {
        isLoading = true
        errorMessage = nil
        
        networkService.request(TransactionEndpoint.getHistory)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.message
                }
            } receiveValue: { [weak self] (response: [Transaction]) in
                self?.transactions = response
            }
            .store(in: &cancellables)
    }
    
    func generatePDF() {
        let pdfService = PDFService()
        let userDetails = UserDetails(
            name: "Suresh Kumar",
            email: "sureshur@gamil.com",
            mobile: "123-456-7890",
            cardNumber: "**** **** **** 1234",
            cardType: "Visa",
            address: "sector 28, gurugram"
        )
        
        pdfData = pdfService.generatePDF(
            transactions: transactions,
            userDetails: userDetails
        )
    }
}

struct UserDetails {
    let name: String
    let email: String
    let mobile: String
    let cardNumber: String
    let cardType: String
    let address: String
}
