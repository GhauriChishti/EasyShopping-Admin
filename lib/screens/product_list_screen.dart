import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../widgets/product_card.dart';
import 'edit_product_screen.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _confirmAndDeleteProduct(
    BuildContext context,
    String productId,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: const Text('Are you sure you want to delete this product?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('products').doc(productId).delete();
      _showSnackBar(context, 'Product deleted successfully.');
    } on FirebaseException catch (e) {
      _showSnackBar(
        context,
        'Delete failed (${e.code}): ${e.message ?? 'Please try again.'}',
      );
    } catch (e) {
      _showSnackBar(context, 'Unexpected error: $e');
    }
  }

  Future<void> _openEditScreen(
    BuildContext context,
    String productId,
    Map<String, dynamic> product,
  ) async {
    final didUpdate = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditProductScreen(
          productId: productId,
          initialName: (product['name'] ?? '').toString(),
          initialPrice: (product['price'] ?? '').toString(),
          initialDescription: (product['description'] ?? '').toString(),
          initialCategory: (product['category'] ?? '').toString(),
        ),
      ),
    );

    if (didUpdate == true) {
      _showSnackBar(context, 'Product list refreshed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product List')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load products.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No products available.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final productDoc = docs[index];
              final product = productDoc.data();
              return ProductCard(
                name: (product['name'] ?? '').toString(),
                price: (product['price'] ?? '').toString(),
                category: (product['category'] ?? '').toString(),
                imageUrl: (product['imageUrl'] ?? '').toString(),
                onEdit: () => _openEditScreen(context, productDoc.id, product),
                onDelete: () => _confirmAndDeleteProduct(
                  context,
                  productDoc.id,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
