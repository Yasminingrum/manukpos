// widgets/pos_cart_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/product.dart';

class PosCartItem extends StatefulWidget {
  final String name;
  final Product product;
  final double quantity;
  final double price;
  final double subtotal;
  final bool allowFractions;
  final Function(double) onQuantityChanged;
  final VoidCallback onRemove;

  const PosCartItem({
    super.key,
    required this.name,
    required this.product,
    required this.quantity,
    required this.price,
    required this.subtotal,
    required this.allowFractions,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  State<PosCartItem> createState() => _PosCartItemState();
}

class _PosCartItemState extends State<PosCartItem> {
  late TextEditingController _quantityController;
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.quantity.toString());
  }

  @override
  void didUpdateWidget(PosCartItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity) {
      _quantityController.text = widget.quantity.toString();
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _updateQuantity(double value) {
    widget.onQuantityChanged(value);
    _quantityController.text = value.toString();
    _quantityController.selection = TextSelection.fromPosition(
      TextPosition(offset: _quantityController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product image or icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: widget.product.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          widget.product.isService
                              ? Icons.miscellaneous_services
                              : Icons.inventory_2,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    )
                  : Icon(
                      widget.product.isService
                          ? Icons.miscellaneous_services
                          : Icons.inventory_2,
                      color: Colors.grey.shade400,
                    ),
            ),
            const SizedBox(width: 12),
            
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(widget.price),
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Quantity controls
            Row(
              children: [
                // Decrease button
                IconButton(
                  onPressed: () {
                    final newValue = widget.quantity - (widget.allowFractions ? 0.5 : 1);
                    if (newValue > 0) {
                      _updateQuantity(newValue);
                    }
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppTheme.primaryColor,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                
                // Quantity input
                SizedBox(
                  width: 40,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: widget.allowFractions
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final parsedValue = double.tryParse(value);
                      if (parsedValue != null && parsedValue > 0) {
                        // If not allowing fractions, ensure it's an integer
                        final adjustedValue = widget.allowFractions
                            ? parsedValue
                            : parsedValue.roundToDouble();
                        widget.onQuantityChanged(adjustedValue);
                      }
                    },
                  ),
                ),
                
                // Increase button
                IconButton(
                  onPressed: () {
                    _updateQuantity(widget.quantity + (widget.allowFractions ? 0.5 : 1));
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppTheme.primaryColor,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            
            const SizedBox(width: 8),
            
            // Subtotal and remove button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(widget.subtotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}