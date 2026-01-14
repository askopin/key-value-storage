import SwiftUI

struct AddEntryView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: EntriesListViewModel

    @State private var key: String = ""
    @State private var value: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Entry Details") {
                    TextField("Key", text: $key).autocorrectionDisabled()
                    TextField("Value", text: $value).autocorrectionDisabled()
                }
            }
            .navigationTitle("Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await viewModel.addEntry(key: key, value: value)
                            dismiss()
                        }
                    }
                    .disabled(key.isEmpty || value.isEmpty)
                }
            }
        }
    }
}
