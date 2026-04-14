import SwiftUI
import CoreLocation

// MARK: - Report Submission Sheet
/// Full report submission flow with category selection, description, and WebSocket broadcast
struct ReportSubmissionSheet: View {
    @ObservedObject var viewModel: AlertViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var locationService: LocationService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: ReportCategory?
    @State private var reportDescription: String = ""
    @State private var showConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        // Category Selection
                        categorySelectionSection

                        // Description
                        if selectedCategory != nil {
                            descriptionSection
                        }

                        // Submit Button
                        if selectedCategory != nil {
                            submitButton
                        }

                        // Submission Status
                        submissionStatusView
                    }
                    .padding(DesignTokens.Spacing.md)
                }
            }
            .navigationTitle("Report Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }
            .toolbarBackground(themeManager.surfaceColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                if let preselected = viewModel.selectedCategory {
                    selectedCategory = preselected
                }
            }
        }
    }

    // MARK: - Category Selection
    private var categorySelectionSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("What did you see?")
                .font(Typography.headline(.h5))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: DesignTokens.Spacing.sm) {
                ForEach(ReportCategory.allCases, id: \.rawValue) { category in
                    CategorySelectionCard(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }

    // MARK: - Description
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Add Details (Optional)")
                .font(Typography.headline(.h5))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            TextEditor(text: $reportDescription)
                .frame(minHeight: 80)
                .padding(DesignTokens.Spacing.sm)
                .scrollContentBackground(.hidden)
                .background(DesignTokens.Colors.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                        .stroke(DesignTokens.Colors.textTertiary.opacity(0.3), lineWidth: 1)
                )

            // Location info
            if let location = locationService.currentLocation {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                    Text("Location: \(String(format: "%.4f", location.coordinate.latitude)), \(String(format: "%.4f", location.coordinate.longitude))")
                        .font(Typography.body(.xxs))
                }
                .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Submit Button
    private var submitButton: some View {
        Button {
            submitReport()
        } label: {
            HStack(spacing: DesignTokens.Spacing.sm) {
                if viewModel.isSubmittingReport {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                }
                Text(viewModel.isSubmittingReport ? "Submitting..." : "Submit Report")
                    .font(Typography.bodySemiBold(.md))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(
                selectedCategory != nil && !viewModel.isSubmittingReport
                    ? DesignTokens.Colors.primaryAccent
                    : DesignTokens.Colors.textTertiary
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
        }
        .disabled(selectedCategory == nil || viewModel.isSubmittingReport)
    }

    // MARK: - Submission Status
    @ViewBuilder
    private var submissionStatusView: some View {
        switch viewModel.reportSubmissionStatus {
        case .success:
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(DesignTokens.Colors.success)
                Text("Report submitted successfully!")
                    .font(Typography.bodySemiBold(.sm))
                    .foregroundStyle(DesignTokens.Colors.success)
            }
            .padding(DesignTokens.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(DesignTokens.Colors.success.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }

        case .failed(let error):
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(DesignTokens.Colors.danger)
                Text("Failed: \(error)")
                    .font(Typography.body(.sm))
                    .foregroundStyle(DesignTokens.Colors.danger)
            }
            .padding(DesignTokens.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(DesignTokens.Colors.danger.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))

        default:
            EmptyView()
        }
    }

    // MARK: - Submit
    private func submitReport() {
        guard let category = selectedCategory else { return }
        let coordinate = locationService.currentLocation?.coordinate
            ?? CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522) // Default: Paris

        viewModel.submitReport(
            category: category,
            description: reportDescription,
            coordinate: coordinate
        )
    }
}

// MARK: - Category Selection Card
struct CategorySelectionCard: View {
    let category: ReportCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: category.iconName)
                    .font(.system(size: 28))
                    .foregroundStyle(isSelected ? .white : severityColor)

                Text(category.rawValue)
                    .font(Typography.bodySemiBold(.xs))
                    .foregroundStyle(isSelected ? .white : DesignTokens.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(
                isSelected
                    ? severityColor
                    : DesignTokens.Colors.surfacePrimary
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                    .stroke(
                        isSelected ? severityColor : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var severityColor: Color {
        switch category.severity {
        case .low: return DesignTokens.Colors.info
        case .medium: return DesignTokens.Colors.warning
        case .high: return DesignTokens.Colors.secondaryAccent
        case .critical: return DesignTokens.Colors.danger
        }
    }
}
