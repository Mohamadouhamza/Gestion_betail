import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CarteSituation extends StatelessWidget {
  final String titre;
  final int valeur;
  final IconData icon;
  final Color couleur;
  final String? sousTitre;
  final VoidCallback? onTap;

  const CarteSituation({
    super.key,
    required this.titre,
    required this.valeur,
    required this.icon,
    required this.couleur,
    this.sousTitre,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [couleur.withOpacity(0.8), couleur],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  if (sousTitre != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        sousTitre!,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                '$valeur',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                titre,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CarteGestation extends StatelessWidget {
  final int valeur;
  const CarteGestation({super.key, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.pink.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.pink.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.pregnant_woman, color: Colors.pink.shade400, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$valeur',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink.shade700,
                  ),
                ),
                Text(
                  'Vaches en gestation',
                  style: GoogleFonts.poppins(
                    color: Colors.pink.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
