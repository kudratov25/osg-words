import AppIntents
import SwiftUI
import WidgetKit

/// Must match `widgetGroupId` in lib/notifications/widget_sync.dart and
/// the App Group added to both this target's and Runner's entitlements.
private let appGroupId = "group.uz.kudratov.osg"

/// Must match `_dataKey` in lib/notifications/widget_sync.dart.
private let dataKey = "todays_words"

/// Widget-only key (the app never reads it): the `at` (epoch millis) of
/// the slot whose meaning was revealed with the "Show meaning" button.
/// Meaning is visible iff this equals the entry's own slot `at`, so the
/// next slot's word automatically starts hidden again.
private let revealedAtKey = "widget_revealed_at"

/// Mirrors AppColors in lib/theme/glass_theme.dart, so the widget reads as
/// the same surface as the app's WordCard rather than a reskinned system
/// widget. Only actually visible on the .systemSmall family below - Lock
/// Screen accessory families (accessoryRectangular/accessoryInline) are
/// forced by the OS into its own monochrome/vibrant rendering regardless
/// of any colors supplied here, which is why they're left uncolored.
private enum AppColors {
    static let background = Color(red: 0x0B / 255, green: 0x0E / 255, blue: 0x14 / 255)
    static let accent = Color(red: 0x7F / 255, green: 0xB3 / 255, blue: 0xFF / 255)
    static let textPrimary = Color(red: 0xF2 / 255, green: 0xF4 / 255, blue: 0xF8 / 255)
    static let textSecondary = Color(red: 0xA3 / 255, green: 0xAD / 255, blue: 0xC2 / 255)
    static let glassBorder = Color.white.opacity(0.20)
    static let glassFillTop = Color.white.opacity(0.10)
    static let glassFillBottom = Color.white.opacity(0.08)
    // AppBackground's three soft color blobs (glass_theme.dart).
    static let blobBlue = Color(red: 0x3D / 255, green: 0x6B / 255, blue: 0xE0 / 255)
    static let blobPurple = Color(red: 0x9A / 255, green: 0x5C / 255, blue: 0xFF / 255)
    static let blobTeal = Color(red: 0x2F / 255, green: 0xB8 / 255, blue: 0xA6 / 255)
}

// MARK: - Entry

struct WordEntry: TimelineEntry {
    let date: Date
    let german: String
    let article: String?
    let translation: String
    let example: String
    let hasData: Bool
    /// The slot's `at` (epoch millis) - identifies the slot for reveal state.
    var slotAt: Int = 0
    /// Whether translation/example are shown. Only consulted on iOS 17+
    /// (interactive widgets); iOS 16 always shows the meaning.
    var meaningRevealed: Bool = true

    var wordTitle: String {
        guard let article, !article.isEmpty else { return german }
        return "\(article) \(german)"
    }

    /// v2 payload titles already carry the flag, so the placeholder does too.
    static let placeholder = WordEntry(
        date: Date(), german: "🇩🇪 der Schlüssel", article: nil,
        translation: "key", example: "Wo ist mein Schlüssel?", hasData: true
    )

    static let empty = WordEntry(
        date: Date(), german: "", article: nil,
        translation: "", example: "", hasData: false
    )
}

// MARK: - Provider

/// Reads the week of word slots written by widget_sync.dart (each with the
/// exact time its notification fires) and turns them into timeline
/// entries. WidgetKit switches between them at those times by itself, so
/// the widget stays in step with the notifications all week without the
/// app being opened. Mirrors OsgWidgetProvider.kt on Android.
struct Provider: TimelineProvider {
    /// Payload v2: {"slots": [{"at": epochMillis, "title", "translation", "example"}]}
    private struct SlotV2: Decodable {
        let at: Double
        let title: String
        let translation: String
        let example: String
    }

    /// Payload v1 (older app versions, today only): {"words": [{"slotMinutes", ...}]}
    private struct SlotV1: Decodable {
        let slotMinutes: Int
        let german: String
        let article: String?
        let translation: String
        let example: String
    }

    private struct Payload: Decodable {
        let slots: [SlotV2]?
        let words: [SlotV1]?
    }

    /// After the plan's last slot, show "open the app" once this much
    /// time has passed (the app wasn't opened for the whole week).
    private let staleAfter: TimeInterval = 24 * 60 * 60

    func placeholder(in context: Context) -> WordEntry { .placeholder }

    /// Snapshots (widget gallery, transient previews) always show the
    /// meaning, as does the placeholder - entries default to revealed.
    func getSnapshot(in context: Context, completion: @escaping (WordEntry) -> Void) {
        completion(current(in: loadEntries(), at: Date()) ?? .placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WordEntry>) -> Void) {
        let now = Date()
        let all = loadEntries()
        guard let currentEntry = current(in: all, at: now) else {
            completion(Timeline(entries: [.empty], policy: .never))
            return
        }
        // The entry showing right now (dated now), then every later slot.
        var entries = [WordEntry(
            date: now, german: currentEntry.german, article: currentEntry.article,
            translation: currentEntry.translation, example: currentEntry.example, hasData: true,
            slotAt: currentEntry.slotAt
        )]
        entries += all.filter { $0.date > now }
        // Meaning starts hidden; only the slot last revealed via
        // RevealMeaningIntent shows it. WidgetKit reloads this timeline
        // after the intent runs, which is what makes the tap take effect.
        let revealedAt = UserDefaults(suiteName: appGroupId)?.object(forKey: revealedAtKey) as? Int
        entries = entries.map { entry in
            var entry = entry
            entry.meaningRevealed = entry.slotAt == revealedAt
            return entry
        }
        if let last = all.last {
            // After the plan runs out, show "open the app" a day later.
            entries.append(WordEntry(
                date: last.date.addingTimeInterval(staleAfter), german: "", article: nil,
                translation: "", example: "", hasData: false
            ))
        }
        // The app reloads the timeline itself whenever it writes new data.
        completion(Timeline(entries: entries, policy: .never))
    }

    /// Latest slot whose time has passed; before the first slot, the first.
    private func current(in entries: [WordEntry], at now: Date) -> WordEntry? {
        guard let first = entries.first else { return nil }
        guard let passed = entries.last(where: { $0.date <= now }) else { return first }
        if passed.date == entries.last?.date && now.timeIntervalSince(passed.date) > staleAfter {
            return nil
        }
        return passed
    }

    private func loadEntries() -> [WordEntry] {
        guard
            let defaults = UserDefaults(suiteName: appGroupId),
            let json = defaults.string(forKey: dataKey),
            let data = json.data(using: .utf8),
            let payload = try? JSONDecoder().decode(Payload.self, from: data)
        else {
            return []
        }

        if let slots = payload.slots {
            return slots
                .map { slot in
                    WordEntry(
                        date: Date(timeIntervalSince1970: slot.at / 1000), german: slot.title, article: nil,
                        translation: slot.translation, example: slot.example, hasData: true,
                        slotAt: Int(slot.at.rounded())
                    )
                }
                .sorted { $0.date < $1.date }
        }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        return (payload.words ?? [])
            .map { slot in
                let date = Calendar.current.date(byAdding: .minute, value: slot.slotMinutes, to: startOfDay) ?? startOfDay
                return WordEntry(
                    date: date, german: slot.german, article: slot.article,
                    translation: slot.translation, example: slot.example, hasData: true,
                    slotAt: Int((date.timeIntervalSince1970 * 1000).rounded())
                )
            }
            .sorted { $0.date < $1.date }
    }
}

// MARK: - Reveal intent

/// Runs in the widget extension when "Show meaning" is tapped (iOS 17+
/// interactive widgets). Records which slot was revealed; WidgetKit then
/// reloads the timeline, and Provider marks that slot's entry revealed.
/// (Plain `iOS` rather than `iOSApplicationExtension`: the AppIntent
/// macro-synthesised @Parameter accessors otherwise warn about being more
/// available than the struct. Same effect - this file only builds into the
/// extension.)
@available(iOS 17.0, *)
struct RevealMeaningIntent: AppIntent {
    static var title: LocalizedStringResource = "Show meaning"
    static var isDiscoverable: Bool = false

    /// The slot's `at` (epoch millis), as in WordEntry.slotAt.
    @Parameter(title: "Slot")
    var slotAt: Int

    init() {}

    init(slotAt: Int) {
        self.slotAt = slotAt
    }

    func perform() async throws -> some IntentResult {
        UserDefaults(suiteName: appGroupId)?.set(slotAt, forKey: revealedAtKey)
        return .result()
    }
}

// MARK: - View

struct OsgWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) private var family
    /// .fullColor = our own glass look. .accented / .vibrant = the system
    /// draws the background (iOS 26 Liquid Glass "Clear"/"Tinted" Home
    /// Screen, Lock Screen): then plain primary/secondary text so the
    /// system tint applies.
    @Environment(\.widgetRenderingMode) private var renderingMode

    private var fullColor: Bool { renderingMode == .fullColor }
    var titleColor: Color { fullColor ? AppColors.textPrimary : .primary }
    var accentColor: Color { fullColor ? AppColors.accent : .primary }
    var secondaryColor: Color { fullColor ? AppColors.textSecondary : .secondary }

    var body: some View {
        Group {
            if !entry.hasData {
                Text("Open OSG to load your next words")
                    .font(.caption)
            } else {
                // The payload's `title` already starts with the target
                // language's flag ("🇩🇪 der Schlüssel"), set by
                // widget_sync.dart - shown as is, like WordCard.
                switch family {
                case .accessoryInline:
                    // Single line, not interactive: always word · translation.
                    Text("\(entry.wordTitle) · \(entry.translation)")
                case .accessoryRectangular:
                    rectangular
                case .systemMedium:
                    medium
                default:
                    small
                }
            }
        }
        .widgetBackgroundCompat()
    }

    /// Hidden meaning only exists where the reveal button can work (iOS
    /// 17+); on iOS 16 the meaning is always shown, as before.
    private var meaningHidden: Bool {
        if #available(iOSApplicationExtension 17.0, *) {
            return !entry.meaningRevealed
        }
        return false
    }

    // MARK: accessoryRectangular

    /// Too small for a separate button, so while hidden the whole widget
    /// is the reveal button; once revealed, a tap opens the app as usual.
    @ViewBuilder
    private var rectangular: some View {
        if #available(iOSApplicationExtension 17.0, *), meaningHidden {
            Button(intent: RevealMeaningIntent(slotAt: entry.slotAt)) {
                rectangularContent(secondLine: "Tap to reveal")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            rectangularContent(secondLine: entry.translation)
        }
    }

    private func rectangularContent(secondLine: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(entry.wordTitle).font(.headline).lineLimit(1)
            Text(secondLine).font(.caption2).lineLimit(1)
        }
    }

    // MARK: systemSmall

    /// WordCard's exact three lines: bold title (textPrimary), translation
    /// (accent), italic example (textSecondary). While hidden, the last two
    /// are replaced by the "Show meaning" button; tapping anywhere else
    /// still opens the app.
    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.wordTitle)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(titleColor)
                .widgetAccentable()
                .lineLimit(1)
            if #available(iOSApplicationExtension 17.0, *), meaningHidden {
                ShowMeaningButton(slotAt: entry.slotAt)
                    .padding(.top, 2)
            } else {
                Text(entry.translation)
                    .font(.system(size: 12))
                    .foregroundStyle(accentColor)
                    .lineLimit(1)
                Text(entry.example)
                    .font(.system(size: 11))
                    .foregroundStyle(secondaryColor)
                    .italic()
                    .lineLimit(1)
            }
        }
        .padding(14)
    }
}

extension OsgWidgetView {
    // MARK: systemMedium (4x2, like the Android widget)

    /// Same three lines as WordCard with room to breathe: a larger title,
    /// translation and example on up to two lines each.
    var medium: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("OSG")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(secondaryColor)
                .tracking(1)
            Text(entry.wordTitle)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(titleColor)
                .widgetAccentable()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if #available(iOSApplicationExtension 17.0, *), meaningHiddenMedium {
                ShowMeaningButton(slotAt: entry.slotAt)
                    .padding(.top, 4)
            } else {
                Text(entry.translation)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(accentColor)
                    .lineLimit(2)
                Text(entry.example)
                    .font(.system(size: 13))
                    .foregroundStyle(secondaryColor)
                    .italic()
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
    }

    private var meaningHiddenMedium: Bool {
        if #available(iOSApplicationExtension 17.0, *) {
            return !entry.meaningRevealed
        }
        return false
    }
}

/// App-style pill: small capsule, translucent fill + glass border, accent
/// text in a bold caption font.
@available(iOSApplicationExtension 17.0, *)
private struct ShowMeaningButton: View {
    let slotAt: Int

    var body: some View {
        Button(intent: RevealMeaningIntent(slotAt: slotAt)) {
            Text("Show meaning")
                .font(.caption.bold())
                .foregroundStyle(AppColors.accent)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(AppColors.glassFillTop))
                .overlay(Capsule().strokeBorder(AppColors.glassBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    /// `containerBackground(for:)` is required from iOS 17 onward and
    /// unavailable before it. Ports glass_container.dart's recipe - dark
    /// base + diagonal white gradient sheen + translucent border - as the
    /// container background; `ContainerRelativeShape` tracks whatever
    /// corner radius the system gives this widget's size/family so the
    /// border always follows the real edge. Accessory (Lock Screen)
    /// families override all of this with system tinting regardless, so
    /// it only actually renders on .systemSmall / .systemMedium.
    @ViewBuilder
    func widgetBackgroundCompat() -> some View {
        if #available(iOS 17.0, *) {
            // The system removes this background in Clear/Tinted Home
            // Screen modes and draws its own (Liquid) glass instead.
            // The glass edge lives in the background layer, which spans the
            // whole widget - on the content it would sit inside the
            // system's content margins as a second, inner frame.
            containerBackground(for: .widget) {
                GlassBackground()
                    .overlay(ContainerRelativeShape().strokeBorder(AppColors.glassBorder, lineWidth: 1))
            }
        } else {
            background(GlassBackground())
        }
    }
}

/// The app's background in miniature: dark base, three soft color blobs
/// (blue top-left, purple right, teal bottom-left) and the glass card's
/// white sheen on top - so the widget reads as frosted glass over the
/// app's colors instead of a flat dark box.
private struct GlassBackground: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height, m = max(w, h)
            ZStack {
                AppColors.background
                blob(AppColors.blobBlue, size: m * 1.3).position(x: w * 0.05, y: h * -0.05)
                blob(AppColors.blobPurple, size: m * 1.2).position(x: w * 1.0, y: h * 0.45)
                blob(AppColors.blobTeal, size: m * 1.2).position(x: w * 0.0, y: h * 1.15)
                LinearGradient(
                    colors: [Color.white.opacity(0.14), Color.white.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    private func blob(_ color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(RadialGradient(
                colors: [color.opacity(0.55), color.opacity(0.28), color.opacity(0)],
                center: .center, startRadius: 0, endRadius: size / 2
            ))
            .frame(width: size, height: size)
    }
}

// MARK: - Widget

struct OsgWidget: Widget {
    let kind: String = "OsgWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            OsgWidgetView(entry: entry)
        }
        .configurationDisplayName("OSG Word")
        .description("Your current vocabulary word, updated through the day.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .systemSmall, .systemMedium])
    }
}

@main
struct OsgWidgetBundle: WidgetBundle {
    var body: some Widget {
        OsgWidget()
    }
}
