import 'package:greentech_qoute/features/quotes/constants/products.dart';

class PricingService {
  static const double markupDealer        = 1.2;
  static const double markupVat           = 1.1;
  static const double markupImported      = 1.5;
  static const int    minPricingDimension = 250;
  static const double fusibleLinkCost     = 700.0;
  static const int    fusibleLinkThreshold = 600;

  static double getCombinedMultiplier(Product product, String material, Set<String> customizations) {
    double total = product.multiplierFor(material);
    for (final custom in customizations) {
      switch (custom) {
        case 'obvd':    total += 5.5; break;
        case 'bird':    total += 1.5; break;
        case 'insect':  total += 1.5; break;
        case 'acrylic': total += 0.1; break;
        case 'radial':  total += 0.3; break;
        case 'powder':  break;
      }
    }
    return total;
  }

  static double calculateUnitPrice(Product? product, String material, int length, int width, Set<String> customizations) {
    if (product == null) return 0;

    if (product.isRound && product.roundPrices != null) {
      final roundBase = product.roundPrices![length] ?? product.basePrice;
      double price = roundBase * 1.1 * 1.5;
      for (final custom in customizations) {
        switch (custom) {
          case 'radial': price += 0.3; break;
          case 'bird':   price += 1.5; break;
          case 'insect': price += 1.5; break;
        }
      }
      return price;
    }

    int effectiveLength = length;
    int effectiveWidth  = width;
    final bool isLinearSlot = product.displayName.toLowerCase().contains('linear slot');

    if (isLinearSlot) {
      final int slotWidthMm = width * 45;
      effectiveWidth = slotWidthMm;
      if (customizations.contains('obvd')) {
        final bool lengthBig = length >= minPricingDimension;
        final bool slotBig   = slotWidthMm >= minPricingDimension;
        if      (lengthBig && !slotBig)  effectiveWidth  = slotWidthMm + 50;
        else if (!lengthBig && slotBig)  effectiveLength = length + 50;
      }
    } else {
      final bool lengthBig = length >= minPricingDimension;
      final bool widthBig  = width  >= minPricingDimension;
      if      (!lengthBig && !widthBig) { effectiveLength = minPricingDimension; effectiveWidth = minPricingDimension; }
      else if (lengthBig && !widthBig)    effectiveWidth  = width + 50;
      else if (!lengthBig && widthBig)    effectiveLength = length + 50;
    }

    return effectiveLength * effectiveWidth / 624 * getCombinedMultiplier(product, material, customizations);
  }

  static double applyFlatFees(double price, Set<String> customizations) {
    if (customizations.contains('powder')) return price + 500;
    return price;
  }

  static int calculateFusibleLinkCount(int length, int width) {
    if (length <= fusibleLinkThreshold && width <= fusibleLinkThreshold) return 1;
    return (length / fusibleLinkThreshold).ceil() + (width / fusibleLinkThreshold).ceil();
  }

  static double roundPrice(double price) {
    final int priceInt  = price.ceil();
    final int remainder = priceInt % 100;
    if (remainder == 0)   return priceInt.toDouble();
    if (remainder <= 10)  return (priceInt - remainder).toDouble();
    return (priceInt + (100 - remainder)).toDouble();
  }
}