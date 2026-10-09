import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'preferences.dart';

import 'components/button.dart';
import 'components/empty_board.dart';
import 'components/score_board.dart';
import 'components/tile_board.dart';
import 'const/colors.dart';
import 'managers/board.dart';

class Game extends ConsumerStatefulWidget {
  const Game({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => Controller();
}

class Controller extends ConsumerState<Game>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  //The controller used to move the the tiles
  late final AnimationController _moveController = AnimationController(
    duration: const Duration(milliseconds: 100),
    vsync: this,
  )..addStatusListener((status) {
      //When the movement finishes merge the tiles and start the scale animation which gives the pop effect.
      if (status == AnimationStatus.completed) {
        ref.read(boardManager.notifier).merge();
        _scaleController.forward(from: 0.0);
      }
    });

  //The curve animation for the move animation controller.
  late final CurvedAnimation _moveAnimation = CurvedAnimation(
    parent: _moveController,
    curve: Curves.easeInOut,
  );

  //The controller used to show a popup effect when the tiles get merged
  late final AnimationController _scaleController = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  )..addStatusListener((status) {
      //When the scale animation finishes end the round and if there is a queued movement start the move controller again for the next direction.
      if (status == AnimationStatus.completed) {
        if (ref.read(boardManager.notifier).endRound()) {
          _moveController.forward(from: 0.0);
        }
      }
    });

  //The curve animation for the scale animation controller.
  late final CurvedAnimation _scaleAnimation = CurvedAnimation(
    parent: _scaleController,
    curve: Curves.easeInOut,
  );

  @override
  void initState() {
    //Add an Observer for the Lifecycles of the App
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      autofocus: true,
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          // Move the tile with the arrows on the keyboard on Desktop
          if (ref.read(boardManager.notifier).onKey(event)) {
            _moveController.forward(from: 0.0);
          }
        }
      },
      child: SwipeDetector(
        onSwipe: (direction, offset) {
          if (ref.read(boardManager.notifier).move(direction)) {
            _moveController.forward(from: 0.0);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'MergeMint 2048',
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 34.0),
            ),
            backgroundColor: backgroundColor,
            leading: IconButton(
              tooltip: isPersian ? 'بازگشت' : 'Back',
              icon: const Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.maybePop(context),
            ),
            actions: [
              IconButton(
                tooltip: isPersian ? 'تنظیمات' : 'Settings',
                icon: const Icon(Icons.settings_outlined, color: textColor),
                onPressed: () => showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (dialogContext, setDialogState) => AlertDialog(
                  title: Text(isPersian ? 'تنظیمات' : 'Settings'),
                  content: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(isPersian ? 'زبان فارسی' : 'Persian language'),
                    value: isPersian,
                    onChanged: (value) async { await Hive.box('settings').put('persian', value); setDialogState(() {}); if (mounted) setState(() {}); },
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(isPersian ? 'بستن' : 'Close'))],
                ))),
              ),
              IconButton(
                tooltip: isPersian ? 'درباره' : 'About',
                icon: const Icon(Icons.info_outline, color: textColor),
                onPressed: () => showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
                  title: Text(isPersian ? 'درباره MergeMint 2048' : 'About MergeMint 2048'),
                  content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isPersian ? 'عددهای هم‌شماره را ادغام کن و به ۲۰۴۸ برس.' : 'Merge matching tiles and try to reach 2048.'),
                    const SizedBox(height: 12), const Text('Eight⁸ Studio'),
                    InkWell(child: const Text('Rubika: @Studio_Eight8', style: TextStyle(color: Colors.blue)), onTap: () => launchUrl(Uri.parse('https://rubika.ir/Studio_Eight8'), mode: LaunchMode.externalApplication)),
                    InkWell(child: const Text('Developer: @Hesam23799', style: TextStyle(color: Colors.blue)), onTap: () async { await Clipboard.setData(const ClipboardData(text: '@Hesam23799')); }),
                    InkWell(child: const Text('hesameghbalei1391@gmail.com', style: TextStyle(color: Colors.blue)), onTap: () => launchUrl(Uri(scheme: 'mailto', path: 'hesameghbalei1391@gmail.com'))),
                  ]),
                  actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(isPersian ? 'بستن' : 'Close'))],
                )),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const ScoreBoard(),
                        const SizedBox(
                          height: 32.0,
                        ),
                        Row(
                          children: [
                            ButtonWidget(
                              icon: Icons.undo,
                              onPressed: () {
                                //Undo the round.
                                ref.read(boardManager.notifier).undo();
                              },
                            ),
                            const SizedBox(
                              width: 16.0,
                            ),
                            ButtonWidget(
                              icon: Icons.refresh,
                              onPressed: () {
                                //Restart the game
                                ref.read(boardManager.notifier).newGame();
                              },
                            )
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 32.0,
              ),
              Stack(
                children: [
                  const EmptyBoardWidget(),
                  TileBoardWidget(
                    moveAnimation: _moveAnimation,
                    scaleAnimation: _scaleAnimation,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    //Save current state when the app becomes inactive
    if (state == AppLifecycleState.inactive) {
      ref.read(boardManager.notifier).save();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    //Remove the Observer for the Lifecycles of the App
    WidgetsBinding.instance.removeObserver(this);

    //Dispose the animations.
    _moveAnimation.dispose();
    _scaleAnimation.dispose();
    _moveController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}
