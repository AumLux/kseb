import 'package:flutter/widgets.dart';

/// A list whose data rows are built on demand (only what is on screen),
/// with optional fixed [header] and [footer] widgets around them.
///
/// Use instead of `ListView(children: [..., for (x in items) Row(x)])`,
/// which builds and lays out every row up front and janks on long lists.
class LazyListView extends StatelessWidget {
  const LazyListView({
    super.key,
    this.header = const [],
    required this.itemCount,
    required this.itemBuilder,
    this.footer = const [],
    this.padding,
    this.physics,
  });

  final List<Widget> header;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final List<Widget> footer;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: padding,
        physics: physics ?? const AlwaysScrollableScrollPhysics(),
        itemCount: header.length + itemCount + footer.length,
        itemBuilder: (context, i) {
          if (i < header.length) return header[i];
          i -= header.length;
          if (i < itemCount) return itemBuilder(context, i);
          return footer[i - itemCount];
        },
      );
}
