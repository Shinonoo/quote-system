import '../constants/actuators.dart';

class ActuatorSelection {
  final ActuatorModel model;
  final int quantity;
  final double unitPrice;   // price per actuator (after markup)
  final double totalPrice;  // unitPrice × quantity
  final double nmRequired;
  final double nmProvided;  // model.nmRating × quantity

  const ActuatorSelection({
    required this.model,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.nmRequired,
    required this.nmProvided,
  });

  String get label =>
      quantity > 1 ? '${model.model} × $quantity units' : model.model;
}

class ActuatorService {
  static const double _maxNm = 20.0;

  /// Nm formula: length × width × 10 / 1,000,000
  static double calculateNm(int lengthMm, int widthMm) {
    return lengthMm * widthMm * 10 / 1000000;
  }

  /// Auto-selects the correct actuator and quantity
  static ActuatorSelection? select({
    required ActuatorSection section,
    required int lengthMm,
    required int widthMm,
  }) {
    final models = ActuatorData.catalog[section];
    if (models == null || models.isEmpty) return null;

    final nmRequired = calculateNm(lengthMm, widthMm);

    // Sort ascending by Nm
    final sorted = [...models]
      ..sort((a, b) => a.nmRating.compareTo(b.nmRating));

    final maxModel = sorted.last;

    if (nmRequired <= maxModel.nmRating) {
      // ✅ Pick lowest Nm model that satisfies the requirement
      final model = sorted.firstWhere(
        (m) => m.nmRating >= nmRequired,
        orElse: () => maxModel,
      );
      return ActuatorSelection(
        model:       model,
        quantity:    1,
        unitPrice:   model.price,
        totalPrice:  model.price,
        nmRequired:  nmRequired,
        nmProvided:  model.nmRating,
      );
    } else {
      // ✅ Exceeds max — divide by largest, round UP
      // e.g. 56Nm / 20Nm = 2.8 → 3 units of SM (20Nm)
      final qty = (nmRequired / maxModel.nmRating).ceil();
      return ActuatorSelection(
        model:       maxModel,
        quantity:    qty,
        unitPrice:   maxModel.price,
        totalPrice:  maxModel.price * qty,
        nmRequired:  nmRequired,
        nmProvided:  maxModel.nmRating * qty,
      );
    }
  }
}