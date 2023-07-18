import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jtech_anime/common/notifier.dart';

/*
* 自定义视频播放器，分层基类
* @author wuxubaiyang
* @Time 2023/7/17 15:56
*/
mixin class CustomVideoPlayerLayer {
  // 显示隐藏的动画间隔
  final animeDuration = const Duration(milliseconds: 100);

  // 切换显示状态
  void toggleShow(ValueChangeNotifier<bool> notifier) =>
      notifier.value ? notifier.setValue(false) : show(notifier);

  // 展示组件并在一定时间后隐藏
  void show(ValueChangeNotifier<bool> notifier,
      {Duration throttleDelay = const Duration(milliseconds: 100)}) {
    _throttle(() {
      notifier.setValue(true);
      _debounce(() => notifier.setValue(false));
    }, throttleDelay);
  }

  // 构建可控显示隐藏组件
  Widget buildAnimeShow(ValueChangeNotifier<bool> notifier, Widget child) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (_, show, __) {
        return AnimatedOpacity(
          opacity: show ? 1 : 0,
          duration: animeDuration,
          child: child,
        );
      },
    );
  }

  // 记录需要复现的事件
  List<ValueChangeNotifier<bool>>? _reappearList;

  // 展示突出组件（展示突出组件并隐藏其他组件）
  void showProtrudeView(ValueChangeNotifier<bool> notifier,
      List<ValueChangeNotifier<bool>> hides, bool show) {
    // 展示重点组件
    notifier.setValue(show);
    // 当隐藏重点组件的时候，则显示需要复现的组件
    if (show && _reappearList == null) {
      _reappearList =
          hides.where((e) => e.value).map((e) => e..setValue(false)).toList();
    } else if (!show && _reappearList != null) {
      _reappearList?.forEach(this.show);
      _reappearList = null;
    }
  }

  // 防抖
  Timer? _debounceTimer;

  // 防抖
  void _debounce(Function func,
      [Duration delay = const Duration(milliseconds: 3000)]) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }
    _debounceTimer = Timer(delay, () => func.call());
  }

  // 节流
  Timer? _throttleTimer;

  // 节流
  void _throttle(Function func,
      [Duration delay = const Duration(milliseconds: 2000)]) {
    if (_throttleTimer != null) return;
    _throttleTimer = Timer(delay, () {
      _throttleTimer?.cancel();
      _throttleTimer = null;
    });
    func.call();
  }
}
