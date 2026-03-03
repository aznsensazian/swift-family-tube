import SwiftUI

struct FamilyManagerView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var newMemberEmail = ""
    @State private var showRemoveConfirmation = false
    @State private var memberToRemove: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header info
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Family Group")
                                .font(.title2.bold())
                                .foregroundColor(.white)

                            Text("Add family members to easily share videos with them. Family members can view videos marked as \"All Family\".")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)

                        // Add member
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Add Family Member")
                                .font(.headline)
                                .foregroundColor(.white)

                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(.gray)

                                TextField("Email address", text: $newMemberEmail)
                                    .textFieldStyle(.plain)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color(white: 0.12))
                            .cornerRadius(10)

                            Button(action: addMember) {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                    Text("Add to Family")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    newMemberEmail.contains("@") ? Color.red : Color.gray
                                )
                                .cornerRadius(25)
                            }
                            .disabled(!newMemberEmail.contains("@"))
                        }
                        .padding(.horizontal)

                        Divider().background(Color.gray.opacity(0.3)).padding(.horizontal)

                        // Members list
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Members (\(authViewModel.currentUser?.familyMembers.count ?? 0))")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)

                            if let members = authViewModel.currentUser?.familyMembers, !members.isEmpty {
                                ForEach(members, id: \.self) { member in
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.red.opacity(0.2))
                                                .frame(width: 44, height: 44)

                                            Text(String(member.prefix(1)).uppercased())
                                                .font(.headline)
                                                .foregroundColor(.red)
                                        }

                                        VStack(alignment: .leading) {
                                            Text(member)
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                            Text("Family member")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }

                                        Spacer()

                                        Button(action: {
                                            memberToRemove = member
                                            showRemoveConfirmation = true
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding()
                                    .background(Color(white: 0.1))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                }
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "person.3")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)

                                    Text("No family members yet")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)

                                    Text("Add email addresses above to build your family group")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                            }
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Family Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .alert("Remove Member", isPresented: $showRemoveConfirmation) {
                Button("Cancel", role: .cancel) { memberToRemove = nil }
                Button("Remove", role: .destructive) {
                    if let member = memberToRemove {
                        authViewModel.removeFamilyMember(email: member)
                    }
                    memberToRemove = nil
                }
            } message: {
                if let member = memberToRemove {
                    Text("Remove \(member) from your family group?")
                } else {
                    Text("Remove this member?")
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func addMember() {
        let email = newMemberEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty, email.contains("@") else { return }
        authViewModel.addFamilyMember(email: email)
        newMemberEmail = ""
    }
}

#Preview {
    FamilyManagerView()
        .environmentObject(AuthViewModel())
}
