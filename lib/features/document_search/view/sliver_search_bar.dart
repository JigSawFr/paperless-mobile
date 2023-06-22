import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/delegate/customizable_sliver_persistent_header_delegate.dart';
import 'package:paperless_mobile/features/document_search/view/document_search_bar.dart';

class SliverSearchBar extends StatelessWidget {
  final bool floating;
  final bool pinned;
  const SliverSearchBar({
    super.key,
    this.floating = false,
    this.pinned = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      sliver: SliverPersistentHeader(
        floating: floating,
        pinned: pinned,
        delegate: CustomizableSliverPersistentHeaderDelegate(
          minExtent: kToolbarHeight,
          maxExtent: kToolbarHeight,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: const DocumentSearchBar(),
          ),
        ),
      ),
    );
  }
}
