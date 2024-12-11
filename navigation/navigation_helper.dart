import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_test/menagerPages/add_announcement.dart';
import 'package:firebase_test/menagerPages/contact_page.dart';
import 'package:firebase_test/menagerPages/reports_page.dart';
import 'package:firebase_test/menagerPages/stats/stats.dart';
import 'package:firebase_test/menagerPages/users.dart';
import 'package:flutter/material.dart';
import '../widgets/app_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import '../userPages/residential_card_page.dart';
import '../userPages/announcements_page.dart';
import '../userPages/report_page.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../widgets/drawer.dart';
import '../userPages/schedule.dart';
import '../userPages/main_page.dart';

class HomePage extends StatefulWidget {
  final String role;
  const HomePage({super.key, required this.role});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1;
  bool _isSpecialPage = false;
  String? _specialPageTitle;

  String _userStatus = 'inactive';

  final List<Widget> _managerPages = [
    const AllReportsPage(),
    const AnnouncementsPage(),
    const UsersPage(),
    const StatsPage(),
  ];

  final List<String> _userPageTitles = [
    "Karta mieszkańca",
    "Ogłoszenia",
    "Strona główna",
    "Zarezerwuj",
  ];

  final List<String> _managerPageTitles = [
    "Zgłoszone awarie",
    "Ogłoszenia",
    "Użytkownicy i autoryzacja",
    "Statystyki",
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isSpecialPage = false;
      _specialPageTitle = null;
    });
  }

  void _navigateToSpecialPage(String title, Widget page) {
    setState(() {
      _isSpecialPage = true;
      _specialPageTitle = title;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchUserStatusAndRole();
  }

  void _fetchUserStatusAndRole() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('user_statuses')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
        if (doc.exists) {
          final data = doc.data();
          setState(() {
            _userStatus = data?['status'] ?? 'inactive';
          });
        }
      });
    }
  }

  Widget _restrictedAccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "Opcja dostępna tylko dla użytkowników z aktywną kartą mieszkańca. "
          "W celu aktywacji karty zgłoś się do kierownika domu studenkiego.",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.outline,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isManager = widget.role == 'manager';
    final isStudentUnion = widget.role == 'student_union';
    final pageTitles = isManager ? _managerPageTitles : _userPageTitles;

    final List<Widget> _userPages = [
      const ResidentialCardPage(),
      const AnnouncementsPage(),
      const StartCardPage(),
      _userStatus == 'active'
          ? const ReservationPage()
          : _restrictedAccessView(),
    ];

    final pages = isManager ? _managerPages : _userPages;

    return Scaffold(
      appBar: CustomAppBar(
        title: _isSpecialPage
            ? _specialPageTitle ?? "Szczegóły"
            : pageTitles[_selectedIndex],
        onInitialsTap: () {
          if (isManager) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      ContactPage(currentUserRole: widget.role)),
            );
          } else {
            setState(() {
              _selectedIndex = 0;
              _isSpecialPage = false;
              _specialPageTitle = null;
            });
          }
        },
      ),
      drawer: const CustomDrawer(),
      body: _isSpecialPage
          ? (_specialPageTitle == "Dodaj ogłoszenie"
              ? const AddAnnouncementPage()
              : const ReportPage())
          : IndexedStack(
              index: _selectedIndex,
              children: pages,
            ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _isSpecialPage ? 4 : _selectedIndex,
        onItemTapped: _onItemTapped,
        userId: FirebaseAuth.instance.currentUser!.uid,
      ),
      floatingActionButton: _buildFAB(context, isStudentUnion, isManager),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget? _buildFAB(BuildContext context, bool isStudentUnion, bool isManager) {
    if (_userStatus != 'active') {
      return null;
    }
    if (isStudentUnion && !_isSpecialPage) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "add_announcement_fab",
            onPressed: () {
              _navigateToSpecialPage(
                  "Dodaj ogłoszenie", const AddAnnouncementPage());
            },
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              MdiIcons.messageDraw,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: "report_issue_fab",
            onPressed: () {
              _navigateToSpecialPage("Zgłoś usterkę", const ReportPage());
            },
            label: Text(
              "Zgłoś usterkę",
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
            ),
            icon: Icon(MdiIcons.alertOctagonOutline,
                color: Theme.of(context).colorScheme.onSecondary),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        ],
      );
    } else if (isManager && !_isSpecialPage) {
      return FloatingActionButton(
        heroTag: "manager_fab",
        onPressed: () {
          _navigateToSpecialPage(
              "Dodaj ogłoszenie", const AddAnnouncementPage());
        },
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          MdiIcons.plusCircleOutline,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
    } else if (!_isSpecialPage) {
      return FloatingActionButton(
        heroTag: "user_fab",
        onPressed: () {
          _navigateToSpecialPage("Zgłoś usterkę", const ReportPage());
        },
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          MdiIcons.plusCircleOutline,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
    } else {
      return null;
    }
  }
}
