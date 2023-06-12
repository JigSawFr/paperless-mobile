import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class DocumentView extends StatefulWidget {
  final Future<Uint8List> documentBytes;
  final String? title;
  const DocumentView({
    Key? key,
    required this.documentBytes,
    this.title,
  }) : super(key: key);

  @override
  State<DocumentView> createState() => _DocumentViewState();
}

class _DocumentViewState extends State<DocumentView> {
  int? _currentPage;
  int? _totalPages;
  PDFViewController? _controller;

  @override
  Widget build(BuildContext context) {
    final isInitialized =
        _controller != null && _currentPage != null && _totalPages != null;
    final canGoToNextPage = isInitialized && _currentPage! + 1 < _totalPages!;
    final canGoToPreviousPage = isInitialized && _currentPage! > 0;
    return Scaffold(
      appBar: AppBar(
        title: widget.title != null ? Text(widget.title!) : null,
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            Flexible(
              child: Row(
                children: [
                  IconButton.filled(
                    onPressed: canGoToPreviousPage
                        ? () {
                            _controller?.setPage(_currentPage! - 1);
                          }
                        : null,
                    icon: const Icon(Icons.arrow_left),
                  ),
                  const SizedBox(width: 16),
                  IconButton.filled(
                    onPressed: canGoToNextPage
                        ? () {
                            _controller?.setPage(_currentPage! + 1);
                          }
                        : null,
                    icon: const Icon(Icons.arrow_right),
                  ),
                ],
              ),
            ),
            if (_currentPage != null && _totalPages != null)
              Text(
                "${_currentPage! + 1}/$_totalPages",
                style: Theme.of(context).textTheme.labelLarge,
              ),
          ],
        ),
      ),
      body: FutureBuilder(
          future: widget.documentBytes,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return PDFView(
              pdfData: snapshot.data,
              defaultPage: 0,
              enableSwipe: true,
              fitPolicy: FitPolicy.BOTH,
              swipeHorizontal: true,
              onRender: (pages) {
                setState(() {
                  _currentPage = 0;
                  _totalPages = pages ?? -1;
                });
              },
              onPageChanged: (page, total) {
                setState(() {
                  _currentPage = page;
                  _totalPages = total;
                });
              },
              onViewCreated: (controller) {
                _controller = controller;
              },
              onError: (error) {
                print(error.toString());
              },
              onPageError: (page, error) {
                print('$page: ${error.toString()}');
              },
            );
          }),
    );
  }
}
