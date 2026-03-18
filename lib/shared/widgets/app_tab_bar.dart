import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  Widget _destination({
    required String iconPath,
    required String label,
    required int index,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                isSelected ? Colors.blue : Colors.grey,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: Row(
        children: [
          _destination(
            iconPath: 'assets/svg/homescreen/home_icon.svg',
            label: 'Home',
            index: 0,
          ),
          _destination(
            iconPath: 'assets/svg/homescreen/scan_qr_icon.svg',
            label: 'Scan',
            index: 1,
          ),

          const SizedBox(width: 72), // место для FAB

          _destination(
            iconPath: 'assets/svg/homescreen/saved_codes_folder_icon.svg',
            label: 'My QR',
            index: 2,
          ),
          _destination(
            iconPath: 'assets/svg/homescreen/history_icon.svg',
            label: 'History',
            index: 3,
          ),
        ],
      ),
    );
  }
}