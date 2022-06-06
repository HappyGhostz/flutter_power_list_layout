import 'package:flutter/material.dart';

class CustomSliverList extends SliverList {
  const CustomSliverList({
    Key? key,
    required SliverChildDelegate delegate,
  }) : super(key: key, delegate: delegate);

  @override
  SliverMultiBoxAdaptorElement createElement() {
    // TODO: implement createElement
    return super.createElement();
  }
}
