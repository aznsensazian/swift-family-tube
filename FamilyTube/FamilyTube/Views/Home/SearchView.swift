import SwiftUI

struct SearchView: View {
    @EnvironmentObject var videoViewModel: VideoViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    private var searchResults: [Video] {
        guard !searchText.isEmpty else { return [] }
        return videoViewModel.videos.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText) ||
            $0.uploaderName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)

                            TextField("Search family videos", text: $searchText)
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                                .focused($isSearchFocused)

                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color(white: 0.15))
                        .cornerRadius(24)

                        Button("Cancel") { dismiss() }
                            .foregroundColor(.white)
                    }
                    .padding()

                    if searchText.isEmpty {
                        // Recent / Suggestions
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Try searching for")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.horizontal)

                            ForEach(["Birthday", "Vacation", "Holiday", "First steps"], id: \.self) { suggestion in
                                Button(action: { searchText = suggestion }) {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(.gray)
                                        Text(suggestion)
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        .padding(.top, 8)
                    } else if searchResults.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No results for \"\(searchText)\"")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Try different keywords")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(searchResults) { video in
                                    NavigationLink(destination: VideoPlayerView(video: video)) {
                                        CompactVideoCardView(video: video)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                        }
                    }

                    Spacer()
                }
            }
            .onAppear {
                isSearchFocused = true
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SearchView()
        .environmentObject(VideoViewModel())
}
