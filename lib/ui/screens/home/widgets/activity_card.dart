import 'package:flutter/material.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    required this.title,
    required this.desc,
    required this.backgroundColor,
    required this.borderColor,
    super.key,
    this.onTap,
  });
  final String title;
  final String desc;
  final Color backgroundColor;
  final Color borderColor;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100, // Adjust based on your design
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center, // Center align text inside Text widget
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFCD2222),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            textAlign: TextAlign.center, // Center align text inside Text widget
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
              fontSize: 12,
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
