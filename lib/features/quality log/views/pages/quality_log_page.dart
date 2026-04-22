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
  QualityLogContainer? qualityLogData; // Make it nullable instead of late
  QualityItemStatus? selectedFilter;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    selectedFilter = null; // Initialize to null (shows "All" items)
    _initializeQualityLog();
  }

  Future<void> _initializeQualityLog() async {
    try {
      final data = await QualityLogService().fetchQualityLog();
      if (mounted) {
        setState(() {
          qualityLogData = data;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _filterByStatus(QualityItemStatus? status) {
    setState(() {
      selectedFilter = status;
      currentPage = 1;
    });
  }

  List<QualityItem> _getFilteredItems() {
    if (qualityLogData == null) return [];

    if (selectedFilter == null) {
      return qualityLogData!.items;
    }
    return qualityLogData!.items
        .where((item) => item.status == selectedFilter)
        .toList();
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

  // Handle Relabel Action
  void _handleRelabel(String itemId) {
    debugPrint('Relabel called for item: $itemId');
    // TODO: Call API to relabel item
    _updateItemStatus(itemId, QualityItemStatus.reviewed);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Item relabeled successfully'),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Handle Confirm Action
  void _handleConfirm(String itemId) {
    debugPrint('Confirm called for item: $itemId');
    // TODO: Call API to confirm defection
    _updateItemStatus(itemId, QualityItemStatus.reviewed);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Defection confirmed'),
        backgroundColor: Colors.blue[600],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Handle Dismiss Action
  void _handleDismiss(String itemId) {
    debugPrint('Dismiss called for item: $itemId');
    // TODO: Call API to dismiss item
    _removeItem(itemId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Item dismissed'),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Handle Send to Dataset Action
  void _handleSendToDataset(String itemId) {
    debugPrint('Send to dataset called for item: $itemId');
    // TODO: Call API to send to dataset
    _removeItem(itemId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Item sent to dataset'),
        backgroundColor: Colors.blue[600],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Helper: Update item status in local state
  void _updateItemStatus(String itemId, QualityItemStatus newStatus) {
    if (qualityLogData != null) {
      final updatedItems = qualityLogData!.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(status: newStatus);
        }
        return item;
      }).toList();

      setState(() {
        qualityLogData = qualityLogData!.copyWith(items: updatedItems);
      });
    }
  }

  // Helper: Remove item from local state
  void _removeItem(String itemId) {
    if (qualityLogData != null) {
      final updatedItems = qualityLogData!.items
          .where((item) => item.id != itemId)
          .toList();

      setState(() {
        qualityLogData = qualityLogData!.copyWith(items: updatedItems);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state while data is being fetched
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
                                  onDismiss: _handleDismiss,
                                  onConfirm: _handleConfirm,
                                  onSendToDataset: _handleSendToDataset,
                                  onRelabel: _handleRelabel,
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

              // Pagination
              if (maxPage > 1) _buildPagination(maxPage),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final pendingCount = qualityLogData?.pendingItems.length ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.clipboardList300,
              color: AppColors.blue,
              size: 32.0,
            ),
            const SizedBox(width: 8.0),
            Column(
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
                  '${pendingCount} Of Items Pending',
                  style: TextStyle(
                    color: AppColors.description,
                    fontWeight: FontWeight.w400,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ],
        ),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterButton('All', null),
          const SizedBox(width: 16.0),
          _buildFilterButton('Pending', QualityItemStatus.pending),
          const SizedBox(width: 16.0),
          _buildFilterButton('Reviewed', QualityItemStatus.reviewed),
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

  Widget _buildPagination(int maxPage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Prev Button
        GestureDetector(
          onTap: currentPage > 1 ? () => _goToPage(currentPage - 1) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

        // Page numbers
        ...List.generate(maxPage, (index) {
          final pageNum = index + 1;
          return Row(
            children: [
              GestureDetector(
                onTap: () => _goToPage(pageNum),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
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

        // Next Button
        GestureDetector(
          onTap: currentPage < maxPage
              ? () => _goToPage(currentPage + 1)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
  final Function(String)? onDismiss;
  final Function(String)? onConfirm;
  final Function(String)? onSendToDataset;
  final Function(String)? onRelabel;

  const QualityItemCard({
    Key? key,
    required this.item,
    this.onDismiss,
    this.onConfirm,
    this.onSendToDataset,
    this.onRelabel,
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
          // Image Preview with confidence badge
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
              // Confidence badge
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

          // Item Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Status
                Row(
                  children: [
                    Text(
                      item.title,
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.status.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: item.status.badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),

                // Timestamp
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

                // Action taken (if any)
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
    // Show different buttons based on status
    if (item.status == QualityItemStatus.reviewed) {
      return Row(
        children: [
          Expanded(
            child: _buildButton(
              icon: Icons.delete_outline,
              label: 'Dismiss',
              backgroundColor: const Color(0xFFFEE8E8),
              textColor: const Color(0xFFE74C3C),
              onPressed: () => _showDismissModal(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildButton(
              icon: Icons.send_outlined,
              label: 'Send to dataset',
              backgroundColor: const Color(0xFFEBF5FB),
              textColor: Colors.blue[600]!,
              onPressed: () => _showSendToDatasetModal(context),
            ),
          ),
        ],
      );
    } else {
      // Pending status
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
              onPressed: () => _showConfirmModal(context),
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

  // Modal Dialogs
  void _showRelabelModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => RelabelItemModal(
        item: item,
        onRelabel: (newLabel) {
          onRelabel?.call(item.id);
        },
      ),
    );
  }

  void _showConfirmModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ConfirmDefectionModal(
        item: item,
        onConfirm: () {
          onConfirm?.call(item.id);
        },
      ),
    );
  }

  void _showDismissModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => DismissItemModal(
        item: item,
        onDismiss: () {
          onDismiss?.call(item.id);
        },
      ),
    );
  }

  void _showSendToDatasetModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SendToDatasetModal(
        item: item,
        onSend: () {
          onSendToDataset?.call(item.id);
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

// Example Usage
class QualityLogExample extends StatelessWidget {
  const QualityLogExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const QualityLogPage();
  }
}
