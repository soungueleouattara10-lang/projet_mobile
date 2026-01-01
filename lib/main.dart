import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

/// ============================================================
/// CALCULATRICE iOS-STYLE
/// ============================================================
///
/// FONCTIONNEMENT GÉNÉRAL :
/// ------------------------
/// Cette calculatrice suit le modèle d'une calculatrice iOS avec :
/// 1. Deux zones d'affichage :
///    - Expression (haut) : montre l'opération en cours
///    - Display (bas) : montre le nombre courant ou résultat
/// 2. Deux états :
///    - Mode saisie : l'utilisateur compose des nombres
///    - Après calcul : l'affichage montre le résultat et est prêt pour nouvelle opération
/// 3. Gestion des opérateurs :
///    - Les opérateurs stockent le nombre courant dans l'expression
///    - Le display est réinitialisé pour le prochain nombre
///
/// ARCHITECTURE PRINCIPALE :
/// -------------------------
/// - expression : String stockant l'opération complète (ex: "5 + 3 × 2")
/// - display : String affichant le nombre courant ou résultat
/// - justEvaluated : Booléen indiquant si on vient de calculer un résultat
///
/// FLUX DE CALCUL :
/// ----------------
/// 1. L'utilisateur tape un nombre (1, 2, 3...)
/// 2. L'utilisateur appuie sur un opérateur (+, -, ×, ÷)
///    → Le nombre est ajouté à l'expression
///    → L'opérateur est ajouté à l'expression
///    → Display repasse à "0"
/// 3. L'utilisateur tape un deuxième nombre
/// 4. L'utilisateur appuie sur "="
///    → L'expression complète est évaluée
///    → Le résultat s'affiche dans display
///    → L'expression montre "expression ="
///
/// ============================================================

class _CalculatorPageState extends State<CalculatorPage> {
  String expression = ""; // Expression affichée en haut
  String display = "0";   // Résultat / nombre courant
  bool justEvaluated = false;

  static const Color bgBlack = Colors.black;
  static const Color btnGray = Color(0xFF333333);
  static const Color btnOrange = Color(0xFFFF9F0A);

  /// Convertit les symboles de multiplication pour l'affichage
  String toDisplayExpression(String exp) {
    return exp.replaceAll("*", "×");
  }

  // ===================== ÉVALUATION MATHÉMATIQUE =================

  /// Évalue l'expression mathématique complète
  ///
  /// PRINCIPE :
  /// ----------
  /// 1. Vérifie si l'expression se termine par un opérateur
  ///    → Si oui, ajoute le display courant comme dernier opérande
  /// 2. Convertit les symboles d'interface en symboles mathématiques :
  ///    - "×" → "*" (multiplication)
  ///    - "÷" → "/" (division)
  ///    - "%" → "/100" (pourcentage)
  /// 3. Utilise la bibliothèque math_expressions pour parser et évaluer
  /// 4. Nettoie le résultat (supprime les zéros inutiles)
  ///
  /// EXEMPLE :
  /// ---------
  /// expression = "5 + 3 ×"
  /// display = "2"
  /// → expression finale = "5 + 3 * 2"
  /// → résultat = 11
  void evaluate() {
    try {
      String exp = expression;

      // Si l'expression se termine par un opérateur, on ajoute display
      if (exp.isEmpty || _endsWithOperator(exp)) {
        exp += display;
      }

      // Conversion des symboles d'interface en symboles mathématiques
      exp = exp
          .replaceAll("×", "*")
          .replaceAll("÷", "/")
          .replaceAll("%", "/100")
          .trim();

      Parser parser = Parser();
      Expression parsed = parser.parse(exp);
      double result =
      parsed.evaluate(EvaluationType.REAL, ContextModel());

      // Formatage du résultat (suppression des décimales inutiles)
      final resultStr = result % 1 == 0
          ? result.toInt().toString()
          : result
          .toStringAsFixed(6)
          .replaceAll(RegExp(r'0*$'), '')
          .replaceAll(RegExp(r'\.$'), '');

      setState(() {
        expression = "$exp =";
        display = resultStr;
        justEvaluated = true;
      });
    } catch (e) {
      setState(() {
        display = "Erreur";
      });
    }
  }

  /// Vérifie si une expression se termine par un opérateur
  bool _endsWithOperator(String exp) {
    return exp.trim().endsWith("+") ||
        exp.trim().endsWith("-") ||
        exp.trim().endsWith("×") ||
        exp.trim().endsWith("÷");
  }



  // ================= GESTION DES BOUTONS  =================

  /// Gère l'appui sur n'importe quel bouton de la calculatrice
  ///
  /// PARAMÈTRES :
  /// ------------
  /// [value] : La valeur du bouton pressé ("1", "+", "C", "=", etc.)
  ///
  /// LOGIQUE PAR TYPE DE BOUTON :
  /// -----------------------------
  /// 1. "C" → Réinitialisation complète
  /// 2. "=" → Évaluation de l'expression
  /// 3. Opérateurs (+, -, ×, ÷) :
  ///    - Si juste après un calcul : utilise le résultat comme premier opérande
  ///    - Sinon : ajoute le display courant à l'expression
  ///    - Réinitialise display pour le prochain nombre
  /// 4. "." → Ajoute une décimale (une seule par nombre)
  /// 5. "+/-" → Change le signe du nombre courant
  /// 6. "%" → Transforme le nombre courant en pourcentage (÷ 100)
  /// 7. Chiffres (0-9) → Construit le nombre courant
  ///
  /// CHOIX D'IMPLÉMENTATION POUR LE BOUTON % :
  /// -----------------------------------------
  /// Le bouton "%" est implémenté comme un opérateur unaire qui transforme
  /// immédiatement le nombre affiché en son pourcentage.
  ///
  /// RAISON :
  /// - Cohérence avec les calculatrices iOS
  /// - Simple et intuitif : tapez "50", appuyez sur "%" → obtient "0.5"
  /// - Permet des calculs comme : "100 + 10%" = "100 + 10" = "110"
  ///
  /// ALTERNATIVES REJETÉES :
  /// 1. Mode "pourcentage" qui affecte l'opération suivante
  ///    → Trop complexe pour l'utilisateur moyen
  /// 2. Stockage comme opérateur binaire (ex: "50 % 100")
  ///    → Moins intuitif pour une calculatrice simple
  ///
  /// EXEMPLE D'UTILISATION :
  /// -----------------------
  /// "100" → "%" → affiche "1" (100% = 1)
  /// "50" → "+" → "20" → "%" → "0.2" → "=" → "50.2"
  void onPress(String value) {
    setState(() {
      if (value == "C") {
        expression = "";
        display = "0";
        justEvaluated = false;
      }

      else if (value == "=") {
        if (display != "Erreur") {
          evaluate();
        }
      }

      // Gestion des opérateurs binaires
      else if (["+", "-", "×", "÷"].contains(value)) {
        if (justEvaluated) {
          // Réutilise le résultat comme premier opérande
          expression = "$display $value ";
          justEvaluated = false;
        } else {
          // Ajoute le nombre courant à l'expression
          expression += "$display $value ";
        }
        display = "0"; // Prêt pour le prochain nombre
      }

      // Gestion de la décimale
      else if (value == ".") {
        if (!display.contains(".")) {
          display += ".";
        }
      }

      // Changement de signe
      else if (value == "+/-") {
        if (display.startsWith("-")) {
          display = display.substring(1);
        } else if (display != "0") {
          display = "-$display";
        }
      }

      // POURCENTAGE - Voir documentation ci-dessus
      else if (value == "%") {
        double n = double.tryParse(display) ?? 0;
        display = (n / 100).toString();
      }

      // Chiffres (0-9)
      else {
        if (display == "Erreur" || justEvaluated) {
          // Réinitialise après erreur ou calcul
          display = value;
          justEvaluated = false;
          expression = "";
        } else if (display == "0") {
          // Remplace le zéro initial
          display = value;
        } else {
          // Ajoute le chiffre au nombre courant
          display += value;
        }
      }
    });
  }

  // ================= BOUTON =================
  Widget calcButton(
      String text, {
        Color color = btnGray,
        double fontSize = 30,
      }) {
    return GestureDetector(
      onTap: () => onPress(text),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      body: SafeArea(
        child: Column(
          children: [
            // ===== AFFICHAGE =====
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.bottomRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      toDisplayExpression(expression),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 24,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      display,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // ===== CLAVIER =====
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _row(["C", "%", "÷"],
                              [btnGray , btnGray , btnOrange]),
                          _row(["7", "8", "9"]),
                          _row(["4", "5", "6"]),
                          _row(["1", "2", "3"]),
                          _row(["+/-", "0", "."]),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: calcButton("×", color: btnOrange)),
                          Expanded(child: calcButton("-", color: btnOrange)),
                          Expanded(child: calcButton("+", color: btnOrange)),
                          Expanded(
                            flex: 2,
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              child: GestureDetector(
                                onTap: () => onPress("="),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: btnOrange,
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "=",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= LIGNE DE BOUTONS =================
  Widget _row(List<String> texts, [List<Color>? colors]) {
    return Expanded(
      child: Row(
        children: List.generate(texts.length, (i) {
          return Expanded(
            child: calcButton(
              texts[i],
              color: colors != null ? colors[i] : btnGray,
            ),
          );
        }),
      ),
    );
  }
}