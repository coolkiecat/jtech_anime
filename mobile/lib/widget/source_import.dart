import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/widget/qr_code/sheet.dart';
import 'package:jtech_anime_base/base.dart';

/*
* 番剧解析源导入sheet
* @author wuxubaiyang
* @Time 2023/8/31 17:09
*/
class AnimeSourceImportSheet extends StatefulWidget {
  // 获取到的解析源
  final AnimeSource source;

  // 是否为查看模式
  final bool importMode;

  const AnimeSourceImportSheet({
    super.key,
    required this.source,
    this.importMode = true,
  });

  static Future<AnimeSource?> show(
    BuildContext context, {
    Widget? title,
  }) async {
    return QRCodeSheet.show(context, title: title).then((result) {
      if (result == null) return null;
      final source = AnimeSource.from(jsonDecode(result));
      return showModalBottomSheet<AnimeSource>(
        context: context,
        builder: (_) {
          return AnimeSourceImportSheet(
            source: source,
          );
        },
      );
    });
  }

  static Future<AnimeSource?> showInfo(BuildContext context,
      {required AnimeSource source}) async {
    return showModalBottomSheet<AnimeSource>(
      context: context,
      builder: (_) {
        return AnimeSourceImportSheet(
          importMode: false,
          source: source,
        );
      },
    );
  }

  @override
  State<StatefulWidget> createState() => _AnimeSourceImportSheetState();
}

/*
* 番剧解析源导入sheet-状态
* @author wuxubaiyang
* @Time 2023/8/31 17:10
*/
class _AnimeSourceImportSheetState extends State<AnimeSourceImportSheet> {
  // 支持得方法集合
  final supportFunctions = ListValueChangeNotifier<AnimeParserFunction>.empty();

  // 缺少的必须方法集合
  final missRequiredFunctions =
      ListValueChangeNotifier<AnimeParserFunction>.empty();

  // 解析源js插件内容
  final jsPlugin = ValueChangeNotifier<String>('');

  @override
  void initState() {
    super.initState();
    // 发起请求获取插件js文件
    _includeJSPlugin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8)
            .copyWith(bottom: kToolbarHeight * 1.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSourceInfo(),
            const SizedBox(height: 14),
            _buildSourceFunctions(),
          ],
        ),
      ),
      floatingActionButton: _buildSourceImportFAB(),
    );
  }

  // 构建解析源基础信息
  Widget _buildSourceInfo() {
    final source = widget.source;
    return DefaultTextStyle(
      style: const TextStyle(color: Colors.black54, fontSize: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          AnimeSourceLogo(source: source, ratio: 40),
          const SizedBox(height: 14),
          Text('${source.name} · ${source.key}',
              style: const TextStyle(fontSize: 22, color: Colors.black)),
          TextButton(
            onPressed: () => launchUrl(Uri.parse(source.homepage)),
            child: Text(source.homepage),
          ),
          Text(source.lastEditDate.format(DatePattern.fullDateZH)),
          const SizedBox(height: 4),
          Text('v${source.version}'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (source.proxy)
                const Icon(FontAwesomeIcons.globe, size: 16, color: Colors.red),
              if (source.nsfw) ...[
                const SizedBox(width: 8),
                const Icon(FontAwesomeIcons.skullCrossbones,
                    size: 16, color: Colors.red),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // 构建当前类所支持得方法集合
  Widget _buildSourceFunctions() {
    return ValueListenableBuilder2<List<AnimeParserFunction>,
        List<AnimeParserFunction>>(
      first: supportFunctions,
      second: missRequiredFunctions,
      builder: (_, functions, missFunctions, __) {
        if (functions.isEmpty && missFunctions.isEmpty) {
          return const Center(
            child: StatusBox(
              status: StatusBoxStatus.loading,
              animSize: 30,
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(functions.length, (i) {
                final item = functions[i];
                return RawChip(
                  side: BorderSide.none,
                  label: Text(item.functionNameCN),
                  backgroundColor: kSecondaryColor.withOpacity(0.2),
                );
              }),
            ),
            if (missFunctions.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(missFunctions.length, (i) {
                  final item = missFunctions[i];
                  return RawChip(
                    side: BorderSide.none,
                    backgroundColor: Colors.red,
                    label: Text(item.functionNameCN),
                    labelStyle: const TextStyle(color: Colors.white),
                    avatar: const Icon(FontAwesomeIcons.triangleExclamation,
                        color: Colors.white, size: 16),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }

  // 构建解析源导入fab
  Widget _buildSourceImportFAB() {
    return FloatingActionButton.extended(
      icon: Icon(
          widget.importMode
              ? FontAwesomeIcons.fileImport
              : FontAwesomeIcons.repeat,
          size: 24),
      extendedTextStyle: const TextStyle(fontSize: 14),
      label: Text(widget.importMode ? '导入' : '切换'),
      onPressed: _importJSPlugin,
    );
  }

  // 导入js插件
  Future<void> _includeJSPlugin() async {
    try {
      final fileUri = widget.source.fileUri;
      String? jsContent;
      if (fileUri.startsWith('http')) {
        final resp = await Dio().get(fileUri);
        if (resp.statusCode != 200) throw Exception('插件下载失败，请重试');
        jsContent = resp.data;
      } else if (fileUri.startsWith('asset')) {
        jsContent = await rootBundle.loadString(fileUri);
      } else {
        final file = File(fileUri);
        jsContent = await file.readAsString();
      }
      if (jsContent == null) throw Exception('js插件加载失败');
      // 验证已存在方法
      final jsRuntime = JSRuntime();
      final functionMap = {},
          functions = [],
          requiredFunctions = <AnimeParserFunction>[];
      for (final fun in AnimeParserFunction.values) {
        final key = fun.functionName;
        functions.add('$key: typeof $key === "function"');
        functionMap[key] = fun;
        if (fun.required) requiredFunctions.add(fun);
      }
      final result = await jsRuntime.eval('''
            $jsContent
            function doJSFunction() {
                return JSON.stringify({
                    ${functions.join(',')}
                })
            }
            doJSFunction()
      ''');
      final results = <String, bool>{...jsonDecode(result)};
      // 计算得出支持方法与缺少的必须方法
      supportFunctions.setValue(results.keys
          .where((key) => results[key] ?? false)
          .map<AnimeParserFunction>((key) => functionMap[key])
          .toList());
      missRequiredFunctions.setValue(requiredFunctions.where((e) {
        return !supportFunctions.contains(e);
      }).toList());
      jsPlugin.setValue(jsContent);
    } catch (e) {
      LogTool.e('导入js插件失败', error: e);
      SnackTool.showMessage(message: '插件下载失败，请重试');
    }
  }

  // 导入js插件
  Future<void> _importJSPlugin() async {
    if (jsPlugin.value.isEmpty) {
      SnackTool.showMessage(message: '请等待插件加载完成~');
      return;
    }
    if (missRequiredFunctions.isNotEmpty) {
      SnackTool.showMessage(message: '缺少必须方法，该插件无效');
      return;
    }
    if (widget.importMode) {
      // 导入模式则执行插件导入
      final functions = supportFunctions.value.map((e) => e.name).toList();
      final result = await Loading.show(
        loadFuture: animeParser.importAnimeSource(
          widget.source..functions = functions,
        ),
      );
      if (result == null) {
        SnackTool.showMessage(message: '插件导入失败');
        return;
      }
      router.pop(result);
    } else {
      final result = await animeParser.changeSource(widget.source);
      if (result) router.pop(widget.source);
    }
  }
}
