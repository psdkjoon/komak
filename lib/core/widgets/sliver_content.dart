import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:komak/core/theme/app_spacing.dart';

class SliverContent extends StatelessWidget {
  const SliverContent({
    super.key,
    required this.sliver,
    this.maxWidth = AppLayout.contentMaxWidth,
  });

  final Widget sliver;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (BuildContext context, SliverConstraints constraints) {
        final double gutter =
            AppLayout.gutterFor(constraints.crossAxisExtent, maxWidth);
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          sliver: sliver,
        );
      },
    );
  }
}

class SliverBox extends StatelessWidget {
  const SliverBox({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SliverContent(
      maxWidth: maxWidth,
      sliver: SliverToBoxAdapter(child: child),
    );
  }
}

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    super.key,
    required this.children,
    this.maxWidth = AppLayout.readableMaxWidth,
    this.bottomPadding = AppSpacing.xxl,
  });

  final List<Widget> children;
  final double maxWidth;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverContent(
          maxWidth: maxWidth,
          sliver: SliverList(delegate: SliverChildListDelegate(children)),
        ),
        SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
      ],
    );
  }
}
