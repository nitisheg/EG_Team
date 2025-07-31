import 'package:flutter/material.dart';
import 'package:flutterquiz/commons/widgets/custom_image.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    required this.title,
    required this.desc,
    // required this.strokeColor,
    // required this.titleColor,
    super.key,
    this.onTap,
  });

  final String title;
  final String desc;
  // final Color strokeColor;
  // final Color titleColor;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 107,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F7FF),
          borderRadius: BorderRadius.circular(12),
          border: const Border(
            top: BorderSide(
              color: Color(0xFF00C853),
              width: 2,
            ), // Green top border
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFCD2222),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBattleCard({
    required String title,
    required String subtitle,
    required String imageUrl,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 280, // Ensures both cards fit in horizontal scroll
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12, width: 1.5),
        borderRadius: BorderRadius.circular(11),
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              QImage(
                imageUrl: imageUrl,
                width: 40,
                height: 40,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(subtitle),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            onPressed: onPressed,
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
//
// class TodayActivityWidget extends StatelessWidget {
//   const TodayActivityWidget({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Header Row
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 "Today's Activity",
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               TextButton(
//                 onPressed: () {
//                   // Handle view more action
//                 },
//                 child: const Text(
//                   "View More",
//                   style: TextStyle(
//                     color: Colors.blue,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//
//         const SizedBox(height: 8),
//
//         // Quiz Cards Row
//         const Padding(
//           padding: EdgeInsets.symmetric(horizontal: 16.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               ActivityCard(
//                 title: "Quiz of the day",
//                 questionCount: "10 Question",
//                 borderColor: Colors.blue,
//                 textColor: Colors.blue,
//               ),
//               ActivityCard(
//                 title: "Featured Quiz",
//                 questionCount: "15 Question",
//                 borderColor: Colors.purple,
//                 textColor: Colors.purple,
//               ),
//               ActivityCard(
//                 title: "Fun Friday",
//                 questionCount: "10 Question",
//                 borderColor: Colors.green,
//                 textColor: Colors.green,
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// class ActivityCard extends StatelessWidget {
//   final String title;
//   final String questionCount;
//   final Color borderColor;
//   final Color textColor;
//
//   const ActivityCard({
//     super.key,
//     required this.title,
//     required this.questionCount,
//     required this.borderColor,
//     required this.textColor,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 100, // adjust width as needed
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.grey[100],
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: borderColor, width: 2),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             title,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 14,
//               color: textColor,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             questionCount,
//             style: const TextStyle(
//               color: Colors.black54,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
