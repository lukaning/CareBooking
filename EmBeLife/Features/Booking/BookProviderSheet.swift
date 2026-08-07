import SwiftUI

/// Multi-step booking: schedule → who → payment → summary → requested booking.
struct BookProviderSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let provider: Provider
    var appointmentType: BookingAppointmentType = .inPerson

    enum Step: Int, CaseIterable {
        case schedule
        case who
        case payment
        case summary
    }

    enum ScheduleField: Hashable {
        case date, start, duration
    }

    @State private var step: Step = .schedule
    @State private var selectedField: ScheduleField = .duration

    @State private var selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
    @State private var startTime = Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: .now) ?? .now
    @State private var durationMinutes = 30

    @State private var selectedMemberIDs: Set<UUID> = []
    @State private var expandedMemberID: UUID?
    @State private var isAddingMember = false
    @State private var newMemberFirst = ""
    @State private var newMemberLast = ""
    @State private var draftMembers: [FamilyMember] = []

    @State private var selectedPayment: PaymentMethodKind = .creditCard
    @State private var bankDetails = BankAccountDetails.sample
    @State private var zelleDetails = ContactPaymentDetails.zelleSample
    @State private var venmoDetails = ContactPaymentDetails.venmoSample
    @State private var paypalDetails = ContactPaymentDetails.paypalSample
    @State private var creditCardDetails = CreditCardDetails.sample
    @State private var paymentConfirmed = false

    @State private var submittedBookingID: UUID?

    private let durations = [15, 30, 45, 60, 75, 90, 120]
    private let giftBalance = 240
    private let linkBlue = Theme.linkBlue
    private let softBorder = Color(red: 0.90, green: 0.91, blue: 0.93)
    private let selectedFill = Color(red: 1.0, green: 0.847, blue: 0.796)
    private let radioRing = Color(red: 0.70, green: 0.72, blue: 0.76)
    private let fieldLabel = Color(red: 0.10, green: 0.20, blue: 0.45)

    private var availableMembers: [FamilyMember] {
        let profileMembers = appModel.profile.familyMembers
        if !draftMembers.isEmpty {
            return draftMembers
        }
        if !profileMembers.isEmpty {
            return profileMembers
        }
        return FamilyMember.samples
    }

    private var selectedMembers: [FamilyMember] {
        availableMembers.filter { selectedMemberIDs.contains($0.id) }
    }

    private var recipientLabel: String {
        let names = selectedMembers.map(\.displayName)
        if names.isEmpty { return "—" }
        return names.joined(separator: ", ")
    }

    private var estimatedTotal: Int {
        let hours = max(Double(durationMinutes) / 60.0, 0.25)
        return Int((Double(provider.ratePerHour) * hours).rounded())
    }

    private var paymentMethodLabel: String {
        switch selectedPayment {
        case .bankAccount:
            return "Bank account"
        case .zelle:
            return "Zelle"
        case .venmo:
            return "Venmo"
        case .paypal:
            return "PayPal"
        case .giftFund:
            return "Gift Fund"
        case .creditCard:
            let last = creditCardDetails.cardNumber.filter(\.isNumber).suffix(4)
            return last.isEmpty ? "Credit card" : "Credit card · \(String(last))"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                Group {
                    switch step {
                    case .schedule:
                        scheduleStep
                    case .who:
                        whoStep
                    case .payment:
                        paymentStep
                    case .summary:
                        summaryStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.darkText)
                            .frame(width: 32, height: 32)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Close")
                }
            }
            .onAppear {
                seedMembersIfNeeded()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Theme.brandOrange)
                .frame(width: 4, height: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(step == .payment ? "Set up payment" : "Book a Provider")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.darkText)
                if step != .payment && step != .summary {
                    Text(provider.name)
                        .font(.subheadline)
                        .foregroundStyle(Theme.mutedText)
                }
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Step 1: Schedule

    private var scheduleStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose a day and time you want to schedule")
                .font(.subheadline)
                .foregroundStyle(Theme.mutedText)
                .padding(.horizontal, 20)

            VStack(spacing: 12) {
                dateField
                HStack(spacing: 12) {
                    startTimeField
                    durationField
                }
            }
            .padding(.horizontal, 20)

            Group {
                switch selectedField {
                case .date:
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(linkBlue)
                    .padding(.horizontal, 12)
                case .start:
                    DatePicker(
                        "Start Time",
                        selection: $startTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                case .duration:
                    durationList
                }
            }
            .frame(maxHeight: 320)

            Spacer(minLength: 0)

            Button("Next Step") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    step = .who
                }
            }
            .buttonStyle(PrimaryOrangeButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private var durationList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("\(durationMinutes) min")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    durationMinutes = 30
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(linkBlue)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(durations, id: \.self) { minutes in
                        Button {
                            durationMinutes = minutes
                        } label: {
                            Text("\(minutes) min")
                                .font(.body.weight(durationMinutes == minutes ? .semibold : .regular))
                                .foregroundStyle(Theme.darkText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background {
                                    if durationMinutes == minutes {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color(red: 0.94, green: 0.95, blue: 0.96))
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
            }
        }
    }

    private var dateField: some View {
        selectionCard(isActive: selectedField == .date) {
            selectedField = .date
        } content: {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date")
                        .font(.caption)
                        .foregroundStyle(Theme.mutedText)
                    Text(selectedDate, format: .dateTime.month(.wide).day().year())
                        .font(.headline)
                        .foregroundStyle(Theme.darkText)
                }
            } icon: {
                Image(systemName: "calendar")
                    .foregroundStyle(linkBlue)
            }
        }
    }

    private var startTimeField: some View {
        selectionCard(isActive: selectedField == .start) {
            selectedField = .start
        } content: {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Time")
                        .font(.caption)
                        .foregroundStyle(Theme.mutedText)
                    Text(startTime, format: .dateTime.hour().minute())
                        .font(.headline)
                        .foregroundStyle(Theme.darkText)
                }
            } icon: {
                Image(systemName: "clock")
                    .foregroundStyle(Theme.grayscale70)
            }
        }
    }

    private var durationField: some View {
        selectionCard(isActive: selectedField == .duration) {
            selectedField = .duration
        } content: {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundStyle(Theme.mutedText)
                    Text("\(durationMinutes) min")
                        .font(.headline)
                        .foregroundStyle(Theme.darkText)
                }
            } icon: {
                Image(systemName: "clock")
                    .foregroundStyle(Theme.grayscale70)
            }
        }
    }

    // MARK: - Step 2: Who

    private var whoStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Who will you book for")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color(red: 0.18, green: 0.22, blue: 0.32))

                    Text("Member List")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.mutedText)

                    VStack(spacing: 12) {
                        ForEach(availableMembers) { member in
                            memberRow(member)
                        }
                    }

                    if isAddingMember {
                        addMemberForm
                    } else {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isAddingMember = true
                            }
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .stroke(softBorder, lineWidth: 1.5)
                                        .frame(width: 36, height: 36)
                                    Text("+")
                                        .font(.title3)
                                        .foregroundStyle(Theme.mutedText)
                                }
                                Text("Adding member")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.darkText)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }

            Button("Continue") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if selectedMemberIDs.isEmpty {
                        isAddingMember = true
                    } else {
                        step = .payment
                    }
                }
            }
            .buttonStyle(PrimaryOrangeButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .opacity(selectedMemberIDs.isEmpty ? 0.55 : 1)
        }
    }

    private func memberRow(_ member: FamilyMember) -> some View {
        let selected = selectedMemberIDs.contains(member.id)
        let expanded = expandedMemberID == member.id

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if selected {
                            selectedMemberIDs.remove(member.id)
                        } else {
                            selectedMemberIDs.insert(member.id)
                        }
                    }
                } label: {
                    Image(systemName: selected ? "checkmark.square.fill" : "square")
                        .font(.title3)
                        .foregroundStyle(selected ? Color(red: 0.20, green: 0.70, blue: 0.40) : linkBlue.opacity(0.55))
                }
                .buttonStyle(.plain)

                Circle()
                    .fill(member.avatarStyle.color)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(member.monogram)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedMemberID = expanded ? nil : member.id
                        if !selected {
                            selectedMemberIDs.insert(member.id)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(member.displayName)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.darkText)
                        Image(systemName: expanded ? "chevron.down" : "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.mutedText)
                    }
                }
                .buttonStyle(.plain)

                Spacer()
            }

            if expanded {
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Preferred Service")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.mutedText)
                        ForEach(member.preferredServices, id: \.self) { service in
                            Text(service)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Theme.darkText)
                        }
                        if member.preferredServices.isEmpty {
                            Text("—")
                                .font(.subheadline)
                                .foregroundStyle(Theme.mutedText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Rectangle()
                        .fill(softBorder)
                        .frame(width: 1)
                        .padding(.horizontal, 10)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Preferred time")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.mutedText)
                        ForEach(member.preferredTimes, id: \.self) { time in
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                    .foregroundStyle(Theme.mutedText)
                                Text(time)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Theme.darkText)
                            }
                        }
                        if member.preferredTimes.isEmpty {
                            Text("—")
                                .font(.subheadline)
                                .foregroundStyle(Theme.mutedText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
            }
        }
    }

    private var addMemberForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add family or friend")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.darkText)

            HStack(spacing: 10) {
                TextField("First name", text: $newMemberFirst)
                    .textFieldStyle(.roundedBorder)
                TextField("Last name", text: $newMemberLast)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Button("Cancel") {
                    withAnimation {
                        isAddingMember = false
                        newMemberFirst = ""
                        newMemberLast = ""
                    }
                }
                .foregroundStyle(Theme.mutedText)

                Spacer()

                Button("Add") {
                    addMemberFromForm()
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(canAddMember ? Theme.brandOrange : Theme.grayscale60)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .disabled(!canAddMember)
            }
        }
        .padding(14)
        .background(Color(red: 0.97, green: 0.975, blue: 0.985))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var canAddMember: Bool {
        !newMemberFirst.trimmingCharacters(in: .whitespaces).isEmpty
            && !newMemberLast.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Step 3: Payment

    private var paymentStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Payment Method")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.darkText)

                    ForEach(PaymentMethodKind.allCases) { method in
                        paymentMethodCard(method)
                    }
                }
                .padding(20)
            }

            Button {
                confirmPaymentAndSummarize()
            } label: {
                Text("Request Booking")
            }
            .buttonStyle(PrimaryOrangeButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .disabled(!paymentReady)
            .opacity(paymentReady ? 1 : 0.55)
        }
    }

    private var paymentReady: Bool {
        switch selectedPayment {
        case .bankAccount:
            return !bankDetails.accountHolderName.isEmpty
                && !bankDetails.accountNumber.isEmpty
                && !bankDetails.abaRoutingNumber.isEmpty
        case .zelle:
            return !zelleDetails.contact.isEmpty
        case .venmo:
            return !venmoDetails.contact.isEmpty
        case .paypal:
            return !paypalDetails.contact.isEmpty
        case .giftFund:
            return giftBalance > 0
        case .creditCard:
            return !creditCardDetails.cardNumber.isEmpty
                && !creditCardDetails.expiry.isEmpty
                && !creditCardDetails.cvc.isEmpty
        }
    }

    private func paymentMethodCard(_ method: PaymentMethodKind) -> some View {
        let isSelected = selectedPayment == method
        return VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedPayment = method
                    paymentConfirmed = false
                }
            } label: {
                HStack(spacing: 12) {
                    paymentRadio(isSelected: isSelected)
                    Text(method.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(isSelected ? linkBlue : Theme.darkText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    trailingPaymentAccessory(method)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isSelected {
                paymentFields(for: method)
            }
        }
        .padding(14)
        .background(isSelected ? selectedFill : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? Theme.brandOrange : softBorder, lineWidth: isSelected ? 1.5 : 1)
        )
    }

    @ViewBuilder
    private func paymentFields(for method: PaymentMethodKind) -> some View {
        switch method {
        case .bankAccount:
            payField("Account Holder Name", text: $bankDetails.accountHolderName)
            payField("Account Number", text: $bankDetails.accountNumber)
            payField("ABA Routing Number", text: $bankDetails.abaRoutingNumber)
        case .zelle:
            payField("Email or Mobile phone number", text: $zelleDetails.contact)
        case .venmo:
            payField("Venmo username or phone", text: $venmoDetails.contact)
        case .paypal:
            payField("PayPal email", text: $paypalDetails.contact)
        case .giftFund:
            Text("$\(giftBalance)")
                .font(.system(size: 32, weight: .bold))
                .frame(maxWidth: .infinity)
            Text("Available gift fund balance")
                .font(.subheadline)
                .foregroundStyle(Theme.mutedText)
                .frame(maxWidth: .infinity)
        case .creditCard:
            payField("Cardholder Name", text: $creditCardDetails.cardholderName)
            payField("Card Number", text: $creditCardDetails.cardNumber)
            HStack(spacing: 10) {
                payField("Expiry", text: $creditCardDetails.expiry)
                payField("CVC", text: $creditCardDetails.cvc)
            }
        }
    }

    private func payField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(fieldLabel)
            TextField(title, text: text)
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(softBorder, lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private func trailingPaymentAccessory(_ method: PaymentMethodKind) -> some View {
        switch method {
        case .giftFund:
            Text("$\(giftBalance)")
                .font(.body.weight(.semibold))
                .foregroundStyle(linkBlue)
        case .zelle, .venmo, .paypal, .creditCard:
            HStack(spacing: 6) {
                ForEach(method.logoAssetNames, id: \.self) { name in
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .frame(height: name == "payVisa" ? 14 : 18)
                        .frame(maxWidth: 40)
                }
            }
        case .bankAccount:
            EmptyView()
        }
    }

    private func paymentRadio(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .strokeBorder(isSelected ? Theme.brandOrange : radioRing, lineWidth: 1.5)
                .frame(width: 22, height: 22)
            Circle()
                .fill(Theme.brandOrange)
                .frame(width: 12, height: 12)
                .scaleEffect(isSelected ? 1 : 0.001)
                .opacity(isSelected ? 1 : 0)
        }
    }

    // MARK: - Step 4: Summary

    private var summaryStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Booking details")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.darkText)

                    summaryRow(label: "Booking Dates", value: bookingDateLabel)
                    summaryRow(label: "To who", value: recipientLabel)

                    labeledIconRow(icon: "calendar", title: "Service Date", value: serviceDateLabel)
                    labeledIconRow(
                        icon: "clock",
                        title: "Time",
                        value: "\(startTimeLabel)\n\(durationMinutes) min"
                    )
                    labeledIconRow(icon: "face.smiling", title: "Provider", value: provider.name)
                    labeledIconRow(icon: "receipt", title: "Total", value: "$\(estimatedTotal)")
                    labeledIconRow(icon: "creditcard", title: "Payment method", value: paymentMethodLabel)

                    VStack(spacing: 12) {
                        Image(systemName: "tray.and.arrow.up.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.brandOrange)
                            .padding(.top, 12)

                        Text("Booking Requested!")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Theme.darkText)

                        Text("Your booking has been requested and waiting for confirmation from your provider.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.mutedText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .padding(20)
            }

            Button("Done") {
                dismiss()
            }
            .buttonStyle(PrimaryOrangeButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.mutedText)
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.darkText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(red: 0.97, green: 0.975, blue: 0.985))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func labeledIconRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Theme.brandOrange)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
                Text(value)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.darkText)
            }
            Spacer()
        }
    }

    // MARK: - Shared

    private func selectionCard<Content: View>(
        isActive: Bool,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Button(action: action) {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isActive ? linkBlue : Color(.separator), lineWidth: isActive ? 2 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var bookingDateLabel: String {
        selectedDate.formatted(.dateTime.month(.wide).day().year())
    }

    private var serviceDateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "d MMM, yyyy"
        return f.string(from: selectedDate)
    }

    private var startTimeLabel: String {
        startTime.formatted(date: .omitted, time: .shortened)
    }

    private func seedMembersIfNeeded() {
        if draftMembers.isEmpty {
            draftMembers = appModel.profile.familyMembers.isEmpty
                ? FamilyMember.samples
                : appModel.profile.familyMembers
        }
        if selectedMemberIDs.isEmpty, let first = draftMembers.first {
            selectedMemberIDs = [first.id]
            expandedMemberID = first.id
        }
    }

    private func addMemberFromForm() {
        let member = FamilyMember(
            firstName: newMemberFirst.trimmingCharacters(in: .whitespaces),
            lastName: newMemberLast.trimmingCharacters(in: .whitespaces),
            preferredServices: ["Personal care/ hygiene"],
            preferredTimes: ["8am – 10am"],
            avatarStyle: .next(after: draftMembers.count)
        )
        withAnimation(.easeInOut(duration: 0.2)) {
            draftMembers.append(member)
            selectedMemberIDs.insert(member.id)
            expandedMemberID = member.id
            isAddingMember = false
            newMemberFirst = ""
            newMemberLast = ""
            // Persist lightly onto profile so Profile also shows them after publish...
            var profile = appModel.profile
            profile.familyMembers = draftMembers
            appModel.profile = profile
        }
    }

    private func confirmPaymentAndSummarize() {
        paymentConfirmed = true
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let combinedStart = calendar.date(
            bySettingHour: timeComponents.hour ?? 12,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: day
        ) ?? startTime

        let booking = Booking(
            provider: provider,
            date: selectedDate,
            startTime: combinedStart,
            durationMinutes: durationMinutes,
            status: .requested,
            serviceProvidedTo: recipientLabel,
            title: "\(provider.title) with \(provider.name)",
            taskDescription: "\(appointmentType.title) · \(durationMinutes) min · $\(estimatedTotal) · \(paymentMethodLabel)",
            location: appModel.profile.address.isEmpty ? "Service location TBD" : appModel.profile.address
        )
        appModel.addBooking(booking)
        submittedBookingID = booking.id
        withAnimation(.easeInOut(duration: 0.2)) {
            step = .summary
        }
    }
}
