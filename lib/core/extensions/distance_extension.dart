import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

extension DistanceExtension on num {
  Widget get height => SizedBox(height: toDouble().h);
  Widget get width => SizedBox(width: toDouble().w);
  Widget get isHeight => SizedBox(height: toDouble().h);
  Widget get isWidth => SizedBox(width: toDouble().w);
}
