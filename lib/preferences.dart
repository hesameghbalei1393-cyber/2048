import 'package:hive_flutter/hive_flutter.dart';

bool get isPersian => Hive.box('settings').get('persian', defaultValue: false) as bool;
