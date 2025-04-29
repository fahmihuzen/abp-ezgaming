import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class PurchaseHistoryPage extends StatefulWidget {
  final String userEmail;

  const PurchaseHistoryPage({
    Key? key,
    required this.userEmail,
  }) : super(key: key);

  @override
  State<PurchaseHistoryPage> createState() => _PurchaseHistoryPageState();
}

class _PurchaseHistoryPageState extends State<PurchaseHistoryPage> {
  List<Map<String, dynamic>> purchases = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost/abp/get_purchases.php?email=${widget.userEmail}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            purchases = List<Map<String, dynamic>>.from(data['purchases']);
            isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load purchases');
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat riwayat: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Pembelian',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF280031),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF280031), Color(0xFF1A0021)],
          ),
        ),
        child: isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : errorMessage != null
            ? Center(
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.white),
                ),
              )
            : purchases.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada riwayat pembelian',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: purchases.length,
                  itemBuilder: (context, index) {
                    final purchase = purchases[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Colors.grey.shade50],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order ID: ${purchase['order_id']}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF280031),
                                    ),
                                  ),
                                  _buildStatusBadge(purchase['status']),
                                ],
                              ),
                              const Divider(height: 24),
                              _buildDetailRow('User ID', purchase['user_id']),
                              _buildDetailRow('Zone ID', purchase['zone_id']),
                              _buildDetailRow('Bukti Pembayaran', purchase['payment_proof']),
                              _buildDetailRow('Diamonds', '${purchase['diamonds']} 💎'),
                              _buildDetailRow('Harga', 'Rp ${purchase['price']}'),
                              _buildDetailRow('Metode Pembayaran', purchase['payment_method']),
                              _buildDetailRow('Status', purchase['status']),
                              _buildDetailRow('Tanggal', _formatDate(DateTime.parse(purchase['purchase_date']))),
                              if (purchase['payment_proof'] != null) ...[
                                const SizedBox(height: 16),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    'http://localhost/abp/${purchase['payment_proof']}',
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 200,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.error_outline,
                                            color: Colors.grey,
                                            size: 48,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'success':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'failed':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF280031),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}

class Purchase {
  final String orderId;
  final String userId;
  final String zoneId;
  final String username;
  final int diamondAmount;
  final double price;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;

  Purchase({
    required this.orderId,
    required this.userId,
    required this.zoneId,
    required this.username,
    required this.diamondAmount,
    required this.price,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      orderId: json['order_id'],
      userId: json['user_id'],
      zoneId: json['zone_id'],
      username: json['username'],
      diamondAmount: int.parse(json['diamond_amount'].toString()),
      price: double.parse(json['price'].toString()),
      paymentMethod: json['payment_method'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class PurchaseDetailPage extends StatelessWidget {
  final Purchase purchase;

  const PurchaseDetailPage({
    super.key,
    required this.purchase,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pembelian'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailCard(
              title: 'Informasi Pesanan',
              content: [
                DetailItem(label: 'Order ID', value: purchase.orderId),
                DetailItem(label: 'Status', value: purchase.status),
                DetailItem(label: 'Tanggal', value: _formatDate(purchase.createdAt)),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              title: 'Detail Produk',
              content: [
                DetailItem(label: 'Item', value: '${purchase.diamondAmount} Diamonds'),
                DetailItem(label: 'Harga', value: 'Rp ${purchase.price}'),
                DetailItem(label: 'Metode Pembayaran', value: purchase.paymentMethod),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              title: 'Informasi Akun Game',
              content: [
                DetailItem(label: 'User ID', value: purchase.userId),
                DetailItem(label: 'Zone ID', value: purchase.zoneId),
                DetailItem(label: 'Username', value: purchase.username),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required List<DetailItem> content,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...content.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.label,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        item.value,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}

class DetailItem {
  final String label;
  final String value;

  DetailItem({required this.label, required this.value});
} 