import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  Future<void> _updateOrderStatus({
    required BuildContext context,
    required String orderId,
    required String newStatus,
  }) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({'status': newStatus});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order status updated'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Orders'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Could not load orders. Please try again.'),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('No orders found.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final orderDoc = docs[index];
              final data = orderDoc.data();

              final customerEmail = data['customerEmail']?.toString() ?? 'N/A';
              final totalPrice = data['totalPrice']?.toString() ?? '0';
              final paymentMethod = data['paymentMethod']?.toString() ?? 'N/A';
              final status = data['status']?.toString() ?? 'N/A';
              final createdAt = _formatCreatedAt(data['createdAt']);
              final itemCount = _getItemCount(data['items']);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ID: ${orderDoc.id}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text('Customer Email: $customerEmail'),
                      Text('Total Price: $totalPrice'),
                      Text('Payment Method: $paymentMethod'),
                      Text('Status: $status'),
                      Text('Created At: $createdAt'),
                      Text('Item Count: $itemCount'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: status == 'confirmed'
                                ? null
                                : () => _updateOrderStatus(
                                      context: context,
                                      orderId: orderDoc.id,
                                      newStatus: 'confirmed',
                                    ),
                            child: const Text('Confirm Order'),
                          ),
                          ElevatedButton(
                            onPressed: status == 'shipped'
                                ? null
                                : () => _updateOrderStatus(
                                      context: context,
                                      orderId: orderDoc.id,
                                      newStatus: 'shipped',
                                    ),
                            child: const Text('Mark Shipped'),
                          ),
                          ElevatedButton(
                            onPressed: status == 'delivered'
                                ? null
                                : () => _updateOrderStatus(
                                      context: context,
                                      orderId: orderDoc.id,
                                      newStatus: 'delivered',
                                    ),
                            child: const Text('Mark Delivered'),
                          ),
                          ElevatedButton(
                            onPressed: status == 'cancelled'
                                ? null
                                : () => _updateOrderStatus(
                                      context: context,
                                      orderId: orderDoc.id,
                                      newStatus: 'cancelled',
                                    ),
                            child: const Text('Cancel Order'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatCreatedAt(dynamic rawValue) {
    if (rawValue is Timestamp) {
      final dateTime = rawValue.toDate();
      return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)} '
          '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
    }

    if (rawValue is String && rawValue.isNotEmpty) {
      return rawValue;
    }

    return 'N/A';
  }

  int _getItemCount(dynamic items) {
    if (items is List) {
      return items.length;
    }

    return 0;
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}
