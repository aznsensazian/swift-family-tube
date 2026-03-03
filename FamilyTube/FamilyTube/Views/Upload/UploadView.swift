import SwiftUI
import PhotosUI
import AVKit

struct UploadView: View {
    @EnvironmentObject var videoViewModel: VideoViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem?
    @State private var videoURL: URL?
    @State private var thumbnailImage: UIImage?
    @State private var videoDuration: TimeInterval = 0
    @State private var videoTitle = ""
    @State private var videoDescription = ""
    @State private var sharedEmails: [String] = []
    @State private var newEmail = ""
    @State private var isPublicToFamily = true
    @State private var showPhotoPicker = false
    @State private var step: UploadStep = .selectVideo

    enum UploadStep {
        case selectVideo
        case editDetails
        case uploading
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                switch step {
                case .selectVideo:
                    selectVideoStep
                case .editDetails:
                    editDetailsStep
                case .uploading:
                    uploadingStep
                }
            }
            .navigationTitle("Upload Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Step 1: Select Video

    private var selectVideoStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)

            Text("Select a Video")
                .font(.title2.bold())
                .foregroundColor(.white)

            Text("Choose a video from your photo library\nto share with your family")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            PhotosPicker(
                selection: $selectedItem,
                matching: .videos
            ) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("Choose from Library")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.red)
                .cornerRadius(28)
                .padding(.horizontal, 40)
            }
            .onChange(of: selectedItem) { _, newItem in
                handleVideoSelection(newItem)
            }

            Text("Supported: MP4, MOV, M4V")
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()
        }
    }

    // MARK: - Step 2: Edit Details

    private var editDetailsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Video preview
                if let thumbnail = thumbnailImage {
                    ZStack(alignment: .bottomTrailing) {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(12)

                        if videoDuration > 0 {
                            let formatted = formatDuration(videoDuration)
                            Text(formatted)
                                .font(.caption.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                                .padding(8)
                        }
                    }
                }

                // Title
                VStack(alignment: .leading, spacing: 6) {
                    Text("Title")
                        .font(.subheadline.bold())
                        .foregroundColor(.gray)

                    TextField("Add a title", text: $videoTitle)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(white: 0.12))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }

                // Description
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description")
                        .font(.subheadline.bold())
                        .foregroundColor(.gray)

                    TextField("Add a description", text: $videoDescription, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...6)
                        .padding()
                        .background(Color(white: 0.12))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }

                // Visibility
                VStack(alignment: .leading, spacing: 6) {
                    Text("Visibility")
                        .font(.subheadline.bold())
                        .foregroundColor(.gray)

                    Toggle(isOn: $isPublicToFamily) {
                        HStack {
                            Image(systemName: isPublicToFamily ? "person.3.fill" : "lock.fill")
                                .foregroundColor(.red)
                            VStack(alignment: .leading) {
                                Text(isPublicToFamily ? "All Family Members" : "Invite Only")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Text(isPublicToFamily
                                     ? "Anyone in your family group can view"
                                     : "Only people you invite can view")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .tint(.red)
                }

                // Share with specific people
                VStack(alignment: .leading, spacing: 10) {
                    Text("Share with")
                        .font(.subheadline.bold())
                        .foregroundColor(.gray)

                    // Add email
                    HStack {
                        TextField("Enter email address", text: $newEmail)
                            .textFieldStyle(.plain)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .padding()
                            .background(Color(white: 0.12))
                            .cornerRadius(10)
                            .foregroundColor(.white)

                        Button(action: addEmail) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                        .disabled(newEmail.isEmpty || !newEmail.contains("@"))
                    }

                    // Quick add family members
                    if let user = authViewModel.currentUser, !user.familyMembers.isEmpty {
                        Text("Family members")
                            .font(.caption)
                            .foregroundColor(.gray)

                        FlowLayout(spacing: 8) {
                            ForEach(user.familyMembers, id: \.self) { member in
                                Button(action: {
                                    if !sharedEmails.contains(member) {
                                        sharedEmails.append(member)
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: sharedEmails.contains(member) ? "checkmark.circle.fill" : "plus.circle")
                                            .font(.caption)
                                        Text(member)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        sharedEmails.contains(member)
                                            ? Color.red.opacity(0.3)
                                            : Color(white: 0.2)
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                }
                            }
                        }
                    }

                    // Added emails list
                    ForEach(sharedEmails, id: \.self) { email in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.gray)
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: { sharedEmails.removeAll { $0 == email } }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Upload button
                Button(action: startUpload) {
                    Text("Upload Video")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            videoTitle.isEmpty ? Color.gray : Color.red
                        )
                        .cornerRadius(28)
                }
                .disabled(videoTitle.isEmpty)
                .padding(.top, 8)
            }
            .padding()
            .padding(.bottom, 40)
        }
    }

    // MARK: - Step 3: Uploading

    private var uploadingStep: some View {
        VStack(spacing: 24) {
            Spacer()

            if videoViewModel.uploadProgress >= 1.0 {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text("Upload Complete!")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Button("Done") { dismiss() }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.red)
                    .cornerRadius(25)
            } else {
                ZStack {
                    Circle()
                        .stroke(Color(white: 0.2), lineWidth: 8)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: videoViewModel.uploadProgress)
                        .stroke(Color.red, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: videoViewModel.uploadProgress)

                    Text("\(Int(videoViewModel.uploadProgress * 100))%")
                        .font(.title.bold())
                        .foregroundColor(.white)
                }

                Text("Uploading...")
                    .font(.title3)
                    .foregroundColor(.white)

                Text("Please keep the app open")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            if let error = videoViewModel.errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button("Retry") { startUpload() }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.red)
                    .cornerRadius(25)
            }

            Spacer()
        }
    }

    // MARK: - Helpers

    private func handleVideoSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("mp4")

                try? data.write(to: tempURL)
                videoURL = tempURL

                thumbnailImage = await ThumbnailGenerator.generateThumbnail(from: tempURL)
                videoDuration = await ThumbnailGenerator.getVideoDuration(from: tempURL)

                step = .editDetails
            }
        }
    }

    private func addEmail() {
        let email = newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if !email.isEmpty, email.contains("@"), !sharedEmails.contains(email) {
            sharedEmails.append(email)
            newEmail = ""
        }
    }

    private func startUpload() {
        guard let videoURL = videoURL else { return }
        step = .uploading

        videoViewModel.uploadVideo(
            fileURL: videoURL,
            title: videoTitle,
            description: videoDescription,
            sharedEmails: sharedEmails,
            isPublicToFamily: isPublicToFamily
        )
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Flow Layout for email chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxHeight = max(maxHeight, currentY + rowHeight)
        }

        return (positions, CGSize(width: maxWidth, height: maxHeight))
    }
}

#Preview {
    UploadView()
        .environmentObject(VideoViewModel())
        .environmentObject(AuthViewModel())
}
