import SwiftUI

struct UsageRowView: View {
    let label: String
    let value: String
    let valueColor: Color?
    
    init(label: String, value: String, valueColor: Color? = nil) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(valueColor ?? .primary)
        }
    }
}

struct QuotaSectionView: View {
    let quota: QuotaInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(quota.type.displayName)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(Int(quota.percentage))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(quota.status.color))
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(quota.status.color))
                        .frame(width: max(0, geometry.size.width * min(quota.percentage / 100, 1)), height: 8)
                }
            }
            .frame(height: 8)
            
            // Subtitle and reset time
            HStack {
                Text(quota.type.cycleDescription)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let resetTime = quota.nextResetTime {
                    Text(timeUntilReset(resetTime))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            // MCP usage details if available
            if quota.type == .time, let details = quota.usageDetails, !details.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(details, id: \.modelCode) { detail in
                        HStack {
                            Text("  • \(detail.modelCode)")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(detail.usage)")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func timeUntilReset(_ date: Date) -> String {
        let interval = date.timeIntervalSince(Date())
        guard interval > 0 else { return "Resetting..." }
        
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "Resets in \(hours)h \(minutes)m"
        } else {
            return "Resets in \(minutes)m"
        }
    }
}

struct UsageSectionView: View {
    let title: String
    let icon: String
    let content: () -> TupleView<(Text, Text)>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
            
            content()
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 16) {
        QuotaSectionView(quota: QuotaInfo(from: QuotaLimitItem(
            type: "TOKENS_LIMIT",
            percentage: 45.5,
            currentValue: nil,
            total: nil,
            usageDetails: nil,
            nextResetTime: Int64(Date().addingTimeInterval(7200).timeIntervalSince1970 * 1000)
        )))
        
        QuotaSectionView(quota: QuotaInfo(from: QuotaLimitItem(
            type: "TIME_LIMIT",
            percentage: 82.0,
            currentValue: 820,
            total: 1000,
            usageDetails: [
                UsageDetail(modelCode: "web_search", usage: 450),
                UsageDetail(modelCode: "web_reader", usage: 370)
            ],
            nextResetTime: nil
        )))
        
        UsageRowView(label: "Total Tokens", value: "12,500,000")
        UsageRowView(label: "Total Calls", value: "1,234")
    }
    .padding()
    .frame(width: 280)
}
