// widgets/product_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';

class ProductItem extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  // Gunakan formatter dari intl package untuk format mata uang
  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  ProductItem({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: product.imageUrl != null && product.imageUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.network(
                    product.imageUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, error, _) => Icon(Icons.image, color: Colors.white),
                  ),
                )
              : Icon(Icons.inventory, color: Colors.white),
        ),
        title: Text(product.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${product.sku}'),
            Text(
              'Harga: ${currencyFormat.format(product.sellingPrice)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            if (product.discountPrice != null)
              Text(
                'Diskon: ${currencyFormat.format(product.discountPrice!)}',
                style: TextStyle(
                  color: Colors.red,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: () {
          // Navigate to product detail screen
          Navigator.of(context).pushNamed(
            '/products/detail',
            arguments: product.id,
          );
        },
      ),
    );
  }
}