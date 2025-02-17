import 'package:flutter/material.dart';
import 'package:mobile/widget/source_import.dart';
import 'package:jtech_anime_base/base.dart';

/*
* 番剧解析源管理
* @author wuxubaiyang
* @Time 2023/8/30 17:27
*/
class AnimeSourcePage extends StatefulWidget {
  const AnimeSourcePage({super.key});

  @override
  State<StatefulWidget> createState() => _AnimeSourcePageState();
}

/*
* 番剧解析源管理-状态
* @author wuxubaiyang
* @Time 2023/8/30 17:27
*/
class _AnimeSourcePageState
    extends LogicState<AnimeSourcePage, _AnimeSourceLogic> {
  @override
  _AnimeSourceLogic initLogic() => _AnimeSourceLogic();

  @override
  Widget buildWidget(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('插件管理'),
      ),
      body: _buildAnimeSourceList(),
      floatingActionButton: FloatingActionButton(
        child: const Icon(FontAwesomeIcons.plus),
        onPressed: () => AnimeSourceImportSheet.show(
          context,
          title: const Text('扫码并导入插件'),
        ).then((source) {
          if (source != null) logic.controller.refreshValue();
        }),
      ),
    );
  }

  // 构建番剧解析源列表
  Widget _buildAnimeSourceList() {
    return SourceStreamView(
      builder: (_, snap) {
        final current = snap.data?.source;
        return CacheFutureBuilder<List<AnimeSource>>(
          controller: logic.controller,
          future: db.getAnimeSourceList,
          builder: (_, snap) {
            final animeSources = snap.data ?? [];
            return ListView.builder(
              shrinkWrap: true,
              itemCount: animeSources.length,
              padding: const EdgeInsets.only(bottom: kToolbarHeight * 1.5),
              itemBuilder: (_, i) {
                return _buildAnimeSourceListItem(animeSources[i], current);
              },
            );
          },
        );
      },
    );
  }

  // 构建番剧解析源列表项
  Widget _buildAnimeSourceListItem(AnimeSource item, AnimeSource? current) {
    final selected = current?.key == item.key;
    return ListTile(
      isThreeLine: true,
      title: Text(item.name),
      leading: ClipOval(
        child: Container(
          padding: const EdgeInsets.all(2),
          color: selected ? kPrimaryColor : null,
          child: AnimeSourceLogo(source: item, ratio: 20),
        ),
      ),
      subtitle: DefaultTextStyle(
        maxLines: 1,
        style: const TextStyle(color: Colors.black38),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(item.homepage),
            Row(
              children: [
                Text('v${item.version}'),
                if (item.proxy) ...[
                  const SizedBox(width: 8),
                  Icon(FontAwesomeIcons.globe, size: 12, color: kPrimaryColor),
                ],
                if (item.nsfw) ...[
                  const SizedBox(width: 8),
                  Icon(FontAwesomeIcons.skullCrossbones,
                      size: 12, color: kPrimaryColor),
                ],
              ],
            ),
          ],
        ),
      ),
      // trailing: TextButton(
      //   child: const Text('卸载'),
      //   onPressed: () => _showUninstallDialog(item),
      // ),
      onTap: () =>
          AnimeSourceImportSheet.showInfo(context, source: item).then((result) {
        if (result == null) return;
        SnackTool.showMessage(
            message: '已切换插件为 ${animeParser.currentSource?.name}');
      }),
    );
  }

  // 展示卸载提示弹窗
  // Future<void> _showUninstallDialog(AnimeSource item) {
  //   return MessageDialog.show(
  //     context,
  //     title: const Text('卸载'),
  //     content: Text('是否卸载插件 ${item.name}'),
  //     actionMiddle: TextButton(
  //       child: const Text('取消'),
  //       onPressed: () => router.pop(),
  //     ),
  //     actionRight: TextButton(
  //       child: const Text('删除'),
  //       onPressed: () async {
  //         final result = await animeParser.uninstallSource(item);
  //         if (result) logic.controller.refreshValue();
  //         router.pop();
  //       },
  //     ),
  //   );
  // }
}

/*
* 番剧解析源管理-逻辑
* @author wuxubaiyang
* @Time 2023/8/30 17:27
*/
class _AnimeSourceLogic extends BaseLogic {
  // 番剧解析源缓存控制器
  final controller = CacheFutureBuilderController<List<AnimeSource>>();
}
