import SwiftUI

struct EntriesListView: View {
    @State private var viewModel = EntriesListViewModel()
    @State private var showingAddEntry = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    ForEach(viewModel.entries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.id).font(.headline)
                            Text(entry.value).font(.subheadline).foregroundStyle(.secondary)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await viewModel.deleteEntry(key: entry.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)

                VStack(spacing: 12) {
                    HStack {
                        TextField("Search prefix", text: $viewModel.searchPrefix)
                            .textFieldStyle(.roundedBorder)
                        Button("Search") {
                            Task { await viewModel.searchKeys() }
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    if !viewModel.filteredKeys.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(viewModel.filteredKeys, id: \.self) { key in
                                    Text(key)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }

                    Button("Get Random Value") {
                        Task { await viewModel.getRandomValue() }
                    }
                    .buttonStyle(.bordered)

                    if !viewModel.randomValue.isEmpty {
                        Text("Random: \(viewModel.randomValue)")
                            .font(.caption)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }

                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(uiColor: .systemGroupedBackground))
            }
            .navigationTitle("Key-Value Storage")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAddEntry = true } label: {
                        Image(systemName: "search")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAddEntry = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear All") {
                        Task { await viewModel.clearAll() }
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddEntryView(viewModel: viewModel)
            }
            .task { await viewModel.refresh() }
        }
    }
}
