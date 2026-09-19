import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LanguageOption {
  final String code;
  final String nativeName;
  final String englishName;
  final String badge;

  const LanguageOption({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.badge,
  });
}

class LanguageModal extends StatelessWidget {
  final String currentLanguageCode;
  final ValueChanged<LanguageOption> onSelect;

  const LanguageModal({
    super.key,
    required this.currentLanguageCode,
    required this.onSelect,
  });

  static const List<LanguageOption> languages = [
    LanguageOption(code: 'en', nativeName: 'English', englishName: 'English (India)', badge: 'Default'),
    LanguageOption(code: 'hi', nativeName: 'हिन्दी', englishName: 'Hindi', badge: 'लोकप्रिय'),
    LanguageOption(code: 'te', nativeName: 'తెలుగు', englishName: 'Telugu', badge: 'జనాదరణ'),
    LanguageOption(code: 'ta', nativeName: 'தமிழ்', englishName: 'Tamil', badge: 'பிரபலம்'),
    LanguageOption(code: 'bn', nativeName: 'বাংলা', englishName: 'Bengali', badge: 'জনপ্রিয়'),
    LanguageOption(code: 'mr', nativeName: 'मराठी', englishName: 'Marathi', badge: 'लोकप्रिय'),
    LanguageOption(code: 'gu', nativeName: 'ગુજરાતી', englishName: 'Gujarati', badge: 'લોકપ્રિય'),
    LanguageOption(code: 'kn', nativeName: 'ಕನ್ನಡ', englishName: 'Kannada', badge: 'ಜನಪ್ರಿಯ'),
    LanguageOption(code: 'ml', nativeName: 'മലയാളം', englishName: 'Malayalam', badge: 'ജനപ്രിയം'),
    LanguageOption(code: 'pa', nativeName: 'ਪੰਜਾਬੀ', englishName: 'Punjabi', badge: 'ਪ੍ਰਸਿੱਧ'),
  ];

  static void show(BuildContext context, {
    required String currentCode,
    required ValueChanged<LanguageOption> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LanguageModal(
        currentLanguageCode: currentCode,
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.neuBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Handle bar
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Modal Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: AppTheme.neuSquircle(radius: 12),
                    child: const Center(
                      child: Text('🌐', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select App Language',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'भाषा चुनें • Voice assistant & UI updates',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Choose your preferred Indian language. This configures the voice assistant and displays clinical guidelines in your dialect:',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withOpacity(0.9)),
              ),
            ),
            const SizedBox(height: 16),

            // Languages Grid / List
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                itemCount: languages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final lang = languages[idx];
                  final isSelected = lang.code == currentLanguageCode;

                  return InkWell(
                    onTap: () {
                      onSelect(lang);
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: isSelected
                          ? AppTheme.neuSunken(radius: 16)
                          : AppTheme.neuRaised(radius: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      lang.nativeName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.primaryLight
                                            : AppTheme.secondaryLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        lang.badge,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? AppTheme.primary : AppTheme.secondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lang.englishName,
                                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: AppTheme.primary, size: 20)
                          else
                            const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
