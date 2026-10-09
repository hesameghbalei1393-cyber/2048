import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';

import 'components/button.dart';
import 'components/empty_board.dart';
import 'components/score_board.dart';
import 'components/tile_board.dart';
import 'const/colors.dart';
import 'managers/board.dart';

class _AboutAppIcon extends StatelessWidget {
  const _AboutAppIcon();

  @override
  Widget build(BuildContext context) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xff8f7a66),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Text(
          '2048',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      );
}

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
            actions: [
              IconButton(
                tooltip: 'About',
                icon: const Icon(Icons.info_outline, color: textColor),
                onPressed: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'MergeMint 2048',
                    applicationVersion: '1.0.0',
                    applicationIcon: const _AboutAppIcon(),
                    applicationLegalese: '© 2026 Eight⁸ Studio',
                    children: const [
                      SizedBox(height: 8),
                      Text(
                        'MergeMint 2048 is a number puzzle game inspired by the classic 2048 gameplay. Swipe to move tiles, merge matching numbers, and challenge yourself to reach 2048.',
                        textAlign: TextAlign.start,
                      ),
                      SizedBox(height: 12),
                      Text('Created with care by Eight⁸ Studio.'),
                      SizedBox(height: 8),
                      Text('Rubika: @Studio_Eight8'),
                      Text('Developer: @Hesam23799'),
                      Text('Privacy: the game stores gameplay data locally on your device and does not send it to a server.'),
                    ],
                  );
                },
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
