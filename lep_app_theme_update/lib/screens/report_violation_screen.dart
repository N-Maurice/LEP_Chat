import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ReportViolationScreen extends StatefulWidget {
  const ReportViolationScreen({super.key});

  @override
  State<ReportViolationScreen> createState() => _ReportViolationScreenState();
}

class _ReportViolationScreenState extends State<ReportViolationScreen> {
  // Keeps track of which category card is currently selected
  String? _selectedCategory;

  final TextEditingController _descriptionController = TextEditingController();

  final List<_CategoryItem> _categories = const [
    _CategoryItem(label: 'Corruption', icon: Icons.account_balance),
    _CategoryItem(label: 'Labour Abuse', icon: Icons.groups_outlined),
    _CategoryItem(label: 'Fraud', icon: Icons.warning_amber_rounded),
    _CategoryItem(label: 'GBV', icon: Icons.shield_outlined),
    _CategoryItem(label: 'Environment', icon: Icons.eco_outlined),
    _CategoryItem(label: 'Other', icon: Icons.more_horiz),
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _selectCategory(String label) {
    setState(() {
      // tapping the same category again deselects it
      _selectedCategory = _selectedCategory == label ? null : label;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'Report a Violation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.notifications_none, color: Colors.black54),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepper(),
              const SizedBox(height: 20),
              const Text(
                'Select Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'What type of violation are you reporting?',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              _buildCategoryGrid(),
              const SizedBox(height: 20),
              const Text(
                'Description of Incident',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              _buildDescriptionField(),
              const SizedBox(height: 24),
              _buildContinueButton(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      children: [
        _stepCircle(number: '1', label: 'Incident', isActive: true),
        _stepLine(),
        _stepCircle(number: '2', label: 'Location', isActive: false),
        _stepLine(),
        _stepCircle(number: '3', label: 'Evidence', isActive: false),
      ],
    );
  }

  Widget _stepCircle({
    required String number,
    required String label,
    required bool isActive,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isActive ? AppColors.primary : Colors.grey[300],
          child: Text(
            number,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? Colors.black : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _stepLine() {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: Colors.grey[300],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, index) {
        final item = _categories[index];
        final isSelected = _selectedCategory == item.label;

        return GestureDetector(
          onTap: () => _selectCategory(item.label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey[300]!,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? AppColors.primary : Colors.black54,
                ),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppColors.primary : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: _descriptionController,
        maxLines: 5,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.all(14),
          border: InputBorder.none,
          hintText: 'Please provide detailed information about\n'
              'what happened, who was involved, and\nany specific dates...',
          hintStyle: TextStyle(fontSize: 13, color: Colors.black38),
        ),
        // simple setState hook so you can track text length, validation, etc.
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildContinueButton() {
    final bool canContinue =
        _selectedCategory != null && _descriptionController.text.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          // Hook up navigation to the "Location" step here later
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Continue to Location tapped')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: canContinue ? AppColors.primary : Colors.grey[400],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Continue to Location',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String label;
  final IconData icon;
  const _CategoryItem({required this.label, required this.icon});
}
