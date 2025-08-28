
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/manga_model.dart';
import '../utils/app_theme.dart';
import 'manga_card.dart';

class MangaGrid extends StatelessWidget {
  final List<Manga> mangaList;
  final ScrollController? scrollController;
  final bool isLoading;

  const MangaGrid({
    super.key,
    required this.mangaList,
    this.scrollController,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (mangaList.isEmpty) {
      return const Center(
        child: Text(
          'No manga found',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 18,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          MasonryGridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            itemCount: mangaList.length,
            itemBuilder: (context, index) {
              return MangaCard(manga: mangaList[index]);
            },
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
              ),
            ),
        ],
      ),
    );
  }
}
