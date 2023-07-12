import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:jtech_anime/model/anime.dart';
import 'package:jtech_anime/widget/image.dart';

/*
* 动漫详情信息
* @author wuxubaiyang
* @Time 2023/7/12 10:00
*/
class AnimeDetailInfo extends StatelessWidget {
  // 番剧信息
  final AnimeModel animeInfo;

  const AnimeDetailInfo({super.key, required this.animeInfo});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildInfoBackground(context),
          _buildInfo(context),
        ],
      ),
    );
  }

  // 构建背景图
  Widget _buildInfoBackground(BuildContext context) {
    return Blur(
      blur: 14,
      blurColor: Colors.white,
      child: Image.network(
        animeInfo.cover,
        fit: BoxFit.cover,
        width: double.maxFinite,
        height: double.maxFinite,
      ),
    );
  }

  // 文本样式
  final textStyle = const TextStyle(
    color: Colors.black54,
    fontSize: 14,
  );

  // 间距
  final padding = const EdgeInsets.symmetric(horizontal: 14);

  // 构建信息部分
  Widget _buildInfo(BuildContext context) {
    return SafeArea(
      child: DefaultTextStyle(
        maxLines: 1,
        style: textStyle,
        overflow: TextOverflow.ellipsis,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackButton(),
            Padding(
              padding: padding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCover(context),
                  const SizedBox(width: 14),
                  Expanded(child: _buildInfoText(context)),
                ],
              ),
            ),
            Padding(
              padding: padding.copyWith(bottom: 0, top: 14),
              child: Text('简介：${animeInfo.intro}', maxLines: 3),
            ),
          ],
        ),
      ),
    );
  }

  // 构建封面
  Widget _buildInfoCover(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ImageView.net(animeInfo.cover,
          width: 110, height: 150, fit: BoxFit.cover),
    );
  }

  // 构建消息文本部分
  _buildInfoText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          animeInfo.name,
          style: textStyle.copyWith(
            color: Colors.black,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 14),
        Text('更新时间：${animeInfo.updateTime}'),
        const SizedBox(height: 4),
        Text(animeInfo.status),
        const SizedBox(height: 4),
        Text('类型：${animeInfo.types.join('/')}'),
        const SizedBox(height: 4),
        Text('地区：${animeInfo.region}'),
      ],
    );
  }
}
