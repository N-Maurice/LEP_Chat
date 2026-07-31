import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class LegalEducationScreen extends StatefulWidget {
  const LegalEducationScreen({super.key});

  @override
  State<LegalEducationScreen> createState() => _LegalEducationScreenState();
}

class _LegalEducationScreenState extends State<LegalEducationScreen> {
  // 0 = Labour Law 101, 1 = Business Compliance
  int _selectedTrack = 0;

  // Course progress is mutable so "Start Learning" can move it later
  double _contractsCourseProgress = 0.85;

  void _selectTrack(int index) {
    setState(() {
      _selectedTrack = index;
    });
  }

  void _continueContractsCourse() {
    setState(() {
      if (_contractsCourseProgress < 1.0) {
        _contractsCourseProgress = (_contractsCourseProgress + 0.05).clamp(0.0, 1.0);
      }
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
              child: const Icon(Icons.menu_book, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'Legal Education',
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
              _buildFeaturedLesson(),
              const SizedBox(height: 20),
              const Text(
                'Learning Tracks',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildTrackChips(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Courses',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text(
                      'View All',
                      style: TextStyle(color: Color(0xFFE53935), fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildContractsCourseCard(),
              const SizedBox(height: 14),
              _buildGdprCourseCard(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedLesson() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Container(
            height: 170,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3A2E25), Color(0xFF1C1712)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Featured Lesson',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Understanding Your\nConstitutional Rights',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white70, size: 13),
                    const SizedBox(width: 4),
                    const Text('45 mins', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(width: 12),
                    const Icon(Icons.bar_chart, color: Colors.white70, size: 13),
                    const SizedBox(width: 4),
                    const Text('Introductory', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackChips() {
    final tracks = ['Labour Law 101', 'Business Compliance'];

    return Row(
      children: List.generate(tracks.length, (index) {
        final isSelected = _selectedTrack == index;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => _selectTrack(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey[300]!,
                ),
              ),
              child: Text(
                tracks[index],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black54,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildContractsCourseCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Drafting Secure\nEmployment Contracts',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.3),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'MODULE 3',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Learn the essential clauses every HR\nprofessional needs to protect the company\nand employee.',
            style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.3),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progress', style: TextStyle(fontSize: 11, color: Colors.black54)),
              Text(
                '${(_contractsCourseProgress * 100).round()}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _contractsCourseProgress,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: _continueContractsCourse,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text(
                'Start Learning',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGdprCourseCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Data Privacy & GDPR\nBasics',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.3),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'MODULE 1',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'A foundational guide to international data\nprotection standards and implementation.',
                  style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
