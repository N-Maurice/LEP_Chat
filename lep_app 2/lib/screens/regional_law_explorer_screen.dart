import 'package:flutter/material.dart';

class RegionalLawExplorerScreen extends StatefulWidget {
  const RegionalLawExplorerScreen({super.key});

  @override
  State<RegionalLawExplorerScreen> createState() => _RegionalLawExplorerScreenState();
}

class _RegionalLawExplorerScreenState extends State<RegionalLawExplorerScreen> {
  String _selectedCommunity = 'East African Community (EAC)';
  String? _selectedCountry = 'Rwanda';

  final List<String> _communities = const [
    'East African Community (EAC)',
    'ECOWAS',
    'SADC',
  ];

  final List<_LawCategory> _lawCategories = const [
    _LawCategory(
      title: 'Constitution',
      subtitle: 'Latest amendment: 2023',
      icon: Icons.menu_book_outlined,
    ),
    _LawCategory(
      title: 'Labour Laws',
      subtitle: 'Employment act & regulations',
      icon: Icons.work_outline,
    ),
    _LawCategory(
      title: 'Land Laws',
      subtitle: 'Ownership & title research',
      icon: Icons.landscape_outlined,
    ),
  ];

  void _openCommunityPicker() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _communities.map((community) {
              return ListTile(
                title: Text(community),
                trailing: community == _selectedCommunity
                    ? const Icon(Icons.check, color: Color(0xFFE53935))
                    : null,
                onTap: () => Navigator.pop(context, community),
              );
            }).toList(),
          ),
        );
      },
    );

    if (choice != null) {
      setState(() {
        _selectedCommunity = choice;
      });
    }
  }

  void _clearSelectedCountry() {
    setState(() {
      _selectedCountry = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F6),
        elevation: 0,
        foregroundColor: Colors.black,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.public, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'Regional Law Explorer',
              style: TextStyle(
                fontSize: 15,
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
              _buildCommunitySelector(),
              const SizedBox(height: 14),
              _buildTapRegionHint(),
              const SizedBox(height: 20),
              if (_selectedCountry != null) _buildSelectedCountryChip(),
              const SizedBox(height: 12),
              ..._lawCategories.map((category) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildLawCategoryTile(category),
                  )),
              const SizedBox(height: 8),
              _buildDeepDiveButton(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunitySelector() {
    return GestureDetector(
      onTap: _openCommunityPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedCommunity,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildTapRegionHint() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_outlined, size: 16, color: Colors.black54),
            SizedBox(width: 6),
            Text(
              'Tap a region to explore jurisdiction',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedCountryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Simple flag-style swatch instead of a real flag asset
          Container(
            width: 32,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: const LinearGradient(
                colors: [Color(0xFF20603D), Color(0xFFFAD201), Color(0xFF00A1DE)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCountry!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Row(
                  children: const [
                    Icon(Icons.verified, size: 13, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Verified Jurisdiction',
                      style: TextStyle(fontSize: 11, color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _clearSelectedCountry,
            icon: const Icon(Icons.close, size: 18, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildLawCategoryTile(_LawCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFBE9E7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(category.icon, color: const Color(0xFFE53935), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(category.subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black38),
        ],
      ),
    );
  }

  Widget _buildDeepDiveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE53935),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Deep Dive Into Research',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _LawCategory {
  final String title;
  final String subtitle;
  final IconData icon;
  const _LawCategory({required this.title, required this.subtitle, required this.icon});
}
