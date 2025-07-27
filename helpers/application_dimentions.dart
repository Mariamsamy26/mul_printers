import 'package:flutter/material.dart';

class AppDimentions {
  var myAppBar = AppBar();
  static double? _appBarHeight;
  static double? _statusBarHeight;
  static double? _availableheightWithAppBar;
  static double? _availableheightWithAppBarIOS;
  static double? _availableheightNoAppBar;
  static double? _availableWidth;

  double get availableheightWithAppBar => _availableheightWithAppBar!;
  double get availableheightWithAppBarIOS => _availableheightWithAppBarIOS!;
  double get availableheightNoAppBar => _availableheightNoAppBar!;
  double get availableWidth => _availableWidth!;
  double get appBarHeight => _appBarHeight!;
  double get statusBarHeight => _statusBarHeight!;

  void appDimentionsInit(BuildContext context) {
    _appBarHeight = myAppBar.preferredSize.height;
    _statusBarHeight = MediaQuery.of(context).padding.top;
    _availableheightNoAppBar = MediaQuery.sizeOf(context).height - (_appBarHeight! + _statusBarHeight!);
    _availableheightWithAppBar = MediaQuery.sizeOf(context).height;
    _availableheightWithAppBarIOS = MediaQuery.sizeOf(context).height - MediaQuery.of(context).padding.bottom;
    _availableWidth = MediaQuery.sizeOf(context).width;
  }
}
