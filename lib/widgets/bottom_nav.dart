import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/mouvement_screen.dart';
import '../screens/inventaire_screen.dart';
import '../screens/historique_screen.dart';
import '../screens/fiche_screen.dart';
import '../models/enums.dart';

class BottomNavScaffold extends StatefulWidget {
  final int initialIndex;
  final String? category;

  const BottomNavScaffold({
    super.key,
    this.initialIndex = 0,
    this.category,
  });

  @override
  State<BottomNavScaffold> createState() => _BottomNavScaffoldState();
}

class _BottomNavScaffoldState extends State<BottomNavScaffold> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    SizedBox(),
    InventaireScreen(),
    HistoriqueScreen(),
    FicheScreen(),
  ];

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MouvementScreen()),
      ).then((_) {
        setState(() {
          _selectedIndex = 0;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
            activeIcon: Icon(Icons.home_filled),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Mouvement',
            activeIcon: Icon(Icons.add_circle),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Inventaire',
            activeIcon: Icon(Icons.inventory_2),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
            activeIcon: Icon(Icons.history_edu),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            label: 'Fiche',
            activeIcon: Icon(Icons.description),
          ),
        ],
      ),
    );
  }
}
