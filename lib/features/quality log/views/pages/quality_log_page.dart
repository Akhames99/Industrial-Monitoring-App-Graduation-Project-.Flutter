import 'package:app/core/utils/theme/app_colors.dart';
import 'package:app/features/quality%20log/views/models/quality_log_model.dart';
import 'package:app/features/quality%20log/views/models/relabel_item_model.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class QualityLogPage extends StatefulWidget {
  const QualityLogPage({Key? key}) : super(key: key);

  @override
  State<QualityLogPage> createState() => _QualityLogPageState();
}

class _QualityLogPageState extends State<QualityLogPage> {
  QualityLogContainer? qualityLogData;
  QualityItemStatus? selectedFilter;
  QualityReviewCategory? selectedReviewCategory;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    // Default mode: pending inspections.
    selectedFilter = QualityItemStatus.pending;
    _initializeQualityLog();
  }

  Future<void> _initializeQualityLog() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await QualityLogService().fetchQualityLog(
        filterByStatus: selectedFilter,
      );
      debugPrint('=== QUALITY ITEMS ===');
      for (final item in data.items) {
        debugPrint(
          'ID: ${item.id} | imageUrl: ${item.imageUrl} | rawStatus: ${item.rawStatus}',
        );
      }
      if (mounted) {
        setState(() {
          qualityLogData = data;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        setState(() {
          qualityLogData = QualityLogContainer(
            items: [],
            lastUpdated: DateTime.now(),
            pendingCount: 0,
            reviewedCount: 0,
          );
        });
      }
    }
  }

  void _filterByStatus(QualityItemStatus? status) {
    if (selectedFilter == status) return;
    setState(() {
      selectedFilter = status;
      // Leaving/entering the Reviewed tab resets the Good/Defected/Invalid
      // sub-filter.
      selectedReviewCategory = null;
      currentPage = 1;
    });
    _loadData();
  }

  void _filterByReviewCategory(QualityReviewCategory? category) {
    if (selectedReviewCategory == category) return;
    setState(() {
      selectedReviewCategory = category;
      currentPage = 1;
    });
  }

  List<QualityItem> _getFilteredItems() {
    if (qualityLogData == null) return [];

    var items = qualityLogData!.items;

    if (selectedFilter != null) {
      items = items.where((item) => item.status == selectedFilter).toList();
    }

    // Good / Defected / Invalid sub-filter only applies within Reviewed.
    if (selectedFilter == QualityItemStatus.reviewed &&
        selectedReviewCategory != null) {
      items = items
          .where((item) => item.reviewCategory == selectedReviewCategory)
          .toList();
    }

    return items;
  }

  void _goToPage(int page) {
    final filteredItems = _getFilteredItems();
    final maxPage = (filteredItems.length / 4).ceil();
    if (page >= 1 && page <= maxPage) {
      setState(() {
        currentPage = page;
      });
    }
  }

  void _handleRelabel(String itemId, String newLabel) async {
    final success = await QualityLogService().relabelItem(itemId, newLabel);

    if (success) {
      // Relabel finalizes the review server-side (sets user_id), which
      // moves the item from Pending to Reviewed. Refetch instead of
      // patching local state so tab membership and counts reflect what
      // the server actually did.
      currentPage = 1;
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item relabeled to $newLabel successfully'),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to relabel item'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  void _handleConfirm(String itemId) async {
    debugPrint('Confirm called for item: $itemId');

    final success = await QualityLogService().confirmInspection(itemId);

    if (success) {
      _updateItemStatus(itemId, QualityItemStatus.reviewed, isConfirmed: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item confirmed successfully'),
            backgroundColor: Colors.blue[600],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to confirm inspection'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  void _handleEdit(String itemId, String newLabel) async {
    final isInvalid = newLabel.toLowerCase() == 'invalid';
    final isPerfectBottle = newLabel.toLowerCase() == 'perfect_bottle';
    final status = isInvalid
        ? 'Invalid'
        : (isPerfectBottle ? 'Good' : 'Defected');
    final defectCategory = (isInvalid || isPerfectBottle) ? '' : newLabel;

    final success = await QualityLogService().editInspection(
      itemId,
      status,
      defectCategory,
    );

    if (success) {
      currentPage = 1;
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item edited to $newLabel successfully'),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to edit item'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  void _updateItemStatus(
    String itemId,
    QualityItemStatus newStatus, {
    bool? isConfirmed,
    String? defectCategory,
    String? rawStatus,
  }) {
    if (qualityLogData != null) {
      final itemIndex = qualityLogData!.items.indexWhere(
        (item) => item.id == itemId,
      );
      if (itemIndex == -1) return;
      final oldStatus = qualityLogData!.items[itemIndex].status;

      final updatedItems = qualityLogData!.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(
            status: newStatus,
            isConfirmed: isConfirmed ?? item.isConfirmed,
            defectCategory: defectCategory ?? item.defectCategory,
            rawStatus: rawStatus ?? item.rawStatus,
          );
        }
        return item;
      }).toList();

      int pendingDelta = 0;
      int reviewedDelta = 0;
      if (oldStatus != newStatus) {
        if (oldStatus == QualityItemStatus.pending) {
          pendingDelta = -1;
        } else if (oldStatus == QualityItemStatus.reviewed) {
          reviewedDelta = -1;
        }

        if (newStatus == QualityItemStatus.pending) {
          pendingDelta += 1;
        } else if (newStatus == QualityItemStatus.reviewed) {
          reviewedDelta += 1;
        }
      }

      setState(() {
        qualityLogData = qualityLogData!.copyWith(
          items: updatedItems,
          pendingCount: qualityLogData!.pendingCount + pendingDelta,
          reviewedCount: qualityLogData!.reviewedCount + reviewedDelta,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (qualityLogData == null) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(child: CircularProgressIndicator(color: Colors.blue[600])),
      );
    }

    final filteredItems = _getFilteredItems();
    final maxPage = (filteredItems.length / 4).ceil();
    final currentItems = filteredItems
        .skip((currentPage - 1) * 4)
        .take(4)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16.0),
              _buildFilterTabs(),
              if (selectedFilter == QualityItemStatus.reviewed) ...[
                const SizedBox(height: 12.0),
                _buildReviewCategoryTabs(),
              ],
              const SizedBox(height: 16.0),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _initializeQualityLog,
                  child: currentItems.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: Center(
                                child: Text(
                                  'No items found',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: currentItems.length,
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                QualityItemCard(
                                  item: currentItems[index],
                                  onConfirm: (id) => _handleConfirm(id),
                                  onRelabel: _handleRelabel,
                                  onEdit: _handleEdit,
                                ),
                                if (index < currentItems.length - 1)
                                  const SizedBox(height: 16),
                              ],
                            );
                          },
                        ),
                ),
              ),

              const SizedBox(height: 24),

              if (maxPage > 1) _buildPagination(maxPage),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final pendingCount = qualityLogData?.pendingCount ?? 0;
    final reviewedCount = qualityLogData?.reviewedCount ?? 0;
    final allCount = pendingCount + reviewedCount;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                LucideIcons.clipboardList300,
                color: AppColors.blue,
                size: 32.0,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quality Log',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue,
                        fontSize: 20.0,
                      ),
                    ),
                    Text(
                      '$allCount All | $pendingCount Pending | $reviewedCount Reviewed',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.description,
                        fontWeight: FontWeight.w400,
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8.0),
        Row(
          children: [
            Container(
              width: 40.0,
              height: 32.0,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                Icons.filter_alt_outlined,
                color: AppColors.description,
                size: 24.0,
              ),
            ),
            const SizedBox(width: 12.0),
            Container(
              width: 40.0,
              height: 32.0,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                Icons.search,
                color: AppColors.description,
                size: 24.0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    final pendingCount = qualityLogData?.pendingCount ?? 0;
    final reviewedCount = qualityLogData?.reviewedCount ?? 0;
    final allCount = pendingCount + reviewedCount;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterButton('All ($allCount)', null),
          const SizedBox(width: 16.0),
          _buildFilterButton(
            'Pending ($pendingCount)',
            QualityItemStatus.pending,
          ),
          const SizedBox(width: 16.0),
          _buildFilterButton(
            'Reviewed ($reviewedCount)',
            QualityItemStatus.reviewed,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, QualityItemStatus? status) {
    final isActive = selectedFilter == status;
    return GestureDetector(
      onTap: () => _filterByStatus(status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue[600] : Colors.white,
          border: Border.all(
            color: isActive ? Colors.blue[600]! : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  /// Sub-tabs shown only inside the "Reviewed" filter, mirroring the three
  /// review outcomes stored in the database: Good, Defected, Invalid.
  Widget _buildReviewCategoryTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildReviewCategoryButton('All', null),
          const SizedBox(width: 12.0),
          _buildReviewCategoryButton('Good', QualityReviewCategory.good),
          const SizedBox(width: 12.0),
          _buildReviewCategoryButton(
            'Defected',
            QualityReviewCategory.defected,
          ),
          const SizedBox(width: 12.0),
          _buildReviewCategoryButton('Invalid', QualityReviewCategory.invalid),
        ],
      ),
    );
  }

  Widget _buildReviewCategoryButton(
    String label,
    QualityReviewCategory? category,
  ) {
    final isActive = selectedReviewCategory == category;
    return GestureDetector(
      onTap: () => _filterByReviewCategory(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue[50] : Colors.white,
          border: Border.all(
            color: isActive ? Colors.blue[600]! : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.blue[600] : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(int maxPage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: currentPage > 1 ? () => _goToPage(currentPage - 1) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: currentPage > 1 ? Colors.white : Colors.grey[200],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Prev',
              style: TextStyle(
                fontSize: 12,
                color: currentPage > 1 ? Colors.grey[700] : Colors.grey[400],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(maxPage, (index) {
                final pageNum = index + 1;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _goToPage(pageNum),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: currentPage == pageNum
                              ? Colors.blue[600]
                              : Colors.white,
                          border: Border.all(
                            color: currentPage == pageNum
                                ? Colors.blue[600]!
                                : Colors.grey[300]!,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          pageNum.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: currentPage == pageNum
                                ? Colors.white
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                );
              }),
            ),
          ),
        ),
        GestureDetector(
          onTap: currentPage < maxPage
              ? () => _goToPage(currentPage + 1)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: currentPage < maxPage ? Colors.white : Colors.grey[200],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Next',
              style: TextStyle(
                fontSize: 12,
                color: currentPage < maxPage
                    ? Colors.grey[700]
                    : Colors.grey[400],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Quality Item Card Widget
class QualityItemCard extends StatelessWidget {
  final QualityItem item;
  final Function(String)? onConfirm;
  final Function(String)? onSendToDataset;
  final Function(String, String)? onRelabel;
  final Function(String, String)? onEdit;

  const QualityItemCard({
    Key? key,
    required this.item,
    this.onConfirm,
    this.onSendToDataset,
    this.onRelabel,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.blue[600],
                                strokeWidth: 2,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderContent(),
                        )
                      : _buildPlaceholderContent(),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.confidenceScore.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: _getConfidenceColor(item.confidenceScore),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      (item.defectCategory != null &&
                              item.defectCategory!.isNotEmpty)
                          ? item.defectCategory!
                          : (item.title.toLowerCase() == 'pending')
                          ? item.type.displayName
                          : item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: item.status.badgeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (item.defectCategory != null &&
                                item.defectCategory!.isNotEmpty)
                            ? "${item.status.displayName}"
                            : item.status.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: item.status.badgeTextColor,
                        ),
                      ),
                    ),
                    if (item.reviewCategory != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: item.reviewCategory!.badgeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.reviewCategory!.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: item.reviewCategory!.badgeTextColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(item.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                if (item.actionTaken != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 14,
                        color: Colors.green[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.actionTaken!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                _buildActionButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (item.isUploading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Uploading image…',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (item.status == QualityItemStatus.reviewed) {
      return _buildButton(
        icon: Icons.edit_outlined,
        label: 'Edit',
        backgroundColor: Colors.grey[200]!,
        textColor: Colors.grey[700]!,
        onPressed: () => _showEditModal(context),
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: _buildButton(
              icon: Icons.clear_outlined,
              label: 'Relabel',
              backgroundColor: Colors.grey[200]!,
              textColor: Colors.grey[700]!,
              onPressed: () => _showRelabelModal(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildButton(
              icon: Icons.check_circle_outline,
              label: 'Confirm',
              backgroundColor: const Color(0xFFEBF5FB),
              textColor: Colors.blue[600]!,
              onPressed: () => _handleDirectConfirm(),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRelabelModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => RelabelItemModal(
        item: item,
        onRelabel: (newLabel) {
          onRelabel?.call(item.id, newLabel);
        },
      ),
    );
  }

  void _handleDirectConfirm() {
    // Call confirm API directly without showing dialog
    onConfirm?.call(item.id);
  }

  void _showEditModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => RelabelItemModal(
        item: item,
        isEditMode: true,
        onRelabel: (newLabel) {
          onEdit?.call(item.id, newLabel);
        },
      ),
    );
  }

  Widget _buildPlaceholderContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 48, color: Colors.grey[500]),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double score) {
    if (score >= 80) {
      return Colors.green[400]!;
    } else if (score >= 60) {
      return Colors.orange[400]!;
    } else {
      return Colors.red[400]!;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class QualityLogExample extends StatelessWidget {
  const QualityLogExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const QualityLogPage();
  }
}
