import 'package:flutter/material.dart';

class Navigation {
  void goToScreen(BuildContext context, Widget Function(BuildContext context) pageName) {
    print('GO TO SCREEN >> $pageName');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: pageName,
      ),
    );
  }

  void goToScreenAndClearAll(BuildContext context, Widget Function(BuildContext context) pageName) {
    print('GO TO SCREEN >> $pageName');
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: pageName,
        ),
        (Route<dynamic> route) => false);
  }

  void goToScreenReplace(BuildContext context, Widget Function(BuildContext context) pageName) {
    print('GO TO SCREEN Replace >> $pageName');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: pageName,
      ),
    );
  }

  void goToScreenWithGoBack(BuildContext context, Widget Function(BuildContext context) pageName, dynamic futureOr) async {
    print('GO TO SCREEN WITH GO BACK >> $pageName');
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: pageName,
          ),
        )
        .then(futureOr);
  }

 

  // void showLoadingTextDialog(BuildContext context) {
  //   showDialog(barrierDismissible: false, context: context, builder: (context) => const LoadingTextDialog());
  // }

  void closeDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
}
