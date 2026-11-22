import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_sliver_app_bar.dart';
import '../../recipes/models/recipe_image.dart';

Future<void> showChatImage(BuildContext context, RecipeImage image) =>
    showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (context) => Dialog.fullscreen(
        child: AppPageScaffold(
          backgroundColor: Colors.black,
          appBar: AppSliverAppBar(
            title: 'Ảnh',
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            onBackPressed: () => Navigator.of(context).pop(),
          ),
          body: InteractiveViewer(
            minScale: .5,
            maxScale: 5,
            child: Center(
              child: Image.network(
                image.url!,
                fit: BoxFit.contain,
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                semanticLabel: 'Ảnh trong cuộc trò chuyện',
                errorBuilder: (_, _, _) => const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIconsRegular.imageBroken,
                      color: Colors.white70,
                      size: 40,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Không tải được ảnh.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
