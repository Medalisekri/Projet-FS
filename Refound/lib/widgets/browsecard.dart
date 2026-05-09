import 'package:flutter/material.dart';
import '../../../theme/apptheme.dart';
import '../../../models/itemmodel.dart';

class BrowseItemCard extends StatelessWidget {
  final ItemModel item;

  const BrowseItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/item-detail', arguments: item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: SizedBox(
                width: 100, height: 110,
                child: item.imageUrl.isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),

            // ── Info ────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(item.title,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                        ),
                        const SizedBox(width: 8),
                        _badge(),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Description
                    if (item.description.isNotEmpty)
                      Text(item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary
                                  .withOpacity(0.8))),

                    const SizedBox(height: 6),

                    // Location
                 Row(children: [
  const Icon(Icons.location_on_outlined,
      size: 13, color: AppColors.teal),   // ← teal instead of gray
  const SizedBox(width: 3),
  Expanded(
    child: Text(
      item.location,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary),
    ),
  ),
]),

// Date row
Row(children: [
  const Icon(Icons.calendar_today_outlined,
      size: 13, color: AppColors.teal),   // ← teal instead of gray
  const SizedBox(width: 3),
  Text(
    item.date,   // ← now shows "18 Mar 2026" cleanly
    style: const TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary),
  ),
]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: item.isLost
          ? const Color(0xFFFEF3C7)
          : const Color(0xFFE1F5EE),
      child: Center(
        child: Icon(
          item.isLost
              ? Icons.search_off_rounded
              : Icons.check_circle_outline_rounded,
          size: 32,
          color: item.isLost
              ? const Color(0xFF854F0B)
              : const Color(0xFF0F6E56),
        ),
      ),
    );
  }

  Widget _badge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
    );
  }
}