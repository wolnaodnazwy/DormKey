import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_test/navigation/user_role_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:badges/badges.dart' as badges;

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final String userId;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.userId,
  });

  Stream<int> getUnreadAnnouncementsCount(String userId) {
    final announcementsStream =
        FirebaseFirestore.instance.collection('announcements').snapshots();
    final userReadsStream = FirebaseFirestore.instance
        .collection('user_reads')
        .doc(userId)
        .snapshots();

    return Rx.combineLatest2(
      announcementsStream,
      userReadsStream,
      (QuerySnapshot announcementsSnapshot,
          DocumentSnapshot userReadsSnapshot) {
        final allAnnouncements =
            announcementsSnapshot.docs.map((doc) => doc.id).toSet();

        final userReadsData = userReadsSnapshot.exists
            ? userReadsSnapshot.data() as Map<String, dynamic>
            : {};

        final readAnnouncements = userReadsData.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .toSet();

        final unreadAnnouncements =
            allAnnouncements.difference(readAnnouncements);

        return unreadAnnouncements.length;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRole = Provider.of<UserRoleProvider>(context).role;
    final bool isManager = userRole == 'manager';

    return StreamBuilder<int>(
      stream: getUnreadAnnouncementsCount(userId),
      builder: (context, snapshot) {
        final badgeCount = snapshot.data ?? 0;

        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: BottomNavigationBar(
            currentIndex: selectedIndex == 4 ? 0 : selectedIndex,
            onTap: onItemTapped,
            items: isManager
                ? _buildManagerNavBarItems(context, badgeCount)
                : _buildUserNavBarItems(context, badgeCount),
          ),
        );
      },
    );
  }

  List<BottomNavigationBarItem> _buildManagerNavBarItems(
      BuildContext context, int badgeCount) {
    return [
      _buildBottomNavigationBarItem(
        context: context,
        icon: MdiIcons.alertOctagonOutline,
        filledIcon: MdiIcons.alertOctagon,
        label: "Awarie",
        index: 0,
      ),
      _buildBottomNavigationBarItem(
        context: context,
        icon: MdiIcons.bellOutline,
        filledIcon: MdiIcons.bell,
        label: "Ogłoszenia",
        index: 1,
        badgeCount: badgeCount,
      ),
      _buildBottomNavigationBarItem(
        context: context,
        icon: MdiIcons.accountGroupOutline,
        filledIcon: MdiIcons.accountGroup,
        label: "Użytkownicy",
        index: 2,
      ),
      _buildBottomNavigationBarItem(
        context: context,
        icon: MdiIcons.chartBoxOutline,
        filledIcon: MdiIcons.chartBox,
        label: "Statystyki",
        index: 3,
      ),
    ];
  }

  List<BottomNavigationBarItem> _buildUserNavBarItems(
      BuildContext context, int badgeCount) {
    return [
      _buildBottomNavigationBarItem(
        context: context,
        icon: MdiIcons.accountCircleOutline,
        filledIcon: MdiIcons.accountCircle,
        label: "Konto",
        index: 0,
      ),
      _buildBottomNavigationBarItem(
        context: context,
        icon: MdiIcons.bellOutline,
        filledIcon: MdiIcons.bell,
        label: "Ogłoszenia",
        index: 1,
        badgeCount: badgeCount,
      ),
      _buildBottomNavigationBarItem(
        context: context,
        icon: MdiIcons.homeOutline,
        filledIcon: MdiIcons.home,
        label: "Start",
        index: 2,
      ),
      _buildBottomNavigationBarItem(
        context: context,
        icon: MdiIcons.calendarPlusOutline,
        filledIcon: MdiIcons.calendarPlus,
        label: "Zarezerwuj",
        index: 3,
      ),
    ];
  }

  BottomNavigationBarItem _buildBottomNavigationBarItem({
    required BuildContext context,
    required IconData icon,
    required IconData filledIcon,
    required String label,
    required int index,
    int badgeCount = 0,
  }) {
    final bool isSelected = selectedIndex == index;
    final String badgeText = badgeCount > 9 ? '9+' : '$badgeCount';
    // final String badgeText = '$badgeCount';
    return BottomNavigationBarItem(
      label: label,
      icon: badges.Badge(
        showBadge: badgeCount > 0,
        badgeContent: Text(
          badgeText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        badgeStyle: badges.BadgeStyle(
            badgeColor: Colors.red,
            shape: badges.BadgeShape.circle,
            padding: badgeText.length > 1
                ? const EdgeInsets.all(3)
                : const EdgeInsets.all(7)),
        position: badgeText.length > 1
            ? badges.BadgePosition.topEnd(top: 1, end: 3)
            : badges.BadgePosition.topEnd(top: -3, end: 1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Container(
            padding: const EdgeInsets.fromLTRB(25, 8, 25, 8),
            decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.6)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20)),
            child: Icon(
              isSelected ? filledIcon : icon,
            ),
          ),
        ),
      ),
    );
  }
}
