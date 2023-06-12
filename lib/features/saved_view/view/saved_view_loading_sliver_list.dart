import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/widgets/shimmer_placeholder.dart';

class SavedViewLoadingSliverList extends StatelessWidget {
  const SavedViewLoadingSliverList({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemBuilder: (context, index) => ShimmerPlaceholder(
        child: ListTile(
          title: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 300,
              height: 14,
              color: Colors.white,
            ),
          ),
          subtitle: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 150,
              height: 12,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
