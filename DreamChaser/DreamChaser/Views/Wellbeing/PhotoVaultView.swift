import PhotosUI
import SwiftData
import SwiftUI
import UIKit

/// Private, on-device progress photos with side-by-side comparison.
struct PhotoVaultView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ProgressPhoto.createdAt, order: .reverse) private var photos: [ProgressPhoto]

    @State private var pickerItem: PhotosPickerItem?
    @State private var compareSelection: [ProgressPhoto] = []
    @State private var showingCompare = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Photos never leave this device. Tap two to compare then vs. now.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if photos.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                            .foregroundStyle(.pink)
                        Text("Progress you can see")
                            .font(.headline)
                        Text("Add a photo every few weeks — future you will want the receipts.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .glassCard()
                    .padding(.top, 24)
                } else {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(photos) { photo in
                            photoCell(photo)
                        }
                    }
                }

                if compareSelection.count == 2 {
                    Button {
                        showingCompare = true
                    } label: {
                        Label("Compare side by side", systemImage: "square.split.2x1")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.glassProminent)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .background(AppBackground())
        .navigationTitle("Progress Vault")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Image(systemName: "plus")
                }
            }
        }
        .onChange(of: pickerItem) {
            importPickedPhoto()
        }
        .sheet(isPresented: $showingCompare) {
            PhotoCompareView(photos: compareSelection)
        }
    }

    private func photoCell(_ photo: ProgressPhoto) -> some View {
        let isSelected = compareSelection.contains { $0.id == photo.id }
        return Button {
            toggleSelection(photo)
        } label: {
            ZStack(alignment: .bottomLeading) {
                if let uiImage = UIImage(data: photo.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 110)
                        .clipShape(.rect(cornerRadius: 14))
                }
                Text(photo.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.black.opacity(0.5), in: .capsule)
                    .foregroundStyle(.white)
                    .padding(6)
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.pink, lineWidth: 3)
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Delete photo", systemImage: "trash", role: .destructive) {
                compareSelection.removeAll { $0.id == photo.id }
                context.delete(photo)
                try? context.save()
            }
        }
    }

    private func toggleSelection(_ photo: ProgressPhoto) {
        if let index = compareSelection.firstIndex(where: { $0.id == photo.id }) {
            compareSelection.remove(at: index)
        } else {
            compareSelection.append(photo)
            if compareSelection.count > 2 {
                compareSelection.removeFirst()
            }
        }
    }

    private func importPickedPhoto() {
        guard let pickerItem else { return }
        Task {
            if let data = try? await pickerItem.loadTransferable(type: Data.self) {
                context.insert(ProgressPhoto(imageData: data))
                try? context.save()
            }
            self.pickerItem = nil
        }
    }
}

struct PhotoCompareView: View {
    @Environment(\.dismiss) private var dismiss
    let photos: [ProgressPhoto]

    /// Oldest on the left.
    private var ordered: [ProgressPhoto] {
        photos.sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 10) {
                ForEach(ordered) { photo in
                    VStack(spacing: 8) {
                        if let uiImage = UIImage(data: photo.imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .clipShape(.rect(cornerRadius: 16))
                        }
                        Text(photo.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppBackground())
            .navigationTitle("Then vs. Now")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
