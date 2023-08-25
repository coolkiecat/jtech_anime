import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jtech_anime/common/logic.dart';
import 'package:jtech_anime/common/notifier.dart';
import 'package:jtech_anime/common/route.dart';
import 'package:jtech_anime/manage/db.dart';
import 'package:jtech_anime/manage/anime_parser/parser.dart';
import 'package:jtech_anime/manage/router.dart';
import 'package:jtech_anime/model/anime.dart';
import 'package:jtech_anime/model/database/filter_select.dart';
import 'package:jtech_anime/model/time_table.dart';
import 'package:jtech_anime/page/home/filter.dart';
import 'package:jtech_anime/tool/loading.dart';
import 'package:jtech_anime/tool/snack.dart';
import 'package:jtech_anime/tool/version.dart';
import 'package:jtech_anime/widget/image.dart';
import 'package:jtech_anime/widget/refresh/refresh_view.dart';
import 'package:jtech_anime/widget/status_box.dart';

/*
* 首页
* @author wuxubaiyang
* @Time 2023/7/6 10:03
*/
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

/*
* 首页-状态
* @author wuxubaiyang
* @Time 2023/7/6 10:03
*/
class _HomePageState extends LogicState<HomePage, _HomeLogic>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // 时间轴tab控制器
  late TabController timetableTabController = TabController(
      length: 7, vsync: this, initialIndex: DateTime.now().weekday - 1);

  @override
  _HomeLogic initLogic() => _HomeLogic();

  @override
  void initState() {
    super.initState();
    // 初始化加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 检查版本更新
      AppVersionTool.check(context);
    });
  }

  @override
  Widget buildWidget(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: logic.showChildIndex,
      builder: (_, childIndex, __) {
        return AnimeFilterConfigMenu(
          complete: () => Loading.show(
            loadFuture: logic.loadAnimeList(false),
          )?.then((_) => logic.animeController.jumpTo(0)),
          filterConfig: logic.filterSelect,
          filterSelect: logic.selectFilterConfig,
          visible: childIndex == 0,
          body: Scaffold(
            appBar: AppBar(
              title: _buildSearchButton(),
              actions: _getAppbarActions(context, childIndex),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: [
                  _buildFilterChips(),
                  _buildTimetableTabBar(),
                ][childIndex],
              ),
            ),
            body: AnimatedCrossFade(
              firstChild: _buildAnimeList(),
              secondChild: _buildTimetableTabView(),
              duration: const Duration(milliseconds: 150),
              crossFadeState: [
                CrossFadeState.showFirst,
                CrossFadeState.showSecond,
              ][childIndex],
              layoutBuilder:
                  (topChild, topChildKey, bottomChild, bottomChildKey) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Positioned.fill(
                      key: bottomChildKey,
                      child: bottomChild,
                    ),
                    Positioned.fill(
                      key: topChildKey,
                      child: topChild,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  // 构建搜索按钮
  Widget _buildSearchButton() {
    const color = Colors.black38;
    const textStyle = TextStyle(color: color, fontSize: 16);
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ElevatedButton(
        child: const Row(
          children: [
            Icon(FontAwesomeIcons.magnifyingGlass, color: color, size: 18),
            SizedBox(width: 8),
            Text('嗖~', style: textStyle),
          ],
        ),
        onPressed: () => router.pushNamed(RoutePath.search),
      ),
    );
  }

  // 获取标题栏动作按钮集合
  List<Widget> _getAppbarActions(BuildContext context, int childIndex) {
    return [
      IconButton(
        icon: const Icon(FontAwesomeIcons.heart),
        onPressed: () => router.pushNamed(RoutePath.collect),
      ),
      IconButton(
        icon: const Icon(FontAwesomeIcons.clockRotateLeft),
        onPressed: () => router.pushNamed(RoutePath.record),
      ),
      IconButton(
        icon: const Icon(FontAwesomeIcons.download),
        onPressed: () => router.pushNamed(RoutePath.download),
      ),
      AnimatedRotation(
        turns: childIndex == 1 ? 0.5 : 1,
        duration: const Duration(milliseconds: 200),
        child: IconButton(
          icon: const Icon(FontAwesomeIcons.handPointRight),
          onPressed: () => logic.showChildIndex.setValue(childIndex ^ 1),
        ),
      ),
    ];
  }

  // 构建番剧过滤配置组件
  Widget _buildFilterChips() {
    return ValueListenableBuilder<Map<String, FilterSelect>>(
      valueListenable: logic.filterSelect,
      builder: (_, filterMap, __) {
        final tempFilter = filterMap.isNotEmpty
            ? filterMap
            : {
                'default': FilterSelect()
                  ..parentName = '默认'
                  ..name = '全部'
              };
        return Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: List.generate(tempFilter.length, (i) {
                final item = tempFilter.values.elementAt(i);
                final text = '${item.parentName} · ${item.name}';
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: RawChip(label: Text(text)),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  // 周/天换算表
  final _weekdayMap = <IconData, String>{
    FontAwesomeIcons.faceDizzy: '周一',
    FontAwesomeIcons.faceFrown: '周二',
    FontAwesomeIcons.faceFlushed: '周三',
    FontAwesomeIcons.faceGrimace: '周四',
    FontAwesomeIcons.faceGrinStars: '周五',
    FontAwesomeIcons.faceLaughWink: '周六',
    FontAwesomeIcons.faceSadTear: '周日',
  };

  // 构建时间轴tabBar
  PreferredSizeWidget _buildTimetableTabBar() {
    return TabBar(
      isScrollable: true,
      controller: timetableTabController,
      tabs: List.generate(timetableTabController.length, (i) {
        final item = _weekdayMap.entries.elementAt(i);
        return Tab(
          child: Row(
            children: [
              Text(item.value),
              const SizedBox(width: 4),
              Icon(item.key, size: 14),
            ],
          ),
        );
      }),
    );
  }

  // 构建时间轴tabView
  Widget _buildTimetableTabView() {
    return ValueListenableBuilder<TimeTableModel?>(
      valueListenable: logic.timetableDataList,
      builder: (_, timeTable, __) {
        if (timeTable == null) return _buildEmpty();
        return TabBarView(
          controller: timetableTabController,
          children: List.generate(timetableTabController.length, (i) {
            final items = timeTable.getAnimeListByWeekday(i);
            return ListView.builder(
              primary: false,
              itemCount: items.length,
              padding: EdgeInsets.zero,
              itemBuilder: (_, i) {
                final item = items[i];
                final updateIcon = item.isUpdate
                    ? const Icon(FontAwesomeIcons.seedling,
                        color: Colors.green, size: 18)
                    : null;
                return ListTile(
                  dense: true,
                  trailing: updateIcon,
                  title: Text(item.name),
                  subtitle: Text(item.status),
                  onTap: () => logic.goDetail(AnimeModel.from({
                    'name': item.name,
                    'url': item.url,
                    'status': item.status,
                  })),
                );
              },
            );
          }),
        );
      },
    );
  }

  // 构建番剧列表
  Widget _buildAnimeList() {
    return ValueListenableBuilder<List<AnimeModel>>(
      valueListenable: logic.animeList,
      builder: (_, animeList, __) {
        return CustomRefreshView(
          enableRefresh: true,
          enableLoadMore: true,
          initialRefresh: true,
          onRefresh: (loadMore) => logic.loadAnimeList(loadMore),
          child: Stack(
            children: [
              if (animeList.isEmpty)
                const Center(
                  child: StatusBox(
                    animSize: 34,
                    status: StatusBoxStatus.empty,
                    title: Text('下拉试试看~'),
                  ),
                ),
              GridView.builder(
                itemCount: animeList.length,
                padding: const EdgeInsets.all(8),
                controller: logic.animeController,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  mainAxisExtent: 190,
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (_, i) {
                  final item = animeList[i];
                  return _buildAnimeListItem(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 构建番剧列表子项
  Widget _buildAnimeListItem(AnimeModel item) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned.fill(
                    child: ImageView.net(item.cover, fit: BoxFit.cover),
                  ),
                  Container(
                    width: double.maxFinite,
                    color: Colors.black.withOpacity(0.6),
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Text(
                      item.status,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      onTap: () => logic.goDetail(item),
    );
  }

  // 构建空内容
  Widget _buildEmpty() {
    return const Center(
      child: StatusBox(
        status: StatusBoxStatus.empty,
      ),
    );
  }
}

/*
* 首页-逻辑
* @author wuxubaiyang
* @Time 2023/7/6 10:03
*/
class _HomeLogic extends BaseLogic {
  // 番剧列表
  final animeList = ListValueChangeNotifier<AnimeModel>.empty();

  // 时间轴数据
  final timetableDataList = ValueChangeNotifier<TimeTableModel?>(null);

  // 记录过滤条件
  final filterSelect = MapValueChangeNotifier<String, FilterSelect>.empty();

  // 首页展示内容下标
  final showChildIndex = ValueChangeNotifier<int>(0);

  // 动漫列表滚动控制器
  final animeController = ScrollController();

  // 维护分页页码
  int _pageIndex = 1;

  // 维护分页数据量
  final _pageSize = 25;

  @override
  void init() {
    super.init();
    // 获取过滤条件
    _loadFilterConfig();
    // 加载时间轴数据
    _loadTimetableDataList();
  }

  // 加载番剧列表
  Future<void> loadAnimeList(bool loadMore) async {
    if (isLoading) return;
    try {
      loading.setValue(true);
      final source = animeParser.currentSource;
      if (source == null) throw Exception('数据源不存在');
      final filters = await db.getFilterSelectList(source);
      final filterSelect =
          filters.asMap().map((_, v) => MapEntry(v.key, v.value));
      final pageIndex = loadMore ? _pageIndex + 1 : 1;
      final result = await animeParser.loadHomeList(
        pageIndex: pageIndex,
        pageSize: _pageSize,
        filterSelect: filterSelect,
      );
      loadMore ? animeList.addValues(result) : animeList.setValue(result);
      if (loadMore && result.isEmpty) {
        SnackTool.showMessage(message: '没有更多番剧了~');
      }
      _pageIndex = pageIndex;
    } catch (e) {
      SnackTool.showMessage(message: '番剧加载失败，请重试~');
    } finally {
      loading.setValue(false);
    }
  }

  // 加载时间轴数据
  Future<void> _loadTimetableDataList() async {
    final result = await animeParser.getTimeTable();
    timetableDataList.setValue(result);
  }

  // 加载过滤条件配置
  Future<void> _loadFilterConfig() async {
    final source = animeParser.currentSource;
    if (source == null) return;
    final result = await db.getFilterSelectList(source);
    filterSelect.setValue(result.asMap().map<String, FilterSelect>(
          (_, v) => MapEntry(_genFilterKey(v), v),
        ));
  }

  // 选择过滤条件
  Future<void> selectFilterConfig(
      bool selected, FilterSelect item, int maxSelected) async {
    if (selected) {
      final result = await db.addFilterSelect(item, maxSelected);
      if (result != null) {
        final temp = filterSelect.value;
        if (maxSelected == 1) {
          temp.removeWhere((_, v) => v.key == item.key);
        }
        filterSelect.setValue({
          ...temp,
          _genFilterKey(result): result,
        });
      }
    } else {
      final result = await db.removeFilterSelect(item.id);
      if (result) filterSelect.removeValue(_genFilterKey(item));
    }
  }

  // 生成过滤条件唯一key
  String _genFilterKey(FilterSelect item) => '${item.key}${item.value}';

  // 跳转到详情页
  Future<void>? goDetail(AnimeModel item) {
    return router.pushNamed(
      RoutePath.animeDetail,
      arguments: {'animeDetail': item},
    );
  }
}
