//
//  PDFPreviewView.swift
//  PDFReportApp
//
//  Created by Suresh Kumar on 24/08/25.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct PDFPreviewView: View {
    let pdfData: Data
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var showSuccessAlert = false
    @State private var pdfDocument: PDFDocument?
    
    var body: some View {
        NavigationView {
            VStack {
                if let pdfDocument = pdfDocument {
                    PDFKitView(data: pdfData)
                } else {
                    VStack(spacing: 16) {
                        Text("Unable to load PDF")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text("PDF data size: \(pdfData.count) bytes")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
                
                HStack {
                    Button(action: {
                        savePDFToDocuments()
                    }) {
                        Label("", systemImage: "square.and.arrow.down")
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    Spacer()
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Label("", systemImage: "square.and.arrow.up")
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("PDF Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [pdfData as Any])
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("PDF saved to Documents")
            }
            .onAppear {
                pdfDocument = PDFDocument(data: pdfData)
                if pdfDocument == nil {
                    print("Failed to create PDFDocument from data")
                }
            }
        }
    }
    
    private func savePDFToDocuments() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        let dateString = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let fileURL = documentsPath.appendingPathComponent("Transaction_Report_\(dateString).pdf")
        
        do {
            try pdfData.write(to: fileURL)
            print("PDF saved successfully at: \(fileURL.path)")
            showSuccessAlert = true
        } catch {
            print("Error saving PDF: \(error.localizedDescription)")
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: data)
        pdfView.autoScales = true
        pdfView.backgroundColor = .systemGray6
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {}
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct PDFFile: Transferable {
    let data: Data
    let fileName: String
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .pdf) { file in
            file.data
        } importing: { data in
            PDFFile(data: data, fileName: "Transaction_Report.pdf")
        }
    }
}

extension UTType {
    static var pdf: UTType {
        UTType(exportedAs: "com.adobe.pdf")
    }
}
