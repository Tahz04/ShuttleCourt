import 'package:flutter/material.dart';
import 'package:shuttlecourt/theme/app_theme.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedLanguage = 'Tiếng Việt';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('Ngôn ngữ', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildLanguageTile('Tiếng Việt', 'vn'),
          const SizedBox(height: 16),
          _buildLanguageTile('English', 'us'),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(String language, String flagCode) {
    final bool isSelected = _selectedLanguage == language;
    return InkWell(
      onTap: () => setState(() => _selectedLanguage = language),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: AppTheme.accent, width: 2) : Border.all(color: Colors.transparent, width: 2),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Text(flagCode == 'vn' ? '🇻🇳' : '🇺🇸', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Text(language, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppTheme.accent),
          ],
        ),
      ),
    );
  }
}
