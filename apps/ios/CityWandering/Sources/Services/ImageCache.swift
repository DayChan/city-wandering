import SwiftUI

// MARK: - Cache

final class ImageCache {
    static let shared = ImageCache()
    private let memory = NSCache<NSString, UIImage>()

    private init() {
        memory.countLimit = 150
        memory.totalCostLimit = 150 * 1024 * 1024  // 150 MB

        // 磁盘缓存：200 MB，存在 Caches 目录
        let diskCapacity = 200 * 1024 * 1024
        let cache = URLCache(memoryCapacity: 20 * 1024 * 1024,
                             diskCapacity: diskCapacity)
        URLCache.shared = cache
    }

    func get(_ url: URL) -> UIImage? {
        memory.object(forKey: url.absoluteString as NSString)
    }

    func set(_ image: UIImage, for url: URL) {
        let cost = Int(image.size.width * image.size.height * 4)
        memory.setObject(image, forKey: url.absoluteString as NSString, cost: cost)
    }
}

// MARK: - Loader

@MainActor
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    private var url: URL?
    private var task: Task<Void, Never>?

    func load(_ url: URL) {
        guard self.url != url else { return }
        self.url = url

        // 命中内存缓存直接返回
        if let cached = ImageCache.shared.get(url) {
            self.image = cached
            return
        }

        task?.cancel()
        isLoading = true
        task = Task {
            do {
                // URLCache 会自动处理磁盘缓存
                let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
                let (data, _) = try await URLSession.shared.data(for: request)
                guard !Task.isCancelled, let img = UIImage(data: data) else { return }
                ImageCache.shared.set(img, for: url)
                self.image = img
            } catch {}
            self.isLoading = false
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}

// MARK: - CachedAsyncImage

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @StateObject private var loader = ImageLoader()

    init(url: URL,
         @ViewBuilder content: @escaping (Image) -> Content,
         @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let img = loader.image {
                content(Image(uiImage: img))
            } else {
                placeholder()
            }
        }
        .onAppear { loader.load(url) }
        .onDisappear { loader.cancel() }
    }
}
