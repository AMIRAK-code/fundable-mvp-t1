import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: PetStore
    @State private var showingPetForm = false

    var body: some View {
        ZStack {
            CalmBackground()
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(CalmPalette.sage)
                Text("Pet Monitor")
                    .font(.largeTitle.weight(.semibold))
                Text("Gentle, daily awareness of your companion's wellbeing.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        featureRow("checklist", "Calm check-ins",
                                   "Log mood, energy and appetite on a gentle cycle.")
                        featureRow("stethoscope", "Health guidance",
                                   "Spot early signals — and always loop in your vet.")
                        featureRow("applewatch", "Watch alerts",
                                   "Urgent signs reach your iPhone and Apple Watch.")
                        featureRow("leaf.fill", "Daily tips",
                                   "Species-specific care ideas, one day at a time.")
                    }
                }

                Text(VetDisclaimer.short)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()

                Button {
                    showingPetForm = true
                } label: {
                    Text("Add your pet")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(24)
        }
        .sheet(isPresented: $showingPetForm) {
            NavigationStack {
                PetEditorView(pet: nil)
            }
        }
        .onChange(of: store.pets.count) { _, newCount in
            if newCount > 0 {
                NotificationManager.requestAuthorization()
                store.handleAppActive()
            }
        }
    }

    private func featureRow(_ symbolName: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolName)
                .font(.body)
                .foregroundStyle(CalmPalette.sage)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(text)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
