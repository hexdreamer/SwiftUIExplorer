import SwiftUI
import Combine

// https://www.vadimbulavin.com/asynchronous-swiftui-image-loading-from-url-with-combine-and-swift/
struct SEAsyncImage<Content:View>: View {
    @ObservedObject private var loader: ImageLoader
    private let placeholder:()->Content
        
    init(url: URL, placeholder:@escaping ()->Content) {
        self.loader = ImageLoader(url: url)
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if self.loader.image != nil {
                Image(uiImage:self.loader.image!)
                    .resizable()
            } else {
                self.placeholder()
                    .onAppear(perform: loader.load)
                    .onDisappear(perform: loader.cancel)
            }
        }
    }
}

class ImageLoader: ObservableObject {
    @Published var image:UIImage?
    
    private let url:URL
    private var dataTask:AnyCancellable?
    
    init(url:URL) {
        self.url = url
    }
    
    deinit {
        self.cancel()
    }
    
    func load() {
        self.dataTask = URLSession.shared.dataTaskPublisher(for:url)
            .map { UIImage(data:$0.data) }
            .replaceError(with:nil)
            .receive(on:DispatchQueue.main)
            .assign(to:\.image, on:self)
    }
    
    func cancel() {
        self.dataTask?.cancel()
    }
}
