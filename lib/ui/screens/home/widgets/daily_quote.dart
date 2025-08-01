import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterquiz/commons/widgets/custom_image.dart';
import 'package:flutterquiz/core/constants/assets_constants.dart';
import 'package:flutterquiz/features/auth/auth_local_data_source.dart';
import 'package:intl/intl.dart';

class DailyQuoteScreen extends StatefulWidget {
  const DailyQuoteScreen({super.key});

  @override
  State<DailyQuoteScreen> createState() => _DailyQuoteScreenState();
}

class _DailyQuoteScreenState extends State<DailyQuoteScreen> {
  final TextEditingController _quoteController = TextEditingController();
  bool _hasSubmitted = false;
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadySubmitted();
  }

  Future<void> _checkIfAlreadySubmitted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docId = '${user.uid}_$today';

    final doc = await FirebaseFirestore.instance
        .collection('daily_quotes')
        .doc(docId)
        .get();

    setState(() {
      _hasSubmitted = doc.exists;
    });
  }

  Future<void> _submitQuote(String quoteText) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    var userName = 'Anonymous';

    try {
      // TEMP: use custom user ID (e.g., "3") instead of Firebase UID
      // const customUserId = 'user1'; // ✅ replace this with actual logic if needed
      // final customUserId = await AuthLocalDataSource.getUserFirebaseId();

      final querySnapshot = await FirebaseFirestore.instance
          .collection('multiUserBattleRoom')
          .where('user1.uid')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        final user1 = data['user1'] as Map<String, dynamic>?;

        if (user1 != null) {
          userName = user1['name']?.toString() ?? 'Anonymous';
        } else {}
      } else {}

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final docId = '${user.uid}_$today';

      await FirebaseFirestore.instance
          .collection('daily_quotes')
          .doc(docId)
          .set({
        'userName': user.displayName,
        'quote': quoteText,
        'submittedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _hasSubmitted = true;
        _quoteController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quote submitted successfully!')),
      );
    } catch (e, stackTrace) {
      debugPrint('StackTrace: $stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit quote.')),
      );
    }
  }

  void _showSubmitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Submit Today's Quote",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: SizedBox(
          height: 100,
          child: TextField(
            controller: _quoteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter your quote...',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = _quoteController.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(context);
                _submitQuote(text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCD2222),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(String quote, String userName, Timestamp submittedAt) {
    final date = submittedAt.toDate();
    final now = DateTime.now();

    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    final dateText = isToday
        ? 'Today'
        : DateFormat('dd MMM yyyy').format(date); // e.g. 24 Jul 2025

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      // decoration: BoxDecoration(
      //   color: Colors.blue[50],
      //   borderRadius: BorderRadius.circular(16),
      //   border: Border.all(color: Colors.grey.shade300),
      // ),
      child: Column(
        children: [
          Text(
            '"$quote"',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$dateText | Submitted by $userName',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDotsIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == i
                ? Theme.of(context).primaryColor
                : Colors.grey[300],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('daily_quotes')
              .orderBy('submittedAt', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              );
            }

            final quotes = snapshot.data!.docs;

            if (quotes.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Text('No quotes submitted yet.'),
              );
            }

            return Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.25,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: quotes.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, index) {
                      return PageView.builder(
                        controller: _pageController,
                        itemCount: quotes.length,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemBuilder: (context, index) {
                          final quoteData =
                              quotes[index].data()! as Map<String, dynamic>;
                          final quote = (quoteData['quote'] ?? '') as String;
                          final userName =
                              (quoteData['userName'] ?? 'Anonymous') as String;
                          final submittedAt = (quoteData['submittedAt'] ??
                              Timestamp.now()) as Timestamp;

                          return _buildQuoteCard(quote, userName, submittedAt);
                        },
                      );
                    },
                  ),
                ),
                _buildDotsIndicator(quotes.length),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _hasSubmitted ? null : _showSubmitDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _hasSubmitted ? 'Submitted' : 'Submit Quote',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const QImage(
                imageUrl: Assets.penLineIcon,
                color: Colors.white,
                width: 15,
                height: 15,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
