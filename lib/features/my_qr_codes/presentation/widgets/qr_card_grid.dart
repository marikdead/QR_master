import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../domain/saved_qr_model.dart';

class QrCardGrid extends StatelessWidget {
  const QrCardGrid({
    super.key,
    required this.items,
    required this.onTap,
    required this.onShare,
    required this.onEdit,
    required this.onDelete,
  });

  final List<SavedQrCode> items;
  final ValueChanged<SavedQrCode> onTap;
  final ValueChanged<SavedQrCode> onShare;
  final ValueChanged<SavedQrCode> onEdit;
  final ValueChanged<SavedQrCode> onDelete;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        return QrCard(
          code: item,
          onTap: () => onTap(item),
          onShare: () => onShare(item),
          onEdit: () => onEdit(item),
          onDelete: () => onDelete(item),
        );
      },
    );
  }
}

class QrCard extends StatelessWidget {
  const QrCard({
    super.key,
    required this.code,
    required this.onTap,
    required this.onShare,
    required this.onEdit,
    required this.onDelete,
  });

  final SavedQrCode code;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 🔹 QR блок как элемент, а не фон
              Container(
                width: double.infinity,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6EC6F5), Color(0xFF4DB6F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: QrImageView(
                    data: code.content,
                    size: 70,
                    backgroundColor: Colors.transparent,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.white,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 0),

              // 🔹 Заголовок + меню
              Row(
                children: [
                  Expanded(
                    child: Text(
                      code.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<void>(
                    icon: const Icon(Icons.more_horiz, size: 20),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        enabled: false,
                        height: 0,
                        padding: EdgeInsets.zero,
                        child: _QrActionsPopup(
                          onShare: () {
                            Navigator.pop(context);
                            onShare();
                          },
                          onEdit: () {
                            Navigator.pop(context);
                            onEdit();
                          },
                          onDelete: () {
                            Navigator.pop(context);
                            onDelete();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              Text(
                code.subtitle,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              // 🔹 Дата + просмотры
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    code.formattedDate,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.visibility_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${code.viewCount}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrActionsPopup extends StatelessWidget {
  const _QrActionsPopup({
    required this.onShare,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PopupAction(
            color: const Color(0xFF4CAF50),
            icon: Icons.reply,
            label: 'Share All',
            onTap: onShare,
          ),
          const SizedBox(width: 20),
          _PopupAction(
            color: const Color(0xFF4DB6F5),
            icon: Icons.edit_outlined,
            label: 'Edit',
            onTap: onEdit,
          ),
          const SizedBox(width: 20),
          _PopupAction(
            color: const Color(0xFFFF9800),
            icon: Icons.delete_outline,
            label: 'Delete',
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _PopupAction extends StatelessWidget {
  const _PopupAction({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF555555)),
          ),
        ],
      ),
    );
  }
}

