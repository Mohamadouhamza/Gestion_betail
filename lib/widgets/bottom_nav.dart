import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/mouvement_screen.dart';
import '../screens/inventaire_screen.dart';
import '../screens/historique_screen.dart';
import '../screens/fiche_screen.dart';
import '../theme/app_colors.dart';

class BottomNavScaffold extends StatefulWidget {
  const BottomNavScaffold({super.key});

  @override
  State<BottomNavScaffold> createState() => _BottomNavScaffoldState();
}

class _NavSpec {
  final IconData icone;
  final IconData iconeActive;
  final String label;
  const _NavSpec(this.icone, this.iconeActive, this.label);
}

class _BottomNavScaffoldState extends State<BottomNavScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SizedBox(),
    InventaireScreen(),
    HistoriqueScreen(),
    FicheScreen(),
  ];

  static const List<_NavSpec> _items = [
    _NavSpec(AppIcons.accueilInactif, AppIcons.accueil, 'Accueil'),
    _NavSpec(AppIcons.mouvement, AppIcons.mouvement, 'Mouvement'),
    _NavSpec(AppIcons.inventaireInactif, AppIcons.inventaire, 'Inventaire'),
    _NavSpec(AppIcons.historique, AppIcons.historique, 'Historique'),
    _NavSpec(AppIcons.ficheInactif, AppIcons.fiche, 'Fiche'),
  ];

  void _onNavItemTapped(int index) {
    // "Mouvement" n'a pas d'écran propre dans la pile : ouvre le formulaire
    // par-dessus, sans changer l'onglet sélectionné dans la navbar.
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MouvementScreen()),
      );
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondEcran,
      extendBody: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: _screens),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: _FloatingNavBar(
          selectedIndex: _selectedIndex,
          items: _items,
          onTap: _onNavItemTapped,
        ),
      ),
    );
  }
}

/// Barre de navigation FLOTTANTE : détachée des bords de l'écran, coins très
/// arrondis et ombre portée, façon "pilule" au-dessus du contenu.
class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavSpec> items;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 14,
      shadowColor: Colors.black.withOpacity(0.35),
      borderRadius: BorderRadius.circular(28),
      color: Colors.white,
      child: SizedBox(
        height: 68,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (i) {
            final actif = selectedIndex == i && i != 1;
            return _NavItem(
              spec: items[i],
              actif: actif,
              onTap: () => onTap(i),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavSpec spec;
  final bool actif;
  final VoidCallback onTap;

  const _NavItem({required this.spec, required this.actif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final couleur = actif ? AppColors.vertPrincipal : Colors.grey.shade500;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: actif ? AppColors.vertPrincipal.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(actif ? spec.iconeActive : spec.icone, color: couleur, size: 24),
            ),
            const SizedBox(height: 2),
            Text(
              spec.label,
              style: TextStyle(
                fontSize: 10.5,
                color: couleur,
                fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
