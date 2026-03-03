import SwiftUI

struct ShareVideoView: View {
    let video: Video
    @EnvironmentObject var videoViewModel: VideoViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var emailToShare = ""
    @State private var selectedFamilyMembers: Set<String> = []
    @State private var isSharing = false
    @State private var shareComplete = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Video preview
                        HStack(spacing: 12) {
                            Rectangle()
                                .fill(Color(white: 0.15))
                                .frame(width: 120, height: 68)
                                .cornerRadius(8)
                                .overlay(
                                    Image(systemName: "video.fill")
                                        .foregroundColor(.gray)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(video.title)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                Text(video.formattedDuration)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(white: 0.1))
                        .cornerRadius(12)

                        // Already shared with
                        if !video.sharedWith.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Already shared with")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.gray)

                                ForEach(video.sharedWith, id: \.self) { email in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text(email)
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }

                        Divider().background(Color.gray.opacity(0.3))

                        // Share by email
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Share by email")
                                .font(.headline)
                                .foregroundColor(.white)

                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(.gray)

                                TextField("Enter email address", text: $emailToShare)
                                    .textFieldStyle(.plain)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .foregroundColor(.white)

                                Button(action: shareWithEmail) {
                                    Text("Send")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            emailToShare.contains("@") ? Color.red : Color.gray
                                        )
                                        .cornerRadius(20)
                                }
                                .disabled(!emailToShare.contains("@"))
                            }
                            .padding()
                            .background(Color(white: 0.12))
                            .cornerRadius(10)
                        }

                        // Family members quick share
                        if let user = authViewModel.currentUser, !user.familyMembers.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Family Members")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                ForEach(user.familyMembers, id: \.self) { member in
                                    let alreadyShared = video.sharedWith.contains(member)

                                    Button(action: {
                                        if !alreadyShared {
                                            if selectedFamilyMembers.contains(member) {
                                                selectedFamilyMembers.remove(member)
                                            } else {
                                                selectedFamilyMembers.insert(member)
                                            }
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "person.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(alreadyShared ? .green : .gray)

                                            Text(member)
                                                .font(.subheadline)
                                                .foregroundColor(.white)

                                            Spacer()

                                            if alreadyShared {
                                                Text("Shared")
                                                    .font(.caption)
                                                    .foregroundColor(.green)
                                            } else if selectedFamilyMembers.contains(member) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.red)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .padding()
                                        .background(Color(white: 0.12))
                                        .cornerRadius(10)
                                    }
                                    .disabled(alreadyShared)
                                }

                                if !selectedFamilyMembers.isEmpty {
                                    Button(action: shareWithSelected) {
                                        HStack {
                                            Image(systemName: "paperplane.fill")
                                            Text("Share with \(selectedFamilyMembers.count) member\(selectedFamilyMembers.count == 1 ? "" : "s")")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Color.red)
                                        .cornerRadius(25)
                                    }
                                }
                            }
                        }

                        if shareComplete {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Invite sent successfully!")
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Share Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func shareWithEmail() {
        let email = emailToShare.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty, email.contains("@") else { return }

        isSharing = true
        videoViewModel.shareVideo(video, withEmail: email)
        emailToShare = ""
        shareComplete = true
        isSharing = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            shareComplete = false
        }
    }

    private func shareWithSelected() {
        isSharing = true
        for member in selectedFamilyMembers {
            videoViewModel.shareVideo(video, withEmail: member)
        }
        selectedFamilyMembers.removeAll()
        shareComplete = true
        isSharing = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            shareComplete = false
        }
    }
}

#Preview {
    ShareVideoView(video: .preview)
        .environmentObject(VideoViewModel())
        .environmentObject(AuthViewModel())
}
