import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PaginationListView<T> extends StatefulWidget {
  const PaginationListView({
    Key? key,
    required this.getDocs,
    required this.fromDoc,
    required this.itemBuilder,
    required this.empty,
    this.separatorBuilder,
    this.shrinkWrap = false,
  }) : super(key: key);

  /// Main pagination function.
  ///
  /// Must return a future of a Firestore query snapshot that will be used to create the list's [T] objects
  final Future<QuerySnapshot<Map<String, dynamic>>> Function(DocumentSnapshot<Object?>? previousDoc) getDocs;

  /// Objects' builder function. must return [T] object
  final T Function(QueryDocumentSnapshot<Map<String, dynamic>> doc) fromDoc;

  /// What should be built incase there were no docs;
  ///
  /// happens when [getDocs] returns no documents at all.
  final Widget empty;

  /// The widget that will be built for [object] with [index] in the list.
  final Widget Function(BuildContext context, T object, int index) itemBuilder;

  /// The widget that seperates the objects' widgets
  final Widget Function(BuildContext, int)? separatorBuilder;

  final bool shrinkWrap;
  @override
  State<PaginationListView<T>> createState() => _PaginationListViewState<T>();
}

class _PaginationListViewState<T> extends State<PaginationListView<T>> {
  /// is loading notifications from Firestore.
  ///
  /// used to prevent multiple calls for Firestore.
  bool _isLoading = false;

  /// there is no more docs other than the one loaded
  ///
  /// defaults to `false` and turns `true` when [_getNotifications()] doesn't return any docs
  bool _noMoreDocs = false;
  List<T> objects = [];
  DocumentSnapshot<Object?>? previousDoc;

  Future<void> _getDocs() async {
    if (_isLoading) return;
    _isLoading = true;
    final result = await widget.getDocs(previousDoc);
    if (result.docs.isEmpty) {
      _noMoreDocs = true;
    } else {
      for (var doc in result.docs) {
        final object = widget.fromDoc(doc);
        objects.add(object);
      }
      previousDoc = result.docs.last;
    }
    _isLoading = false;
  }

  _refresh() {
    setState(() {
      objects.clear();
      _noMoreDocs = false;
      previousDoc = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getDocs(),
      builder: (context, snapshot) {
        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView.separated(
            shrinkWrap: widget.shrinkWrap,
            itemCount: objects.length + 1,
            separatorBuilder: widget.separatorBuilder ?? (context, index) => const Divider(),
            itemBuilder: (context, index) {
              // If there is no objects and no more docs
              if (_noMoreDocs && objects.isEmpty) {
                return widget.empty;
              }

              if (index >= objects.length) {
                if (!_noMoreDocs) {
                  // If at the end of the list and didn't reach the end of the list (!noMoreDocs)
                  // then call _getDocs() and setState when Done
                  _getDocs().then((value) => setState(() {}));
                }
                // Show loading bar or empty if the end of the list was reached (noMoreDocs)
                return ListTile(
                  title: _noMoreDocs ? null : const LinearProgressIndicator(),
                );
              }
              return widget.itemBuilder(context, objects[index], index);
            },
          ),
        );
      },
    );
  }
}
