import 'package:app/features/quality%20log/views/models/quality_log_model.dart';
import 'package:app/features/quality%20log/views/models/relabel_item_model.dart';
import 'package:flutter/material.dart';

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
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: Colors.blue[400],
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImagePlaceholder();
                          },
                        )
                      : _buildImagePlaceholder(),
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

                // Action Buttons
                _buildActionButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
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

  void _showRelabelModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => RelabelItemModal(
        item: item,
        onRelabel: (newLabel) {
          onRelabel?.call(item.id);
          debugPrint('Relabeled to: $newLabel');
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
          debugPrint('Defection confirmed');
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
          debugPrint('Item dismissed');
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
          debugPrint('Sent to dataset');
        },
      ),
    );
  }

  Color _getConfidenceColor(double score) {
    if (score >= 80) return Colors.green[400]!;
    if (score >= 60) return Colors.orange[400]!;
    return Colors.red[400]!;
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
