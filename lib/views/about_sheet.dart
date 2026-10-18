import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app.dart';

/// Keep in step with `version:` in pubspec.yaml (a test checks this).
const appVersion = '1.1.0';

const privacyUrl = 'https://tools.homilabs.org/privacy.html#businesscalc';
const termsUrl = 'https://tools.homilabs.org/terms.html#businesscalc';
const contactEmail = 'homilabs.smc@gmail.com';
const communityUrl = 'https://www.facebook.com/groups/2834353386950005?ref=app';

/// Opens [url] in the browser. The app itself has no internet permission;
/// the browser does the fetching.
Future<void> openLink(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).catchError((_) => false);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open $url')));
  }
}

const _help = [
  ('M+ / M−', 'Finish the calculation and add it to (or take it from) memory. MR recalls, MC clears.'),
  ('GT', 'Grand total of every result. Tap to use it, long-press to clear.'),
  ('TAX+ / TAX−', 'Add tax, or take tax out of a price that includes it. Set the rate in Settings.'),
  ('%', '500 + 10% = 550 · 500 − 10% = 450 · 250 × 8% = 20'),
  ('Tape', 'Every result is saved. Tap one on screen to reuse it; share or copy the tape.'),
];

Future<void> showAboutSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (ctx) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.85),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ListTile(
              leading: Icon(Icons.calculate_outlined, color: Palette.accent, size: 32),
              title: Text(appName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              subtitle: Text('Version $appVersion · by HomiLabs'),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'No account and no sign-in. Your calculations stay on this phone and work offline. '
                'The app is free and shows ads from Google AdMob.',
                style: TextStyle(color: Palette.inkSoft),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text('Keys', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            for (final (k, v) in _help)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$k  ',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Palette.opKey),
                      ),
                      TextSpan(text: v),
                    ],
                  ),
                  style: const TextStyle(fontSize: 14, height: 1.35, color: Palette.ink),
                ),
              ),
            const SizedBox(height: 8),
            ListTile(
              key: const Key('about-privacy'),
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy policy'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => openLink(ctx, privacyUrl),
            ),
            ListTile(
              key: const Key('about-terms'),
              leading: const Icon(Icons.description_outlined),
              title: const Text('Terms of use'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => openLink(ctx, termsUrl),
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Contact'),
              subtitle: const Text(contactEmail),
              onTap: () => openLink(ctx, 'mailto:$contactEmail?subject=Business%20Calculator'),
            ),
            ListTile(
              key: const Key('about-community'),
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Join the HomiLabs community'),
              subtitle: const Text('New apps, early builds and a say in what we build next'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => openLink(ctx, communityUrl),
            ),
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: const Text('Open-source licences'),
              onTap: () => showLicensePage(context: ctx, applicationName: appName, applicationVersion: appVersion),
            ),
          ],
        ),
      ),
    ),
  ),
);
