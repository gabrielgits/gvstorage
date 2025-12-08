import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../models/asset.dart';
import 'asset_card.dart';

/// Responsive asset grid layout
class AssetGrid extends StatelessWidget {
  final List<Asset> assets;
  final Function(Asset)? onAssetTap;
  final int? crossAxisCount;
  final double? childAspectRatio;

  const AssetGrid({
    super.key,
    required this.assets,
    this.onAssetTap,
    this.crossAxisCount,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = crossAxisCount ?? _calculateColumns(constraints.maxWidth);
        final aspectRatio = childAspectRatio ?? 0.72;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppConstants.gridSpacing,
            crossAxisSpacing: AppConstants.gridSpacing,
            childAspectRatio: aspectRatio,
          ),
          itemCount: assets.length,
          itemBuilder: (context, index) {
            final asset = assets[index];
            return AssetCard(
              asset: asset,
              onTap: () => onAssetTap?.call(asset),
            );
          },
        );
      },
    );
  }

  int _calculateColumns(double width) {
    if (width >= AppConstants.breakpointDesktop) {
      return AppConstants.gridColumnsDesktop;
    } else if (width >= AppConstants.breakpointTablet) {
      return AppConstants.gridColumnsTablet;
    }
    return AppConstants.gridColumnsMobile;
  }
}

/// Sliver version of AssetGrid for use in CustomScrollView
class SliverAssetGrid extends StatelessWidget {
  final List<Asset> assets;
  final Function(Asset)? onAssetTap;
  final int? crossAxisCount;
  final double? childAspectRatio;

  const SliverAssetGrid({
    super.key,
    required this.assets,
    this.onAssetTap,
    this.crossAxisCount,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = crossAxisCount ?? _calculateColumns(constraints.crossAxisExtent);
        final aspectRatio = childAspectRatio ?? 0.72;

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppConstants.gridSpacing,
            crossAxisSpacing: AppConstants.gridSpacing,
            childAspectRatio: aspectRatio,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final asset = assets[index];
              return AssetCard(
                asset: asset,
                onTap: () => onAssetTap?.call(asset),
              );
            },
            childCount: assets.length,
          ),
        );
      },
    );
  }

  int _calculateColumns(double width) {
    if (width >= AppConstants.breakpointDesktop) {
      return AppConstants.gridColumnsDesktop;
    } else if (width >= AppConstants.breakpointTablet) {
      return AppConstants.gridColumnsTablet;
    }
    return AppConstants.gridColumnsMobile;
  }
}
