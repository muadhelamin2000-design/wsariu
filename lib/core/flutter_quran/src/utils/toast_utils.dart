import 'package:fluttertoast/fluttertoast.dart';

class ToastUtils {
  Future<bool?> showToast(String msg, {ToastGravity? gravity, Toast? toastLength}) =>
      Fluttertoast.showToast(
        msg: msg,
        toastLength: toastLength ?? Toast.LENGTH_SHORT,
        gravity: gravity ?? ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        fontSize: 16.0,
      );

  Future<bool?> hideToast() => Fluttertoast.cancel();

  static final ToastUtils _instance = ToastUtils._internal();

  factory ToastUtils() {
    return _instance;
  }

  ToastUtils._internal();
}
