import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MergeMintApp());
}

class MergeMintApp extends StatelessWidget {
  const MergeMintApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'MergeMint 2048',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff8f7a66))),
        home: const GamePage(),
      );
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  static const int size = 4;
  final Random _random = Random();
  List<List<int>> _grid = List.generate(size, (_) => List.filled(size, 0));
  List<List<int>>? _previousGrid;
  int _score = 0;
  int _previousScore = 0;
  int _best = 0;
  bool _isPersian = true;
  bool _wonShown = false;
  bool _gameOverShown = false;

  String t(String fa, String en) => _isPersian ? fa : en;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  List<List<int>> _copyGrid(List<List<int>> source) => source.map((row) => List<int>.from(row)).toList();

  void _newGame() {
    _grid = List.generate(size, (_) => List.filled(size, 0));
    _score = 0;
    _previousGrid = null;
    _wonShown = false;
    _gameOverShown = false;
    _addTile();
    _addTile();
    if (mounted) setState(() {});
  }

  void _addTile() {
    final empty = <Point<int>>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (_grid[r][c] == 0) empty.add(Point(r, c));
      }
    }
    if (empty.isEmpty) return;
    final p = empty[_random.nextInt(empty.length)];
    _grid[p.x][p.y] = _random.nextInt(10) == 0 ? 4 : 2;
  }

  void _move(String direction) {
    final before = _copyGrid(_grid);
    final beforeScore = _score;
    var changed = false;
    for (var i = 0; i < size; i++) {
      List<int> line;
      if (direction == 'left' || direction == 'right') {
        line = List<int>.from(_grid[i]);
      } else {
        line = List.generate(size, (j) => _grid[j][i]);
      }
      if (direction == 'right' || direction == 'down') line = line.reversed.toList();
      final compact = line.where((v) => v != 0).toList();
      final merged = <int>[];
      for (var j = 0; j < compact.length; j++) {
        if (j + 1 < compact.length && compact[j] == compact[j + 1]) {
          final value = compact[j] * 2;
          merged.add(value);
          _score += value;
          j++;
        } else {
          merged.add(compact[j]);
        }
      }
      while (merged.length < size) { merged.add(0); }
      if (direction == 'right' || direction == 'down') {
        line = merged.reversed.toList();
      } else {
        line = merged;
      }
      for (var j = 0; j < size; j++) {
        final old = direction == 'left' || direction == 'right' ? _grid[i][j] : _grid[j][i];
        if (old != line[j]) changed = true;
        if (direction == 'left' || direction == 'right') {
          _grid[i][j] = line[j];
        } else {
          _grid[j][i] = line[j];
        }
      }
    }
    if (!changed) { _score = beforeScore; return; }
    _previousGrid = before;
    _previousScore = beforeScore;
    _addTile();
    _best = max(_best, _score);
    setState(() {});
    if (!_wonShown && _grid.any((row) => row.contains(2048))) {
      _wonShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _message(t('آفرین! به ۲۰۴۸ رسیدی 🎉', 'Great! You reached 2048 🎉')));
    } else if (_isGameOver() && !_gameOverShown) {
      _gameOverShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _message(t('بازی تمام شد!', 'Game over!')));
    }
  }

  bool _isGameOver() {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (_grid[r][c] == 0) return false;
        if (r + 1 < size && _grid[r][c] == _grid[r + 1][c]) return false;
        if (c + 1 < size && _grid[r][c] == _grid[r][c + 1]) return false;
      }
    }
    return true;
  }

  void _undo() {
    if (_previousGrid == null) return;
    setState(() {
      _grid = _copyGrid(_previousGrid!);
      _score = _previousScore;
      _previousGrid = null;
      _gameOverShown = false;
    });
  }

  void _message(String message) {
    if (!mounted) return;
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: Text(message),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('باشه', 'OK'))),
        TextButton(onPressed: () { Navigator.pop(ctx); _newGame(); }, child: Text(t('بازی جدید', 'New game')))],
    ));
  }

  Color _tileColor(int value) {
    const colors = <int, Color>{
      0: Color(0xffcdc1b4), 2: Color(0xffeee4da), 4: Color(0xffede0c8),
      8: Color(0xfff2b179), 16: Color(0xfff59563), 32: Color(0xfff67c5f),
      64: Color(0xfff65e3b), 128: Color(0xffedcf72), 256: Color(0xffedcc61),
      512: Color(0xffedc850), 1024: Color(0xffedc53f), 2048: Color(0xffedc22e),
    };
    return colors[value] ?? const Color(0xff3c3a32);
  }

  Color _textColor(int value) => value <= 4 ? const Color(0xff776e65) : Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffaf8ef),
      appBar: AppBar(
        backgroundColor: const Color(0xfffaf8ef),
        title: const Text('MergeMint 2048', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xff776e65))),
        actions: [
          IconButton(tooltip: t('تغییر زبان', 'Change language'), onPressed: () => setState(() => _isPersian = !_isPersian), icon: const Icon(Icons.language, color: Color(0xff776e65))),
          IconButton(tooltip: t('درباره', 'About'), onPressed: () => showAboutDialog(
            context: context, applicationName: 'MergeMint 2048', applicationVersion: '1.0.0',
            applicationLegalese: '© 2026 Eight⁸ Studio',
            children: const [Text('Merge matching tiles and try to reach 2048.'), SizedBox(height: 8), Text('Eight⁸ Studio'), Text('Rubika: @Studio_Eight8'), Text('Developer: @Hesam23799')],
          ), icon: const Icon(Icons.info_outline, color: Color(0xff776e65))),
        ],
      ),
      body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        final boardWidth = min(constraints.maxWidth - 32, 460.0);
        return Center(child: SingleChildScrollView(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: boardWidth, child: Row(children: [
            Expanded(child: Text(t('عددها را ادغام کن و به ۲۰۴۸ برس!', 'Merge tiles and reach 2048!'), style: const TextStyle(color: Color(0xff776e65), fontWeight: FontWeight.w700, fontSize: 15))),
            _scoreCard(t('امتیاز', 'SCORE'), _score), const SizedBox(width: 8), _scoreCard(t('بهترین', 'BEST'), _best),
          ])),
          const SizedBox(height: 14),
          SizedBox(width: boardWidth, child: Row(children: [
            Expanded(child: Text(t('با کشیدن صفحه بازی کن', 'Swipe to play'), style: const TextStyle(color: Color(0xff776e65)))),
            _smallButton(Icons.undo, t('برگشت', 'Undo'), _undo), const SizedBox(width: 8),
            _smallButton(Icons.refresh, t('جدید', 'New'), _newGame),
          ])),
          const SizedBox(height: 16),
          GestureDetector(
            onVerticalDragEnd: (details) { final v = details.primaryVelocity ?? 0; if (v.abs() > 80) _move(v < 0 ? 'up' : 'down'); },
            onHorizontalDragEnd: (details) { final v = details.primaryVelocity ?? 0; if (v.abs() > 80) _move(v < 0 ? 'left' : 'right'); },
            child: Container(width: boardWidth, height: boardWidth, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xffbbada0), borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: List.generate(
                  size,
                  (r) => Expanded(
                    child: Row(
                      children: List.generate(size, (c) {
                        final value = _grid[r][c];
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _tileColor(value),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: value == 0
                                ? const SizedBox.shrink()
                                : FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: Text(
                                        '$value',
                                        style: TextStyle(
                                          fontSize: value >= 1024
                                              ? 24
                                              : value >= 128
                                                  ? 28
                                                  : 34,
                                          fontWeight: FontWeight.w900,
                                          color: _textColor(value),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(t('ساخته‌شده توسط Eight⁸ Studio', 'Made by Eight⁸ Studio'), style: const TextStyle(color: Color(0xff776e65), fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
        ])));
      })),
    );
  }

  Widget _scoreCard(String label, int value) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: const Color(0xffbbada0), borderRadius: BorderRadius.circular(6)), child: Column(children: [Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)), Text('$value', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))]));

  Widget _smallButton(IconData icon, String label, VoidCallback onTap) => FilledButton.tonalIcon(onPressed: onTap, icon: Icon(icon, size: 18), label: Text(label), style: FilledButton.styleFrom(foregroundColor: const Color(0xff776e65), backgroundColor: const Color(0xffeee4da), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)));
}
