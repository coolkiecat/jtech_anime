import 'package:flutter/material.dart';
import 'package:jtech_anime_base/base.dart';

// 执行搜索回调
typedef SearchCallback = void Function(String keyword);

// 搜索记录删除回调
typedef RecordDeleteCallback = void Function(SearchRecord item);

/*
* 搜索条组件
* @author wuxubaiyang
* @Time 2023/7/11 16:35
*/
class SearchBarView extends StatelessWidget {
  // 搜索记录列表
  final ListValueChangeNotifier<SearchRecord> searchRecordList;

  // 搜索记录删除回调
  final RecordDeleteCallback recordDelete;

  // 搜索回调
  final SearchCallback search;

  // 加载状态管理
  final ValueChangeNotifier<bool> inSearching;

  // 动作按钮集合
  final List<Widget> actions;

  const SearchBarView({
    super.key,
    required this.searchRecordList,
    required this.recordDelete,
    required this.inSearching,
    required this.search,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: searchRecordList,
      builder: (_, searchRecords, ___) {
        return Autocomplete<SearchRecord>(
          optionsBuilder: (v) {
            final keyword = v.text.trim().toLowerCase();
            if (keyword.isEmpty) return [];
            return searchRecords.where(
              (e) => e.keyword.contains(keyword),
            );
          },
          fieldViewBuilder: _buildFieldView,
          displayStringForOption: (e) => e.keyword,
          optionsViewBuilder: _buildOptionsView,
          onSelected: (v) => search(v.keyword.trim()),
        );
      },
    );
  }

  // 构建搜索条输入框
  Widget _buildFieldView(BuildContext context, TextEditingController controller,
      FocusNode focusNode, VoidCallback _) {
    return Card(
      elevation: 0,
      color: kPrimaryColor.withOpacity(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: TextField(
          autofocus: true,
          onSubmitted: search,
          focusNode: focusNode,
          controller: controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintStyle: const TextStyle(color: Colors.black12),
            border: InputBorder.none,
            hintText: '嗖嗖嗖~',
            prefixIcon: IconButton(
              icon: const Icon(FontAwesomeIcons.arrowLeft),
              onPressed: () => router.pop(),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFieldViewSubmit(controller, focusNode),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建搜索条输入框的确认按钮
  Widget _buildFieldViewSubmit(
      TextEditingController controller, FocusNode focusNode) {
    return ValueListenableBuilder<bool>(
      valueListenable: inSearching,
      builder: (_, searching, __) {
        return AnimatedCrossFade(
          firstChild: IconButton(
            icon: const Icon(FontAwesomeIcons.magnifyingGlass),
            onPressed: () {
              search(controller.text.trim());
              focusNode.unfocus();
            },
          ),
          secondChild: const Padding(
            padding: EdgeInsets.only(right: 8),
            child: StatusBox(
              status: StatusBoxStatus.loading,
              animSize: 14,
            ),
          ),
          duration: const Duration(milliseconds: 100),
          crossFadeState:
              searching ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        );
      },
    );
  }

  // 构建搜索条选项
  Widget _buildOptionsView(
    BuildContext context,
    AutocompleteOnSelected<SearchRecord> onSelected,
    Iterable<SearchRecord> options,
  ) {
    return const SizedBox();
    // return Align(
    //   alignment: Alignment.topLeft,
    //   child: Material(
    //     color: Colors.transparent,
    //     child: Card(
    //       clipBehavior: Clip.antiAlias,
    //       margin: const EdgeInsets.only(left: 4, right: 30, top: 8),
    //       child: ListView.builder(
    //         shrinkWrap: true,
    //         padding: EdgeInsets.zero,
    //         itemCount: min(options.length, 5),
    //         itemBuilder: (_, i) {
    //           final item = options.elementAt(i);
    //           return _buildOptionsViewItem(item, () => onSelected(item));
    //         },
    //       ),
    //     ),
    //   ),
    // );
  }

  // 构建搜索补充条件子项
  // Widget _buildOptionsViewItem(SearchRecord item, VoidCallback onTap) {
  //   return ListTile(
  //     onTap: onTap,
  //     title: Text(item.keyword),
  //     contentPadding: const EdgeInsets.only(left: 18, right: 8),
  //     trailing: IconButton(
  //       icon: const Icon(FontAwesomeIcons.trashCan,
  //           color: Colors.black38, size: 18),
  //       onPressed: () => recordDelete(item),
  //     ),
  //   );
  // }
}
