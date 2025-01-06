// import 'package:flutter/material.dart';
// import '../../models/subscription_plan.dart';

// class PlanCard extends StatelessWidget {
//   final SubscriptionPlan plan;
//   final VoidCallback onSelect;

//   const PlanCard({
//     Key? key,
//     required this.plan,
//     required this.onSelect,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.symmetric(vertical: 8),
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Text(
//               plan.name,
//               style: Theme.of(context).textTheme.headline6,
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 8),
//             Text(
//               '\$${plan.price.toStringAsFixed(2)}',
//               style: Theme.of(context).textTheme.headline5?.copyWith(
//                 color: Theme.of(context).primaryColor,
//                 fontWeight: FontWeight.bold,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 16),
//             ...plan.features.map((feature) => Padding(
//               padding: EdgeInsets.symmetric(vertical: 4),
//               child: Row(
//                 children: [
//                   Icon(Icons.check_circle, color: Colors.green),
//                   SizedBox(width: 8),
//                   Text(feature),
//                 ],
//               ),
//             )).toList(),
//             SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: onSelect,
//               child: Text('Select Plan'),
//               style: ElevatedButton.styleFrom(
//                 padding: EdgeInsets.symmetric(vertical: 12),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
