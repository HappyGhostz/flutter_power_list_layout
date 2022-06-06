import 'package:flutter/material.dart';

class CustomSliverChildBuilderDelegate extends SliverChildBuilderDelegate {
  CustomSliverChildBuilderDelegate(NullableIndexedWidgetBuilder builder, {required this.customChildCount}) : super(builder);

  final CustomChildCount? customChildCount;

  @override
  int? get childCount => customChildCount != null ? customChildCount!.childrenCount : (childCount ?? 0);
}

class CustomChildCount {
  int childrenCount = 0;
}
