import SwiftUI

/// Settings: theme picker, profile summary, data-source status & remote feed
/// configuration, scan-data management and the about/disclaimer block.
struct SettingsView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var model: AppModel

    @State private var remoteURL: String = UserDefaults.standard.string(forKey: DataHub.remoteURLKey) ?? ""
    @State private var confirmReset = false
    @State private var confirmDeleteScans = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    appearanceSection
                    profileSection
                    dataSourcesSection
                    scanDataSection
                    aboutSection
                }
                .padding(20)
            }
            .themedScreen()
            .navigationTitle("Settings")
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Appearance", subtitle: "Three looks, all first-class")
            VStack(spacing: 10) {
                ForEach(AppTheme.allCases) { appTheme in
                    Button {
                        withAnimation(.easeInOut) { theme.theme = appTheme }
                    } label: {
                        HStack(spacing: 14) {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(LinearGradient(
                                    colors: appTheme.palette.heroGradient,
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                                .frame(width: 52, height: 40)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(appTheme.palette.accent, lineWidth: 2)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(appTheme.displayName)
                                    .font(.headline)
                                    .foregroundStyle(theme.palette.textPrimary)
                                Text(appTheme.tagline)
                                    .font(.caption)
                                    .foregroundStyle(theme.palette.textSecondary)
                            }
                            Spacer()
                            Image(systemName: theme.theme == appTheme ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(theme.theme == appTheme ? theme.palette.accent : theme.palette.textSecondary)
                        }
                        .card()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Profile

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Your profile")
            if let profile = model.profile {
                VStack(spacing: 6) {
                    profileRow("Name", profile.displayName)
                    profileRow("Age", profile.ageRange.rawValue)
                    profileRow("Hair", "\(profile.hairType.label) · \(profile.hairLength.label)")
                    profileRow("Scalp", profile.scalp.label)
                    profileRow(
                        "Concerns",
                        profile.concerns.isEmpty
                            ? "None"
                            : profile.concerns.map(\.label).sorted().joined(separator: ", ")
                    )
                    profileRow("Goal", profile.goal.label)
                }
                .card()

                Button {
                    confirmReset = true
                } label: {
                    Label("Retake onboarding", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(SecondaryButtonStyle(palette: theme.palette))
                .confirmationDialog(
                    "Retake onboarding? Your current routine and progress checkmarks will be replaced. Scans are kept.",
                    isPresented: $confirmReset,
                    titleVisibility: .visible
                ) {
                    Button("Retake onboarding", role: .destructive) { model.resetProfile() }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
    }

    private func profileRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(theme.palette.textSecondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(theme.palette.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 3)
    }

    // MARK: - Data sources

    private var dataSourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Data sources", subtitle: "The catalog is aggregated from every source below")
            VStack(spacing: 8) {
                ForEach(model.sources) { source in
                    HStack(spacing: 12) {
                        Image(systemName: source.kind == "Remote" ? "antenna.radiowaves.left.and.right" : "internaldrive")
                            .foregroundStyle(theme.palette.accent)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(source.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.palette.textPrimary)
                            Text(source.state)
                                .font(.caption)
                                .foregroundStyle(theme.palette.textSecondary)
                        }
                        Spacer()
                        if source.itemCount > 0 {
                            Text("\(source.itemCount)")
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(theme.palette.surfaceSecondary)
                                .foregroundStyle(theme.palette.textSecondary)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .card()

            VStack(alignment: .leading, spacing: 10) {
                Text("Community feed URL")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.palette.textPrimary)
                Text("Point MANE at any URL serving catalog JSON (see ios/sample-remote-catalog.json in the repo). Remote products override bundled ones by id.")
                    .font(.caption)
                    .foregroundStyle(theme.palette.textSecondary)
                TextField("https://example.com/catalog.json", text: $remoteURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(theme.palette.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(theme.palette.textPrimary)
                Button {
                    UserDefaults.standard.set(
                        remoteURL.trimmingCharacters(in: .whitespacesAndNewlines),
                        forKey: DataHub.remoteURLKey
                    )
                    Task { await model.refreshData() }
                } label: {
                    if model.isLoadingData {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Label("Save & refresh sources", systemImage: "arrow.clockwise")
                    }
                }
                .buttonStyle(SecondaryButtonStyle(palette: theme.palette))
                .disabled(model.isLoadingData)
            }
            .card()
        }
    }

    // MARK: - Scan data

    private var scanDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Scan data", subtitle: "\(model.sessions.count) saved scan\(model.sessions.count == 1 ? "" : "s") — stored only on this device")
            if !model.sessions.isEmpty {
                Button(role: .destructive) {
                    confirmDeleteScans = true
                } label: {
                    Label("Delete all scan data", systemImage: "trash")
                        .font(.headline)
                        .foregroundStyle(theme.palette.negative)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(theme.palette.negative.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .confirmationDialog(
                    "Delete all \(model.sessions.count) scans and their photos? This cannot be undone.",
                    isPresented: $confirmDeleteScans,
                    titleVisibility: .visible
                ) {
                    Button("Delete everything", role: .destructive) { model.deleteAllSessions() }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "About")
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("MANE")
                        .font(.system(.headline, design: .rounded).weight(.black))
                        .tracking(2)
                        .foregroundStyle(theme.palette.textPrimary)
                    Spacer()
                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                        .font(.caption)
                        .foregroundStyle(theme.palette.textSecondary)
                }
                Text("Engineered hair care for men. Routine, products and hairline tracking — all personalized, all private.")
                    .font(.subheadline)
                    .foregroundStyle(theme.palette.textSecondary)
                Divider()
                DisclaimerFooter()
            }
            .card()
        }
    }
}
