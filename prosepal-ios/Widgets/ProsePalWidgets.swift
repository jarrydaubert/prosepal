import AppIntents
import ProsePalDomain
import SwiftUI
import WidgetKit

private enum ProsePalWidgetConstants {
    // Widget kind and moment URLs both derive from the shared handoff
    // environment, so staging routing lives in one place (ProsePalDomain).
    private static let environment = MomentHandoffEnvironment.current

    static var careGlanceKind: String {
        "\(widgetKindPrefix).care-glance"
    }

    static var startMomentControlKind: String {
        "\(widgetKindPrefix).start-moment-control"
    }

    static var widgetMomentURL: URL {
        MomentDeepLink.momentURL(source: MomentLaunchSource.widget, environment: environment)!
    }

    static var controlMomentURL: URL {
        MomentDeepLink.momentURL(source: MomentLaunchSource.controlCenter, environment: environment)!
    }

    private static var widgetKindPrefix: String {
        environment == .staging
            ? "com.prosepal.prosepal.staging.widgets"
            : "com.prosepal.prosepal.widgets"
    }
}

struct CareGlanceEntry: TimelineEntry {
    let date: Date
}

struct CareGlanceProvider: TimelineProvider {
    func placeholder(in context: Context) -> CareGlanceEntry {
        CareGlanceEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (CareGlanceEntry) -> Void) {
        completion(CareGlanceEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CareGlanceEntry>) -> Void) {
        let entry = CareGlanceEntry(date: Date())
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 60))))
    }
}

struct CareGlanceWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: ProsePalWidgetConstants.careGlanceKind,
            provider: CareGlanceProvider()
        ) { entry in
            CareGlanceWidgetView(entry: entry)
        }
        .configurationDisplayName("Care Glance")
        .description("Start a thoughtful Moment from your Home Screen.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

struct CareGlanceWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CareGlanceEntry

    var body: some View {
        Link(destination: ProsePalWidgetConstants.widgetMomentURL) {
            switch family {
            case .accessoryCircular:
                VStack(spacing: 3) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.title3)
                    Text("Moment")
                        .font(.caption2.weight(.semibold))
                }
            case .accessoryRectangular:
                HStack(spacing: 8) {
                    Image(systemName: "heart.text.square.fill")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Care Glance")
                            .font(.headline)
                        Text("Start a Moment")
                            .font(.caption)
                    }
                }
            default:
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.title2)
                    Spacer(minLength: 0)
                    Text("Care Glance")
                        .font(.headline)
                    Text("Start a thoughtful Moment.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(ProsePalWidgetConstants.widgetMomentURL)
        .accessibilityLabel("Start a ProsePal Moment")
    }
}

struct StartMomentControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: ProsePalWidgetConstants.startMomentControlKind) {
            ControlWidgetButton(action: OpenURLIntent(ProsePalWidgetConstants.controlMomentURL)) {
                Label("Start Moment", systemImage: "square.and.pencil")
            }
        }
        .displayName("Start Moment")
        .description("Open ProsePal ready to write for someone.")
    }
}

@main
struct ProsePalWidgetsBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        CareGlanceWidget()
        StartMomentControlWidget()
    }
}
