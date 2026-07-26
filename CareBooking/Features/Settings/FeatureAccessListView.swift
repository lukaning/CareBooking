import SwiftUI

struct FeatureAccessListView: View {
    @Binding var permissions: [FeatureAccessKey: Bool]
    @Binding var nestedPermissions: [FeatureAccessKey: [NestedFeatureAccess]]
    @Binding var expandedKeys: Set<FeatureAccessKey>
    var isEditable: Bool = true

    private let rowColor = Color(red: 0.435, green: 0.463, blue: 0.494)

    var body: some View {
        VStack(spacing: 0) {
            ForEach(FeatureAccessKey.allCases) { key in
                permissionRow(key)

                if expandedKeys.contains(key), key.hasNestedItems {
                    ForEach(nestedPermissions[key] ?? []) { item in
                        nestedRow(parent: key, item: item)
                    }
                }
            }
        }
    }

    private func permissionRow(_ key: FeatureAccessKey) -> some View {
        HStack(spacing: 10) {
            Button {
                guard key.hasNestedItems else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expandedKeys.contains(key) {
                        expandedKeys.remove(key)
                    } else {
                        expandedKeys.insert(key)
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(rowColor)
                    .rotationEffect(.degrees(expandedKeys.contains(key) && key.hasNestedItems ? 90 : 0))
                    .frame(width: 16)
            }
            .buttonStyle(.plain)
            .disabled(!key.hasNestedItems)

            Text(key.title)
                .font(.subheadline)
                .foregroundStyle(Theme.darkText)
                .frame(maxWidth: .infinity, alignment: .leading)

            Toggle(
                "",
                isOn: Binding(
                    get: { permissions[key] ?? false },
                    set: { newValue in
                        guard isEditable else { return }
                        permissions[key] = newValue
                    }
                )
            )
            .labelsHidden()
            .tint(Color.teal)
            .disabled(!isEditable)
        }
        .padding(.vertical, 10)
    }

    private func nestedRow(parent: FeatureAccessKey, item: NestedFeatureAccess) -> some View {
        HStack(spacing: 10) {
            Color.clear.frame(width: 16)

            Text(item.title)
                .font(.footnote)
                .foregroundStyle(Theme.darkText)
                .frame(maxWidth: .infinity, alignment: .leading)

            Toggle(
                "",
                isOn: Binding(
                    get: {
                        nestedPermissions[parent]?.first(where: { $0.id == item.id })?.isEnabled ?? false
                    },
                    set: { newValue in
                        guard isEditable else { return }
                        guard var items = nestedPermissions[parent],
                              let index = items.firstIndex(where: { $0.id == item.id })
                        else { return }
                        items[index].isEnabled = newValue
                        nestedPermissions[parent] = items
                    }
                )
            )
            .labelsHidden()
            .tint(Color.teal)
            .disabled(!isEditable)
        }
        .padding(.vertical, 8)
        .padding(.leading, 12)
    }
}
