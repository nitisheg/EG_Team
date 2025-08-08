import 'package:flutter/material.dart';
import 'package:flutterquiz/commons/widgets/custom_image.dart';

class LearnAndExploreCard extends StatelessWidget {
  const LearnAndExploreCard({
    required this.title,
    required this.desc,
    required this.img,
    super.key,
    this.onTap,
  });

  final String title;
  final String desc;
  final String img;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 161,
        padding: const EdgeInsets.only(top: 8, left: 1, right: 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: QImage(
                  imageUrl: img,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6C7278), // Gray 600
              ),
            ),
          ],
        ),
      ),
    );
  }
}
