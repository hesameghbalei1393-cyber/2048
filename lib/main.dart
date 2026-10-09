import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
<<<<<<< HEAD
import 'package:url_launcher/url_launcher.dart';

import 'models/board_adapter.dart';
import 'game.dart';
import 'const/colors.dart';
import 'preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Hive.initFlutter();
  Hive.registerAdapter(BoardAdapter());
  await Hive.openBox('settings');
  runApp(const ProviderScope(child: MergeMintApp()));
}

class MergeMintApp extends StatelessWidget {
  const MergeMintApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MergeMint 2048',
        theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: backgroundColor, colorScheme: ColorScheme.fromSeed(seedColor: buttonColor)),
        home: const HomeScreen(),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!(Hive.box('settings').get('languageChosen', defaultValue: false) as bool)) {
        showDialog<void>(context: context, barrierDismissible: false, builder: (dialogContext) => AlertDialog(
          title: const Text('Choose language / انتخاب زبان'),
          content: const Text('Choose the language for MergeMint 2048.'),
          actions: [
            TextButton(onPressed: () async { await Hive.box('settings').put('persian', true); await Hive.box('settings').put('languageChosen', true); if (mounted) setState(() {}); if (dialogContext.mounted) Navigator.pop(dialogContext); }, child: const Text('فارسی')),
            FilledButton(onPressed: () async { await Hive.box('settings').put('persian', false); await Hive.box('settings').put('languageChosen', true); if (mounted) setState(() {}); if (dialogContext.mounted) Navigator.pop(dialogContext); }, child: const Text('English')),
          ],
        ));
      }
    });
  }

  void refresh() => setState(() {});

  void settings() => showDialog<void>(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
    title: Text(isPersian ? 'تنظیمات' : 'Settings'),
    content: SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(isPersian ? 'زبان فارسی' : 'Persian language'),
      subtitle: Text(isPersian ? 'خاموش: English' : 'Off: English'),
      value: isPersian,
      onChanged: (value) async { await Hive.box('settings').put('persian', value); await Hive.box('settings').put('languageChosen', true); setDialogState(() {}); refresh(); },
    ),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(isPersian ? 'بستن' : 'Close'))],
  )));

  void about() => showDialog<void>(context: context, builder: (context) => AlertDialog(
    title: Text(isPersian ? 'درباره MergeMint 2048' : 'About MergeMint 2048'),
    content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(isPersian ? 'یک بازی فکری ساده بر پایه ادغام کاشی‌های هم‌شماره؛ هدفت رسیدن به ۲۰۴۸ است.' : 'A classic number puzzle: merge matching tiles and try to reach 2048.'),
      const SizedBox(height: 14), Text('Made by Eight⁸ Studio'),
      const SizedBox(height: 10),
      InkWell(child: const Text('Rubika: @Studio_Eight8', style: TextStyle(color: Colors.blue)), onTap: () => launchUrl(Uri.parse('https://rubika.ir/Studio_Eight8'), mode: LaunchMode.externalApplication)),
      InkWell(child: const Text('Developer: @Hesam23799', style: TextStyle(color: Colors.blue)), onTap: () async { await Clipboard.setData(const ClipboardData(text: '@Hesam23799')); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isPersian ? 'آیدی کپی شد' : 'ID copied'))); }),
      InkWell(child: const Text('Feedback: hesameghbalei1391@gmail.com', style: TextStyle(color: Colors.blue)), onTap: () => launchUrl(Uri(scheme: 'mailto', path: 'hesameghbalei1391@gmail.com', queryParameters: {'subject':'MergeMint 2048 feedback'}))),
    ]),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(isPersian ? 'بستن' : 'Close'))],
  ));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('MergeMint 2048', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)), backgroundColor: backgroundColor,
      actions: [IconButton(tooltip: isPersian ? 'تنظیمات' : 'Settings', onPressed: settings, icon: const Icon(Icons.settings_outlined, color: textColor)), IconButton(tooltip: isPersian ? 'درباره' : 'About', onPressed: about, icon: const Icon(Icons.info_outline, color: textColor))]),
    body: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 100, height: 100, decoration: BoxDecoration(color: buttonColor, borderRadius: BorderRadius.circular(24)), alignment: Alignment.center, child: const Text('2048', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 30))),
      const SizedBox(height: 20), const Text('MergeMint 2048', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: textColor)),
      const SizedBox(height: 8), Text(isPersian ? 'عددها را ادغام کن و به ۲۰۴۸ برس!' : 'Merge the tiles and reach 2048!', style: const TextStyle(color: textColor)),
      const SizedBox(height: 34), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Game())), icon: const Icon(Icons.play_arrow), label: Text(isPersian ? 'شروع بازی' : 'Start Game'), style: FilledButton.styleFrom(backgroundColor: buttonColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)))),
      const SizedBox(height: 12), SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: settings, icon: const Icon(Icons.settings_outlined), label: Text(isPersian ? 'تنظیمات' : 'Settings'), style: OutlinedButton.styleFrom(foregroundColor: textColor, padding: const EdgeInsets.symmetric(vertical: 14)))),
      const SizedBox(height: 4), TextButton(onPressed: about, child: Text(isPersian ? 'درباره برنامه' : 'About', style: const TextStyle(color: textColor))),
    ]))),
  );
=======

import 'models/board_adapter.dart';

import 'game.dart';

void main() async {
  //Allow only portrait mode on Android & iOS
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  );
  //Make sure Hive is initialized first and only after register the adapter.
  await Hive.initFlutter();
  Hive.registerAdapter(BoardAdapter());
  runApp(const ProviderScope(
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      
      title: 'MergeMint 2048',
      home: Game(),
    ),
  ));
>>>>>>> 5a2e75ccc159512ba54ab5c94eecfbc71b73ab78
}
