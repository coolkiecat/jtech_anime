import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:jtech_anime/widget/refresh/controller.dart';

// 异步刷新回调
typedef AsyncRefreshCallback = Future<void> Function(bool loadMore);

/*
* 自定义刷新组件
* @author wuxubaiyang
* @Time 2023/7/14 9:13
*/
class CustomRefreshView extends StatefulWidget {
  // 子元素
  final Widget child;

  // 是否启用下拉刷新
  final bool enableRefresh;

  // 是否启用上拉加载
  final bool enableLoadMore;

  // 异步加载回调
  final AsyncRefreshCallback onRefresh;

  // 是否初始化加载更多
  final bool initialRefresh;

  // 刷新组件控制器
  final CustomRefreshController controller;

  CustomRefreshView({
    super.key,
    required this.child,
    required this.onRefresh,
    this.enableRefresh = true,
    this.enableLoadMore = false,
    this.initialRefresh = false,
    CustomRefreshController? controller,
  }) : controller = controller ?? CustomRefreshController();

  @override
  State<StatefulWidget> createState() => _CustomRefreshViewState();
}

/*
* 自定义刷新组件-状态
* @author wuxubaiyang
* @Time 2023/7/14 9:15
*/
class _CustomRefreshViewState extends State<CustomRefreshView>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    // 初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 判断是否启用初始化加载
      if (widget.initialRefresh) widget.controller.startRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final onRefresh =
        widget.enableRefresh ? () => widget.onRefresh(false) : null;
    final onloadMore =
        widget.enableLoadMore ? () => widget.onRefresh(true) : null;
    return EasyRefresh(
      onLoad: onloadMore,
      onRefresh: onRefresh,
      controller: widget.controller.controller,
      child: widget.child,
    );
  }
}
