//
//  PDFReportAppApp.swift
//  PDFReportApp
//
//  Created by Suresh Kumar on 24/08/25.
//

import SwiftUI

@main
struct PDFReportAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            TransactionListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
