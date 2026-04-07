import SwiftUI
import PhotosUI
import Supabase

@MainActor
class CheckInViewModel: ObservableObject {
    @Published var note = ""
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var photoImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadPhoto() async {
        guard let item = selectedPhoto else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let img = UIImage(data: data) {
            photoImage = img
        }
    }

    func submit(cardId: String, userId: String) async throws {
        isLoading = true
        defer { isLoading = false }

        var photoUrl: String? = nil

        // 上传图片
        if let img = photoImage,
           let data = img.jpegData(compressionQuality: 0.8) {
            let path = "\(userId)/\(UUID().uuidString).jpg"
            try await supabase.storage
                .from("check-in-photos")
                .upload(path, data: data, options: .init(contentType: "image/jpeg"))
            let url = try supabase.storage.from("check-in-photos").getPublicURL(path: path)
            photoUrl = url.absoluteString
        }

        // 创建打卡记录
        struct CheckInInsert: Encodable {
            let card_id: String
            let user_id: String
            let note: String?
            let photo_url: String?
        }

        try await supabase.from("check_ins").insert(
            CheckInInsert(
                card_id: cardId,
                user_id: userId,
                note: note.isEmpty ? nil : note,
                photo_url: photoUrl
            )
        ).execute()
    }
}

struct CheckInSheet: View {
    let card: Card
    let userId: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = CheckInViewModel()
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 卡片预览
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: card.theme.symbolName)
                            Text(card.theme.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(card.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // 照片选择
                    PhotosPicker(selection: $vm.selectedPhoto, matching: .images) {
                        if let img = vm.photoImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal)
                        } else {
                            HStack(spacing: 10) {
                                Image(systemName: "camera.fill")
                                Text("添加照片（可选）")
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        }
                    }
                    .onChange(of: vm.selectedPhoto) { _, _ in
                        Task { await vm.loadPhoto() }
                    }

                    // 备注
                    VStack(alignment: .leading, spacing: 8) {
                        Text("备注（可选）")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("写下你的感受…", text: $vm.note, axis: .vertical)
                            .lineLimit(3...6)
                            .padding()
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    // 提交按钮
                    Button {
                        Task {
                            do {
                                try await vm.submit(cardId: card.id, userId: userId)
                                showSuccess = true
                                try? await Task.sleep(nanoseconds: 800_000_000)
                                dismiss()
                            } catch {
                                vm.errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        HStack {
                            if vm.isLoading {
                                ProgressView().tint(.white)
                            } else if showSuccess {
                                Image(systemName: "checkmark")
                                Text("已打卡！")
                            } else {
                                Image(systemName: "mappin.circle.fill")
                                Text("完成打卡")
                            }
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(showSuccess ? Color.green : Color.primary)
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                    .disabled(vm.isLoading || showSuccess)

                    Spacer(minLength: 20)
                }
                .padding(.top, 16)
            }
            .navigationTitle("完成打卡")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}
