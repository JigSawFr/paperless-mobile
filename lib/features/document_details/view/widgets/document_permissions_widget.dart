import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';

class DocumentPermissionsWidget extends StatefulWidget {
  final DocumentModel document;
  const DocumentPermissionsWidget({super.key, required this.document});

  @override
  State<DocumentPermissionsWidget> createState() =>
      _DocumentPermissionsWidgetState();
}

class _DocumentPermissionsWidgetState extends State<DocumentPermissionsWidget> {
  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(
      child: Placeholder(),
    );
  }
}
