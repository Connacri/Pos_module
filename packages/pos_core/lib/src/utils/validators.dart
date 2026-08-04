class Validators {
  Validators._();

  static String? required(String? value, [String fieldName = 'Ce champ']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Email invalide';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^\+?[\d\s\-]{8,15}$');
    if (!regex.hasMatch(value)) return 'Numéro de téléphone invalide';
    return null;
  }

  static String? positiveNumber(String? value) {
    if (value == null || value.isEmpty) return null;
    final number = double.tryParse(value.replaceAll(',', '.'));
    if (number == null || number < 0) return 'Doit être un nombre positif';
    return null;
  }

  static String? percent(String? value) {
    if (value == null || value.isEmpty) return null;
    final number = double.tryParse(value.replaceAll(',', '.'));
    if (number == null) return 'Doit être un nombre';
    if (number < 0 || number > 100) return 'Entre 0 et 100';
    return null;
  }

  static String? integer(String? value) {
    if (value == null || value.isEmpty) return null;
    final number = int.tryParse(value);
    if (number == null || number < 0) return 'Doit être un nombre entier positif';
    return null;
  }

  static String? sku(String? value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^[A-Z0-9\-]{3,30}$');
    if (!regex.hasMatch(value.toUpperCase())) {
      return 'SKU invalide (3-30 caractères alphanumériques)';
    }
    return null;
  }
}
