import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.15, green: 0.0, blue: 0.0)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Logo
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.red)
                            .frame(width: 100, height: 70)

                        Image(systemName: "play.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    }

                    Text("Family Tube")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)

                    Text("Private family video sharing")
                        .font(.title3)
                        .foregroundColor(.gray)
                }

                // Features
                VStack(alignment: .leading, spacing: 20) {
                    FeatureRow(icon: "video.fill", text: "Upload & share family videos")
                    FeatureRow(icon: "lock.shield.fill", text: "Private, invite-only viewing")
                    FeatureRow(icon: "icloud.fill", text: "Stored securely on Google Drive")
                    FeatureRow(icon: "person.3.fill", text: "Share with family members only")
                }
                .padding(.horizontal, 40)

                Spacer()

                // Sign In Button
                Button(action: {
                    authViewModel.signIn()
                }) {
                    HStack(spacing: 12) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Image(systemName: "g.circle.fill")
                                .font(.title2)
                        }
                        Text("Sign in with Google")
                            .font(.headline)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(28)
                }
                .disabled(authViewModel.isLoading)
                .padding(.horizontal, 40)

                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Text("Your videos are stored in your own Google Drive")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 30)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.red)
                .frame(width: 30)

            Text(text)
                .font(.body)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthViewModel())
}
