import SwiftUI

struct CitySelectorView: View {
    @ObservedObject var store: LocationStore
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var filteredCities: [CityDef]? {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return nil }
        return allCities.filter { $0.label.contains(q) || $0.slug.contains(q.lowercased()) }
    }

    var body: some View {
        NavigationStack {
            List {
                // 自动检测
                Section {
                    Button {
                        Task {
                            await store.detectFromGPS()
                            dismiss()
                        }
                    } label: {
                        Label(store.isDetecting ? "定位中…" : "GPS 定位", systemImage: "location.fill")
                    }

                    Button {
                        Task {
                            store.reset()
                            await store.detectFromIP()
                            dismiss()
                        }
                    } label: {
                        Label("IP 自动检测", systemImage: "network")
                    }

                    if store.city != nil {
                        Button(role: .destructive) {
                            store.reset()
                            dismiss()
                        } label: {
                            Label("清除当前城市", systemImage: "xmark.circle")
                        }
                    }
                } header: {
                    Text("自动检测")
                }

                // 城市列表
                if let filtered = filteredCities {
                    Section("搜索结果") {
                        cityRows(filtered)
                    }
                } else {
                    ForEach([CityDef.Region.china, .eastAsia, .northAmerica], id: \.rawValue) { region in
                        let cities = allCities.filter { $0.region == region }
                        Section(region.label) {
                            cityRows(cities)
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "搜索城市…")
            .navigationTitle("选择城市")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func cityRows(_ cities: [CityDef]) -> some View {
        ForEach(cities) { city in
            Button {
                store.selectManual(city)
                dismiss()
            } label: {
                HStack {
                    Text(city.label)
                        .foregroundStyle(.primary)
                    Spacer()
                    if store.city?.slug == city.slug {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.primary)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}
