import 'package:flutter/material.dart';
import 'package:refound/theme/apptheme.dart';
import 'package:refound/models/itemmodel.dart';

class ListingCard extends StatelessWidget {
  final ItemModel item;

  const ListingCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/item-detail',
          arguments: item),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          // Icon
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: item.isLost
                  ? const Color(0xFFFEF3C7)
                  : const Color(0xFFE1F5EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.isLost
                  ? Icons.search_off_rounded
                  : Icons.check_circle_outline_rounded,
              color: item.isLost
                  ? const Color(0xFF854F0B)
                  : const Color(0xFF0F6E56),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(item.location,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: item.isLost
                  ? const Color(0xFFFCEBEB)
                  : const Color(0xFFE1F5EE),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.isLost ? 'Lost' : 'Found',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: item.isLost
                    ? const Color(0xFFA32D2D)
                    : const Color(0xFF0F6E56),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}