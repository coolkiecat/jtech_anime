import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:package_info_plus/package_info_plus.dart';
import 'date.dart';
import 'log.dart';

/*
* 工具方法
* @author wuxubaiyang
* @Time 2022/9/8 15:09
*/
class Tool {
  // 生成id
  static String genID({int? seed}) {
    final time = DateTime.now().millisecondsSinceEpoch;
    return md5('${time}_${Random(seed ?? time).nextDouble()}');
  }

  // 生成时间戳签名
  static String genDateSign() => DateTime.now().format(DatePattern.dateSign);

  // 获取屏幕宽度
  static double getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  // 获取屏幕高度
  static double getScreenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // 获取状态栏高度
  static double getStatusBarHeight(BuildContext context) =>
      MediaQuery.of(context).padding.top;

  // 获取应用名
  static Future<String> get appName async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.appName;
  }

  // 获取应用包名
  static Future<String> get packageName async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.packageName;
  }

  // 获取版本号
  static Future<String> get buildNumber async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
  }

  // 获取版本名
  static Future<String> get version async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  // 解析字符串格式的色值
  static Color parseColor(String colorString,
      [Color defaultColor = Colors.white]) {
    try {
      if (colorString.isEmpty) return defaultColor;
      // 解析16进制格式的色值 0xffffff
      if (colorString.contains(RegExp(r'#|0x'))) {
        String hexColor = colorString.replaceAll(RegExp(r'#|0x'), '');
        if (hexColor.length == 6) hexColor = 'ff$hexColor';
        return Color(int.parse(hexColor, radix: 16));
      }
      // 解析rgb格式的色值 rgb(0,0,0)
      if (colorString.toLowerCase().contains(RegExp(r'rgb(.*)'))) {
        String valuesString = colorString.substring(4, colorString.length - 1);
        List<String> values = valuesString.split(',');
        if (values.length == 3) {
          int red = int.parse(values[0].trim());
          int green = int.parse(values[1].trim());
          int blue = int.parse(values[2].trim());
          return Color.fromARGB(255, red, green, blue);
        }
        return defaultColor;
      }
    } catch (e) {
      LogTool.e('色值格式化失败', error: e);
    }
    return defaultColor;
  }
}

// 计算md5
String md5(String value) => crypto.md5.convert(utf8.encode(value)).toString();
