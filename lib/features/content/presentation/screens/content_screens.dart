import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../app/models/shop_models.dart';
import '../../../../app/state/shop_state.dart';
import '../../../../shared/widgets/shop_widgets.dart';

class StoresScreen extends StatelessWidget {
  const StoresScreen({super.key});
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Ubícanos',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Visítanos en nuestras tiendas de Lima.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        ...ShopScope.of(context).storeLocations.map(
          (store) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  store.district,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(store.address),
                Text(store.hours, style: Theme.of(context).textTheme.bodySmall),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(
                          text: '${store.address}, ${store.district}',
                        ),
                      );
                      if (context.mounted) {
                        feedback(context, 'Dirección copiada');
                      }
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copiar dirección'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Blog',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: ShopScope.of(context).articles
          .map(
            (article) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => BlogArticleScreen(article: article),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: SizedBox(
                        height: 160,
                        child: ShopImage(article.image),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${article.category.toUpperCase()} · ${article.readMinutes} min',
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.summary,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class BlogArticleScreen extends StatelessWidget {
  const BlogArticleScreen({super.key, required this.article});
  final BlogArticle article;
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Blog',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: SizedBox(height: 200, child: ShopImage(article.image)),
        ),
        const SizedBox(height: 16),
        Text(
          '${article.category.toUpperCase()} · ${article.readMinutes} min de lectura',
          style: const TextStyle(
            color: AppColors.green,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(article.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Text(article.body, style: const TextStyle(height: 1.5)),
      ],
    ),
  );
}
