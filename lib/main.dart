import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
WidgetsFlutterBinding.ensureInitialized();
SystemChrome.setPreferredOrientations([
DeviceOrientation.portraitUp,
]);
runApp(const MergeMintApp());
}

class MergeMintApp extends StatelessWidget {
const MergeMintApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'MergeMint 2048',
debugShowCheckedModeBanner: false,
theme: ThemeData(
useMaterial3: true,
colorScheme: ColorScheme.fromSeed(
seedColor: const Color(0xff8f7a66),
),
),
home: const GamePage(),
);
}
}

class Tile {
final int id;
final int value;

const Tile(this.id, this.value);
}

class MovingTile {
final Tile tile;
final int fromRow;
final int fromCol;
final int toRow;
final int toCol;

const MovingTile({
required this.tile,
required this.fromRow,
required this.fromCol,
required this.toRow,
required this.toCol,
});
}

class GamePage extends StatefulWidget {
const GamePage({super.key});

@override
State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
static const int size = 4;
static const Duration moveDuration = Duration(milliseconds: 190);

final Random _random = Random();

List<List<Tile?>> grid = List.generate(
size,
() => List<Tile?>.filled(size, null),
);

List<List<Tile?>>? _previousGrid;
List<List<Tile?>>? _pendingGrid;
List<MovingTile>? _movingTiles;

int _nextTileId = 0;
int _score = 0;
int _previousScore = 0;
int _best = 0;

bool _isPersian = true;
bool _isMoving = false;
bool _wonShown = false;
bool _gameOverShown = false;

String t(String fa, String en) => _isPersian ? fa : en;

@override
void initState() {
super.initState();
_newGame();
}

List<List<Tile?>> _copyGrid(List<List<Tile?>> source) {
return source.map((row) => List<Tile?>.from(row)).toList();
}

void _newGame() {
grid = List.generate(
size,
() => List<Tile?>.filled(size, null),
);

_score = 0;
_previousScore = 0;
_previousGrid = null;
_pendingGrid = null;
_movingTiles = null;
_isMoving = false;
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
    if (_grid[r][c] == null) {
      empty.add(Point(r, c));
    }
  }
}

if (empty.isEmpty) return;

final p = empty[_random.nextInt(empty.length)];
final value = _random.nextInt(10) == 0 ? 4 : 2;

_grid[p.x][p.y] = Tile(_nextTileId++, value);

}

void _move(String direction) {
if (_isMoving) return;

final target = List.generate(
  size,
  (_) => List<Tile?>.filled(size, null),
);

final plans = <MovingTile>[];
var gained = 0;

for (var lineIndex = 0; lineIndex < size; lineIndex++) {
  final cells = <Point<int>>[];

  for (var offset = 0; offset < size; offset++) {
    int r;
    int c;

    if (direction == 'left') {
      r = lineIndex;
      c = offset;
    } else if (direction == 'right') {
      r = lineIndex;
      c = size - 1 - offset;
    } else if (direction == 'up') {
      r = offset;
      c = lineIndex;
    } else {
      r = size - 1 - offset;
      c = lineIndex;
    }

    cells.add(Point(r, c));
  }

  final occupied = <({Tile tile, int r, int c})>[];

  for (final cell in cells) {
    final tile = _grid[cell.x][cell.y];

    if (tile != null) {
      occupied.add((
        tile: tile,
        r: cell.x,
        c: cell.y,
      ));
    }
  }

  var sourceIndex = 0;
  var destinationIndex = 0;

  while (sourceIndex < occupied.length) {
    final first = occupied[sourceIndex];

    final canMerge = sourceIndex + 1 < occupied.length &&
        first.tile.value ==
            occupied[sourceIndex + 1].tile.value;

    final destination = cells[destinationIndex];
    final destinationRow = destination.x;
    final destinationCol = destination.y;

    if (canMerge) {
      final second = occupied[sourceIndex + 1];
      final mergedValue = first.tile.value * 2;

      target[destinationRow][destinationCol] = Tile(
        _nextTileId++,
        mergedValue,
      );

      gained += mergedValue;

      plans.add(MovingTile(
        tile: first.tile,
        fromRow: first.r,
        fromCol: first.c,
        toRow: destinationRow,
        toCol: destinationCol,
      ));

      plans.add(MovingTile(
        tile: second.tile,
        fromRow: second.r,
        fromCol: second.c,
        toRow: destinationRow,
        toCol: destinationCol,
      ));

      sourceIndex += 2;
    } else {
      target[destinationRow][destinationCol] = first.tile;

      plans.add(MovingTile(
        tile: first.tile,
        fromRow: first.r,
        fromCol: first.c,
        toRow: destinationRow,
        toCol: destinationCol,
      ));

      sourceIndex++;
    }

    destinationIndex++;
  }
}

var changed = false;

for (var r = 0; r < size; r++) {
  for (var c = 0; c < size; c++) {
    if (_grid[r][c]?.value != target[r][c]?.value) {
      changed = true;
      break;
    }
  }

  if (changed) break;
}

if (!changed) return;

_previousGrid = _copyGrid(_grid);
_previousScore = _score;

_pendingGrid = target;
_movingTiles = plans;
_isMoving = true;

setState(() {});

Future.delayed(moveDuration + const Duration(milliseconds: 25), () {
  if (!mounted || !_isMoving || _pendingGrid == null) return;

  setState(() {
    _grid = _pendingGrid!;
    _pendingGrid = null;
    _movingTiles = null;
    _isMoving = false;

    _score += gained;
    _best = max(_best, _score);

    _addTile();
  });

  if (!_wonShown &&
      _grid.any((row) => row.any((tile) => tile?.value == 2048))) {
    _wonShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _message(t(
        'آفرین! به ۲۰۴۸ رسیدی 🎉',
        'Great! You reached 2048 🎉',
      ));
    });
  } else if (_isGameOver() && !_gameOverShown) {
    _gameOverShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _message(t('بازی تمام شد!', 'Game over!'));
    });
  }
});

}

bool _isGameOver() {
for (var r = 0; r < size; r++) {
for (var c = 0; c < size; c++) {
final tile = _grid[r][c];

    if (tile == null) return false;

    if (r + 1 < size &&
        tile.value == _grid[r + 1][c]?.value) {
      return false;
    }

    if (c + 1 < size &&
        tile.value == _grid[r][c + 1]?.value) {
      return false;
    }
  }
}

return true;

}

void _undo() {
if (_isMoving || _previousGrid == null) return;

setState(() {
  _grid = _copyGrid(_previousGrid!);
  _score = _previousScore;
  _previousGrid = null;
  _gameOverShown = false;
});

}

void _message(String message) {
if (!mounted) return;

showDialog<void>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: Text(message),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(ctx),
        child: Text(t('باشه', 'OK')),
      ),
      TextButton(
        onPressed: () {
          Navigator.pop(ctx);
          _newGame();
        },
        child: Text(t('بازی جدید', 'New game')),
      ),
    ],
  ),
);

}

Future<void> _openLink(String url) async {
final uri = Uri.parse(url);

try {
  final opened = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );

  if (!opened && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t(
          'باز کردن لینک ممکن نشد.',
          'Could not open the link.',
        )),
      ),
    );
  }
} catch (_) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(t(
        'خطا در باز کردن لینک.',
        'Error opening link.',
      )),
    ),
  );
}

}

Future<void> _copyText(String value) async {
await Clipboard.setData(ClipboardData(text: value));

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(t('کپی شد: $value', 'Copied: $value')),
    duration: const Duration(seconds: 2),
  ),
);

}

void _about() {
showDialog<void>(
context: context,
builder: (ctx) => AlertDialog(
title: Text(t('درباره MergeMint 2048', 'About MergeMint 2048')),
content: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(t(
'عددهای یکسان را ترکیب کن و به ۲۰۴۸ برس!',
'Merge matching tiles and reach 2048!',
)),
const SizedBox(height: 14),
const Text('Eight⁸ Studio'),
const SizedBox(height: 8),
InkWell(
onTap: () {
Navigator.pop(ctx);
_openLink('https://rubika.ir/Studio_Eight8');
},
child: Text(
t('کانال روبیکا: @Studio_Eight8',
'Rubika channel: @Studio_Eight8'),
style: const TextStyle(
color: Colors.blue,
decoration: TextDecoration.underline,
),
),
),
TextButton.icon(
onPressed: () => _copyText('@Studio_Eight8'),
icon: const Icon(Icons.copy),
label: Text(t('کپی آیدی کانال', 'Copy channel ID')),
),
InkWell(
onTap: () {
Navigator.pop(ctx);
_openLink('https://rubika.ir/Hesam23799');
},
child: const Text(
'Developer: @Hesam23799',
style: TextStyle(
color: Colors.blue,
decoration: TextDecoration.underline,
),
),
),
TextButton.icon(
onPressed: () => _copyText('@Hesam23799'),
icon: const Icon(Icons.copy),
label: Text(t('کپی آیدی سازنده', 'Copy developer ID')),
),
],
),
actions: [
TextButton(
onPressed: () => Navigator.pop(ctx),
child: Text(t('بستن', 'Close')),
),
],
),
);
}

void _selectMenu(String value) {
switch (value) {
case 'channel':
_openLink('https://rubika.ir/Studio_Eight8');
break;
case 'copy_channel':
_copyText('@Studio_Eight8');
break;
case 'developer':
_openLink('https://rubika.ir/Hesam23799');
break;
case 'copy_developer':
_copyText('@Hesam23799');
break;
case 'about':
_about();
break;
}
}

Color _tileColor(int value) {
const colors = <int, Color>{
2: Color(0xffeee4da),
4: Color(0xffede0c8),
8: Color(0xfff2b179),
16: Color(0xfff59563),
32: Color(0xfff67c5f),
64: Color(0xfff65e3b),
128: Color(0xffedcf72),
256: Color(0xffedcc61),
512: Color(0xffedc850),
1024: Color(0xffedc53f),
2048: Color(0xffedc22e),
};

return colors[value] ?? const Color(0xff3c3a32);

}

Color _textColor(int value) {
return value <= 4
? const Color(0xff776e65)
: Colors.white;
}

Widget _tileContent(Tile tile) {
return Container(
decoration: BoxDecoration(
color: _tileColor(tile.value),
borderRadius: BorderRadius.circular(6),
),
alignment: Alignment.center,
child: FittedBox(
fit: BoxFit.scaleDown,
child: Padding(
padding: const EdgeInsets.all(2),
child: Text(
'${tile.value}',
style: TextStyle(
fontSize: tile.value >= 1024
? 24
: tile.value >= 128
? 28
: 34,
fontWeight: FontWeight.w900,
color: _textColor(tile.value),
),
),
),
),
);
}

Widget _buildBoard(double boardWidth) {
return Container(
width: boardWidth,
height: boardWidth,
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: const Color(0xffbbada0),
borderRadius: BorderRadius.circular(10),
),
child: LayoutBuilder(
builder: (context, constraints) {
final cellSize = constraints.maxWidth / size;
final tileSize = cellSize - 8;

      final tiles = <MovingTile>[];

      if (_isMoving && _movingTiles != null) {
        tiles.addAll(_movingTiles!);
      } else {
        for (var r = 0; r < size; r++) {
          for (var c = 0; c < size; c++) {
            final tile = _grid[r][c];

            if (tile != null) {
              tiles.add(MovingTile(
                tile: tile,
                fromRow: r,
                fromCol: c,
                toRow: r,
                toCol: c,
              ));
            }
          }
        }
      }

      return Stack(
        children: [
          for (var r = 0; r < size; r++)
            for (var c = 0; c < size; c++)
              Positioned(
                left: c * cellSize + 4,
                top: r * cellSize + 4,
                width: tileSize,
                height: tileSize,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xffcdc1b4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
          for (final item in tiles)
            AnimatedPositioned(
              key: ValueKey(item.tile.id),
              duration: moveDuration,
              curve: Curves.easeInOutCubic,
              left: item.toCol * cellSize + 4,
              top: item.toRow * cellSize + 4,
              width: tileSize,
              height: tileSize,
              child: _tileContent(item.tile),
            ),
        ],
      );
    },
  ),
);

}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xfffaf8ef),
appBar: AppBar(
backgroundColor: const Color(0xfffaf8ef),
title: const Text(
'MergeMint 2048',
style: TextStyle(
fontWeight: FontWeight.w900,
color: Color(0xff776e65),
),
),
actions: [
IconButton(
tooltip: t('تغییر زبان', 'Change language'),
onPressed: () => setState(() => _isPersian = !_isPersian),
icon: const Icon(
Icons.language,
color: Color(0xff776e65),
),
),
PopupMenuButton<String>(
tooltip: t('منو و لینک‌ها', 'Menu and links'),
onSelected: _selectMenu,
icon: const Icon(
Icons.more_vert,
color: Color(0xff776e65),
),
itemBuilder: (context) => [
PopupMenuItem(
value: 'channel',
child: Text(t('باز کردن کانال روبیکا', 'Open Rubika channel')),
),
PopupMenuItem(
value: 'copy_channel',
child: Text(t('کپی آیدی کانال', 'Copy channel ID')),
),
const PopupMenuDivider(),
PopupMenuItem(
value: 'developer',
child: Text(t('صفحه سازنده', 'Developer profile')),
),
PopupMenuItem(
value: 'copy_developer',
child: Text(t('کپی آیدی سازنده', 'Copy developer ID')),
),
const PopupMenuDivider(),
PopupMenuItem(
value: 'about',
child: Text(t('درباره برنامه', 'About the app')),
),
],
),
],
),
body: SafeArea(
child: LayoutBuilder(
builder: (context, constraints) {
final boardWidth = min(
constraints.maxWidth - 32,
460.0,
);

        return Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: boardWidth,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t(
                            'عددها را ادغام کن و به ۲۰۴۸ برس!',
                            'Merge tiles and reach 2048!',
                          ),
                          style: const TextStyle(
                            color: Color(0xff776e65),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      _scoreCard(t('امتیاز', 'SCORE'), _score),
                      const SizedBox(width: 8),
                      _scoreCard(t('بهترین', 'BEST'), _best),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: boardWidth,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t('با کشیدن صفحه بازی کن', 'Swipe to play'),
                          style: const TextStyle(
                            color: Color(0xff776e65),
                          ),
                        ),
                      ),
                      _smallButton(
                        Icons.undo,
                        t('برگشت', 'Undo'),
                        _undo,
                      ),
                      const SizedBox(width: 8),
                      _smallButton(
                        Icons.refresh,
                        t('جدید', 'New'),
                        _newGame,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onVerticalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity.abs() > 80) {
                      _move(velocity < 0 ? 'up' : 'down');
                    }
                  },
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity.abs() > 80) {
                      _move(velocity < 0 ? 'left' : 'right');
                    }
                  },
                  child: _buildBoard(boardWidth),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Eight⁸ Studio',
                  style: TextStyle(
                    color: Color(0xff776e65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        );
      },
    ),
  ),
);

}

Widget _scoreCard(String label, int value) {
return Container(
padding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 8,
),
decoration: BoxDecoration(
color: const Color(0xffbbada0),
borderRadius: BorderRadius.circular(6),
),
child: Column(
children: [
Text(
label,
style: const TextStyle(
color: Colors.white,
fontSize: 10,
fontWeight: FontWeight.w800,
),
),
Text(
'$value',
style: const TextStyle(
color: Colors.white,
fontSize: 18,
fontWeight: FontWeight.w900,
),
),
],
),
);
}

Widget _smallButton(
IconData icon,
String label,
VoidCallback onTap,
) {
return FilledButton.tonalIcon(
onPressed: _isMoving ? null : onTap,
icon: Icon(icon, size: 18),
label: Text(label),
style: FilledButton.styleFrom(
foregroundColor: const Color(0xff776e65),
backgroundColor: const Color(0xffeee4da),
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 10,
),
),
);
}
}
