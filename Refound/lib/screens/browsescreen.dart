import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/apptheme.dart';
import '../../../models/itemmodel.dart';
import '../widgets/browsecard.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _db            = FirebaseFirestore.instance;
  final _searchCtrl    = TextEditingController();

  List<ItemModel> _allItems      = [];
  List<ItemModel> _filteredItems = [];
  bool _loading    = true;
  String _typeFilter     = 'all';      // 'all' | 'lost' | 'found'
  String _categoryFilter = 'All';

  final List<String> _categories = [
    'All', 'Keys', 'Wallet', 'Phone', 'Bag',
    'Documents', 'Jewelry', 'Glasses', 'Electronics', 'Clothing', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final snap = await _db
          .collection('items')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();

      final items = snap.docs
          .map((d) => ItemModel.fromMap(d.data(), d.id))
          .toList();

      setState(() {
        _allItems      = items;
        _filteredItems = items;
        _loading       = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    final query = _searchCtrl.text.toLowerCase().trim();

    setState(() {
      _filteredItems = _allItems.where((item) {
        // Type filter
        final matchType = _typeFilter == 'all' || item.type == _typeFilter;

        // Category filter
        final matchCategory =
            _categoryFilter == 'All' || item.category == _categoryFilter;

        // Search filter
        final matchSearch = query.isEmpty ||
            item.title.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query) ||
            item.location.toLowerCase().contains(query);

        return matchType && matchCategory && matchSearch;
      }).toList();
    });
  }

  void _setType(String type) {
    setState(() => _typeFilter = type);
    _applyFilters();
  }

  void _setCategory(String cat) {
    setState(() => _categoryFilter = cat);
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Browse Listings',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ── Search + Filters (fixed) ─────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search for an item...',
                    hintStyle: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.5),
                        fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textSecondary, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                size: 18,
                                color: AppColors.textSecondary),
                            onPressed: () {
                              _searchCtrl.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Type tabs — All / Lost / Found
                Row(children: [
                  _typeTab('all',   'All'),
                  const SizedBox(width: 8),
                  _typeTab('lost',  'Lost'),
                  const SizedBox(width: 8),
                  _typeTab('found', 'Found'),
                ]),
                const SizedBox(height: 12),

                // Category chips — scrollable
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) =>
                        _categoryChip(_categories[i]),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // ── Results ──────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.teal))
                : _filteredItems.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: AppColors.teal,
                        onRefresh: _loadItems,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) =>
                              BrowseItemCard(item: _filteredItems[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Type tab ─────────────────────────────────────────
  Widget _typeTab(String value, String label) {
    final selected = _typeFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setType(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 36,
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.navy : AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : AppColors.textSecondary,
              )),
        ),
      ),
    );
  }

  // ── Category chip ─────────────────────────────────────
  Widget _categoryChip(String label) {
    final selected = _categoryFilter == label;
    return GestureDetector(
      onTap: () => _setCategory(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.teal : AppColors.border,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            )),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 52,
              color: AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 14),
          const Text('No items found',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(
            _searchCtrl.text.isNotEmpty
                ? 'Try a different search term'
                : 'No listings match your filters',
            style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}