import 'package:firebase_test/menagerPages/contact_page.dart';
import 'package:firebase_test/menagerPages/regulations.dart';
import 'package:firebase_test/menagerPages/reservations.dart';
import 'package:firebase_test/navigation/user_role_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../userPages/report_status_page.dart';
import '../userPages/my_reservations.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Wyloguj się',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          content: Text(
            'Czy jesteś pewny, że chcesz się wylogować?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: <Widget>[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Anuluj"),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () async {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text("Wyloguj"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final role = Provider.of<UserRoleProvider>(context).role;

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              user?.displayName ?? 'User Name',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
            ),
            accountEmail: Text(
              user?.email ?? 'Email Not Available',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (role == 'manager') ...[
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Zarządzaj rezerwacjami'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllReservationsPage(),
                  ),
                );
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Status zgłoszeń'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportStatusPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Moje rezerwacje'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyReservationsPage(),
                  ),
                );
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.announcement),
            title: const Text('Kontakt'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContactPage(
                    currentUserRole: role ?? "user",
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Regulamin'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RegulationsPage(role: role ?? "user"),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Wyloguj się'),
            onTap: () => _confirmSignOut(context),
          ),
          // const Divider(),
          // Padding(
          //   padding:
          //       const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          //   child: Text(
          //     'Pomoc i ustawienia',
          //     style: Theme.of(context).textTheme.labelSmall?.copyWith(
          //           color: Theme.of(context).colorScheme.onSurfaceVariant,
          //         ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
