import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EZ Gaming',
      theme: ThemeData(
        primaryColor: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const TopUpPage(),
    );
  }
}

class TopUpPage extends StatefulWidget {
  const TopUpPage({super.key});

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final userIdController = TextEditingController();
  final zoneIdController = TextEditingController();
  String? username;
  String? errorMessage;
  Timer? _debounceTimer;
  bool isLoggedIn = false;
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    userIdController.addListener(_onInputChanged);
    zoneIdController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    userIdController.removeListener(_onInputChanged);
    zoneIdController.removeListener(_onInputChanged);
    _debounceTimer?.cancel();
    userIdController.dispose();
    zoneIdController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    _debounceTimer?.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (userIdController.text.length == 9 && zoneIdController.text.length == 4) {
        _validateUser();
      } else {
        setState(() {
          username = null;
          if (userIdController.text.isNotEmpty || zoneIdController.text.isNotEmpty) {
            errorMessage = 'User ID harus 9 digit dan Zone ID harus 4 digit';
          } else {
            errorMessage = null;
          }
        });
      }
    });
  }

  Future<void> _validateUser() async {
    try {
      final response = await http.post(
        Uri.parse('https://order-sg.codashop.com/validate'),
        headers: {
          'accept': 'application/json, text/plain, */*',
          'content-type': 'application/json',
          'origin': 'https://www.codashop.com',
        },
        body: jsonEncode({
          'country': 'sg',
          'voucherTypeName': 'MOBILE_LEGENDS',
          'whiteLabelId': '',
          'deviceId': 'e336d25e-dff8-4029-8b71-2b155b988680',
          'userId': userIdController.text,
          'zoneId': zoneIdController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          username = data['result']['username'];
          errorMessage = null;
        });
      } else {
        throw Exception('Failed to validate user');
      }
    } catch (e) {
      setState(() {
        username = null;
        errorMessage = 'Username tidak ditemukan';
      });
    }
  }

  void _showPaymentPage(DiamondPackage package) {
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu untuk melakukan pembelian'),
          backgroundColor: Colors.red,
        ),
      );
      _showLoginDialog();
      return;
    }

    if (username == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap masukkan User ID dan Zone ID yang valid terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentMethodPage(
          package: package,
          userId: userIdController.text,
          zoneId: zoneIdController.text,
          username: username,
          userEmail: userEmail,
        ),
      ),
    );
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => LoginDialog(
        onLoginSuccess: (email) {
          setState(() {
            isLoggedIn = true;
            userEmail = email;
          });
        },
      ),
    );
  }

  void _showRegisterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => RegisterDialog(),
    );
  }

  void _showProfilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(userEmail: userEmail),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF280031),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/gz_gaming_logo.png',
                height: 40,
              ),
              if (isLoggedIn) ...[
                const SizedBox(height: 12),
                Text(
                  'Halo,',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  userEmail,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        Container(
          height: 1,
          width: double.infinity,
          color: Colors.grey[300],
        ),
      ],
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.deepPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            Image.asset('assets/gz_gaming_logo.png', height: 30),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'EZ Gaming',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Solusi top up diamond terpercaya dan termurah',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!isLoggedIn)
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8E24AA), Color(0xFFAB47BC)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8E24AA).withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => _showRegisterDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Daftar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () {
                setState(() {
                  isLoggedIn = false;
                  userEmail = '';
                });
              },
            ),
        ],
      ),
      drawer: Drawer(
        child: _buildDrawerContent(),
      ),
      body: Container(
        color: const Color(0xFF280031),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xFF280031),
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Mobile Legends: Bang Bang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFeatureBox(
                      icon: Icons.security,
                      text: 'Pembayaran yang Aman',
                    ),
                    const SizedBox(width: 8),
                    _buildFeatureBox(
                      icon: Icons.support_agent,
                      text: 'Layanan Pelanggan 24/7',
                    ),
                  ],
                ),
              ),

              // User ID Input Section dengan background putih dan border radius
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildInputSection(),
              ),

              // Diamond Packages Section dengan background putih dan border radius
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Center(
                            child: Text(
                              '2',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Pilih Nominal Top Up',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.pink[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_fire_department, color: Colors.pink[400], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '29,491 item dibeli dalam satu jam terakhir',
                            style: TextStyle(
                              color: Colors.pink[400],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildDiamondGrid(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBox({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,  // Mengembalikan ke warna putih
        borderRadius: BorderRadius.circular(20),  // Mempertahankan border radius besar
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,  // Tetap compact
        children: [
          Icon(icon, color: Colors.deepPurple, size: 18),  // Icon ungu
          const SizedBox(width: 6),  // Jarak kecil antara icon dan teks
          Text(
            text.replaceAll('\n', ' '),
            style: const TextStyle(
              color: Colors.deepPurple,  // Teks ungu
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiamondGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,  // Membuat card lebih tinggi
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: diamondPackages.length,
      itemBuilder: (context, index) {
        final package = diamondPackages[index];
        return _buildDiamondPackage(package);
      },
    );
  }

  Widget _buildDiamondPackage(DiamondPackage package) {
    return GestureDetector(
      onTap: username != null 
          ? () => _showPaymentPage(package)
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Harap masukkan User ID dan Zone ID yang valid terlebih dahulu'),
                  backgroundColor: Colors.red,
                ),
              );
            },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.blue.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Diamond Amount
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(
                    '${package.diamonds} Diamonds',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (package.bonus != null)
                    Text(
                      '(${package.bonus})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Diamond Icon
            Image.asset(
              getImageAsset(package.diamonds),
              height: 50,
              width: 50,
            ),
            const SizedBox(height: 16),
            
            // Price
            Text(
              'Rp. ${package.price}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getImageAsset(int diamonds) {
    if (diamonds <= 44) {
      return 'assets/10_MLBB_NewDemom.png';
    } else if (diamonds <= 85) {
      return 'assets/50_MLBB_NewDemom.png';
    } else if (diamonds <= 408) {
      return 'assets/150x250_MLBB_NewDemom.png';
    } else if (diamonds <= 875) {
      return 'assets/500_MLBB_NewDemom.png';
    } else if (diamonds <= 2010) {
      return 'assets/1500_MLBB_NewDemom.png';
    } else {
      return 'assets/2500_MLBB_NewDemom.png';
    }
  }

  Widget _buildInputSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Masukkan User ID',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: userIdController,
                  keyboardType: TextInputType.number,
                  maxLength: 9,
                  decoration: InputDecoration(
                    hintText: 'Masukkan User ID (9 digit)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: zoneIdController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    hintText: 'Zone ID (4 digit)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    counterText: '',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.help),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          if (errorMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          
          if (username != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Username: $username',
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 8),
          const Text(
            'Untuk mengetahui User ID Anda, silakan klik menu profile dibagian kiri atas pada menu utama game. User ID akan terlihat dibagian bawah Nama Karakter Game Anda.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerContent() {
    return Column(
      children: [
        _buildDrawerHeader(),
        const SizedBox(height: 24),
        if (isLoggedIn) ...[
          // Profile button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showProfilePage(),
              icon: const Icon(Icons.person, color: Colors.white),
              label: const Text('Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // History button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PurchaseHistoryPage(userEmail: userEmail),
                  ),
                );
              },
              icon: const Icon(Icons.history, color: Colors.white),
              label: const Text('Riwayat Pemesanan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Logout button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoggedIn = false;
                  userEmail = '';
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Keluar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ] else ...[
          _buildFeatureItem(
            icon: Icons.star,
            text: 'Jadilah yang pertama mengetahui promo dan penawaran ekslusif!',
          ),
          _buildFeatureItem(
            icon: Icons.history,
            text: 'Akses riwayat pesanan anda dengan mudah',
          ),
          _buildFeatureItem(
            icon: Icons.security,
            text: 'Lebih cepat dan aman',
          ),
          const SizedBox(height: 24),
          // Login and register buttons for non-logged in users
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () => _showRegisterDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Daftar sekarang, gratis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: () => _showLoginDialog(),
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text(
                'Masuk',
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        const Spacer(),
      ],
    );
  }
}

class DiamondPackage {
  final int diamonds;
  final String price;
  final String? bonus;

  DiamondPackage({
    required this.diamonds,
    required this.price,
    this.bonus,
  });
}

final List<DiamondPackage> diamondPackages = [
  DiamondPackage(diamonds: 3, price: '1.171'),
  DiamondPackage(diamonds: 5, price: '1.423'),
  DiamondPackage(diamonds: 12, price: '3.323'),
  DiamondPackage(diamonds: 19, price: '5.223'),
  DiamondPackage(diamonds: 28, price: '7.600', bonus: '+2 Diamonds'),
  DiamondPackage(diamonds: 44, price: '11.400', bonus: '+4 Diamonds'),
  DiamondPackage(diamonds: 59, price: '15.200', bonus: '+6 Diamonds'),
  DiamondPackage(diamonds: 85, price: '21.850', bonus: '+8 Diamonds'),
  DiamondPackage(diamonds: 170, price: '43.700', bonus: '+20 Diamonds'),
  DiamondPackage(diamonds: 240, price: '61.750', bonus: '+25 Diamonds'),
  DiamondPackage(diamonds: 296, price: '76.000', bonus: '+40 Diamonds'),
  DiamondPackage(diamonds: 408, price: '104.500', bonus: '+50 Diamonds'),
  DiamondPackage(diamonds: 568, price: '142.500', bonus: '+75 Diamonds'),
  DiamondPackage(diamonds: 875, price: '218.500', bonus: '+100 Diamonds'),
  DiamondPackage(diamonds: 2010, price: '475.000', bonus: '+200 Diamonds'),
  DiamondPackage(diamonds: 4830, price: '1.140.000', bonus: '+500 Diamonds'),
];

class AppStyles {
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.black.withOpacity(0.1),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.purple.withOpacity(0.1),
        spreadRadius: 0,
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static EdgeInsets cardPadding = const EdgeInsets.all(16);
  static double elementSpacing = 16.0;
}

class PaymentMethodPage extends StatelessWidget {
  final DiamondPackage package;
  final String userId;
  final String zoneId;
  final String? username;
  final String userEmail;

  const PaymentMethodPage({
    super.key,
    required this.package,
    required this.userId,
    required this.zoneId,
    this.username,
    required this.userEmail,
  });

  void _proceedToPaymentConfirmation(BuildContext context, String method) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentConfirmationPage(
          package: package,
          userId: userId,
          zoneId: zoneId,
          username: username,
          paymentMethod: method,
          userEmail: userEmail,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Pembayaran'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Detail Pembelian Card
            Container(
              decoration: AppStyles.cardDecoration,
              padding: AppStyles.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detail Pembelian',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DetailRow(label: 'User ID', value: userId),
                  DetailRow(label: 'Username', value: username ?? '-'),
                  DetailRow(label: 'Item', value: '${package.diamonds} Diamonds'),
                  DetailRow(label: 'Harga', value: 'Rp. ${package.price}'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment Methods Section
            const Text(
              'Pilih Pembayaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // DANA
            _buildPaymentMethodButton(
              context,
              'DANA',
              'assets/dana_logo.png',
              onTap: () => _proceedToPaymentConfirmation(context, 'DANA'),
            ),
            const SizedBox(height: 12),
            
            // QRIS
            _buildPaymentMethodButton(
              context,
              'QRIS',
              'assets/qris_logo.png',
              onTap: () => _proceedToPaymentConfirmation(context, 'QRIS'),
            ),
            const SizedBox(height: 12),
            
            // BCA
            _buildPaymentMethodButton(
              context,
              'BCA',
              'assets/bca_logo.png',
              onTap: () => _proceedToPaymentConfirmation(context, 'BCA'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodButton(
    BuildContext context,
    String name,
    String logoPath, {
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: AppStyles.cardDecoration,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Image.asset(
                logoPath,
                height: 30,
                width: 60,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 16),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentConfirmationPage extends StatefulWidget {
  final DiamondPackage package;
  final String userId;
  final String zoneId;
  final String? username;
  final String paymentMethod;
  final String userEmail;

  const PaymentConfirmationPage({
    super.key,
    required this.package,
    required this.userId,
    required this.zoneId,
    required this.username,
    required this.paymentMethod,
    required this.userEmail,
  });

  @override
  State<PaymentConfirmationPage> createState() => _PaymentConfirmationPageState();
}

class _PaymentConfirmationPageState extends State<PaymentConfirmationPage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _savePurchaseToDatabase(String orderId) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost/abp/save_purchases.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'user_id': widget.userId,
          'zone_id': widget.zoneId,
          'diamonds': widget.package.diamonds,
          'price': widget.package.price,
          'payment_method': widget.paymentMethod,
          'payment_proof': _image?.path ?? '',
          'user_email': widget.userEmail,
        }),
      );

      final data = jsonDecode(response.body);
      if (!data['success']) {
        throw Exception(data['message']);
      }
    } catch (e) {
      print('Error saving purchase: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Detail Pesanan Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detail Pesanan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      DetailRow(label: 'User ID', value: widget.userId),
                      DetailRow(label: 'Username', value: widget.username ?? '-'),
                      DetailRow(label: 'Email', value: widget.userEmail),
                      DetailRow(
                        label: 'Item',
                        value: '${widget.package.diamonds} Diamonds',
                      ),
                      DetailRow(label: 'Total', value: 'Rp. ${widget.package.price}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Instruksi Pembayaran Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Instruksi Pembayaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      _buildPaymentInstructions(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Upload Bukti Pembayaran Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload Bukti Pembayaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          final XFile? image = await _picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            setState(() {
                              _image = File(image.path);
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _image != null
                              ? Image.file(
                                  _image!,
                                  height: 150,
                                  fit: BoxFit.contain,
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.upload_outlined,
                                      color: Colors.grey.shade400,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Pilih file bukti pembayaran',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Konfirmasi Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_image == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Harap upload bukti pembayaran'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                    
                    try {
                      await _savePurchaseToDatabase(orderId);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ThankYouPage(
                            orderId: orderId,
                            email: widget.userEmail,
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal menyimpan pembelian: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Konfirmasi Pembayaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    String bankInfo = '';
    String accountNo = '';
    
    switch (widget.paymentMethod) {
      case 'BCA':
        bankInfo = 'Bank/eWallet: BCA';
        accountNo = '0970956603';
        break;
      case 'DANA':
        bankInfo = 'Bank/eWallet: Dana';
        accountNo = '085156558787';
        break;
      case 'QRIS':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transfer sesuai nominal ke:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Image.asset(
              'assets/pembayaran_qris.png',
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            Text(
              'Total Pembayaran: Rp. ${widget.package.price}',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      default:
        return const Text('Metode pembayaran tidak valid');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transfer sesuai nominal ke:',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(bankInfo),
        Text('No Rekening : $accountNo'),
        const Text('Atas Nama: Fahmi Huzen'),
        const SizedBox(height: 8),
        Text(
          'Total Pembayaran: Rp. ${widget.package.price}',
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class ThankYouPage extends StatelessWidget {
  final String orderId;
  final String email;

  const ThankYouPage({
    super.key,
    required this.orderId,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Icon dengan animasi scale
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween<double>(begin: 0.5, end: 1.0),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 80,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                
                // Success Message
                const Text(
                  'Pembayaran Berhasil!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Terima kasih telah melakukan pembelian',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Order Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildDetailItem('Order ID', orderId),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(),
                      ),
                      _buildDetailItem('Email', email.isNotEmpty ? email : '-'),
                    ],
                  ),
                ),
                const Spacer(),
                
                // Back to Home Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Kembali ke Beranda',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Widget untuk menampilkan dialog login
class LoginDialog extends StatefulWidget {
  final Function(String) onLoginSuccess;

  const LoginDialog({
    Key? key,
    required this.onLoginSuccess,
  }) : super(key: key);

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String? errorMessage;
  bool isLoading = false;

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost/abp/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailPhoneController.text,
          'password': _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success']) {
        // Show success message before closing dialog
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 50,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Login Berhasil!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selamat datang, ${_emailPhoneController.text}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          );

          // Wait for 2 seconds before closing both dialogs
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pop(context); // Close success alert
            Navigator.pop(context); // Close login dialog
            widget.onLoginSuccess(_emailPhoneController.text);
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = data['message'] ?? 'Login gagal';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masuk',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailPhoneController,
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : () {
                  if (_emailPhoneController.text.isNotEmpty && 
                      _passwordController.text.isNotEmpty) {
                    _login();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget untuk menampilkan dialog registrasi
class RegisterDialog extends StatefulWidget {
  const RegisterDialog({Key? key}) : super(key: key);

  @override
  State<RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<RegisterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? errorMessage;
  bool isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('http://localhost/abp/register.php'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'password': _passwordController.text,
          }),
        );

        final data = jsonDecode(response.body);
        
        if (data['success']) {
          // Show success message
          if (mounted) {
            setState(() {
              isLoading = false;
            });
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 50,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Registrasi Berhasil!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Silakan login dengan akun yang telah dibuat',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            );

            // Wait for 2 seconds before closing both dialogs
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.pop(context); // Close success alert
              Navigator.pop(context); // Close register dialog
            });
          }
        } else {
          setState(() {
            isLoading = false;
            errorMessage = data['message'];
          });
        }
      } catch (e) {
        setState(() {
          isLoading = false;
          errorMessage = 'Terjadi kesalahan: ${e.toString()}';
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Daftar',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mohon masukkan email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Nomor HP (diawali 62)',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mohon masukkan nomor HP';
                    }
                    if (!value.startsWith('62')) {
                      return 'Nomor HP harus diawali dengan 62';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mohon masukkan password';
                    }
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Konfirmasi Password',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mohon konfirmasi password';
                    }
                    if (value != _passwordController.text) {
                      return 'Password tidak cocok';
                    }
                    return null;
                  },
                ),
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Daftar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PurchaseHistoryPage extends StatefulWidget {
  final String userEmail;

  const PurchaseHistoryPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<PurchaseHistoryPage> createState() => _PurchaseHistoryPageState();
}

class _PurchaseHistoryPageState extends State<PurchaseHistoryPage> {
  List<Purchase> purchases = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost/abp/get_purchases.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_email': widget.userEmail}),
      );

      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          purchases = (data['purchases'] as List)
              .map((p) => Purchase.fromJson(p))
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pembelian'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : purchases.isEmpty
                  ? const Center(child: Text('Belum ada riwayat pembelian'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: purchases.length,
                      itemBuilder: (context, index) {
                        final purchase = purchases[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Order ID: ${purchase.orderId}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    _buildStatusBadge(purchase.status),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Diamonds: ${purchase.diamonds}'),
                                Text('Harga: ${purchase.price}'),
                                Text('Metode: ${purchase.paymentMethod}'),
                                Text('Tanggal: ${purchase.purchaseDate}'),
                              ],
                            ),
                          ),
                        );
                      },
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class Purchase {
  final String orderId;
  final String userId;
  final String zoneId;
  final int diamonds;
  final String price;
  final String paymentMethod;
  final String purchaseDate;
  final String status;

  Purchase({
    required this.orderId,
    required this.userId,
    required this.zoneId,
    required this.diamonds,
    required this.price,
    required this.paymentMethod,
    required this.purchaseDate,
    required this.status,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      orderId: json['order_id'] as String,
      userId: json['user_id'] as String,
      zoneId: json['zone_id'] as String,
      diamonds: int.parse((json['diamonds'] ?? '0').toString()),
      price: json['price'] as String,
      paymentMethod: json['payment_method'] as String,
      purchaseDate: json['purchase_date'] as String,
      status: json['status'] as String,
    );
  }
}

// Add new ProfilePage widget
class ProfilePage extends StatefulWidget {
  final String userEmail;

  const ProfilePage({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  final _newPasswordController = TextEditingController();
  bool isLoading = true;
  String? errorMessage;
  String? successMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.userEmail);
    _phoneController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost/abp/get_profile.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.userEmail}),
      );

      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          _phoneController.text = data['phone'];
          isLoading = false;
        });
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
        successMessage = null;
      });

      final response = await http.post(
        Uri.parse('http://localhost/abp/update_profile.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.userEmail,
          'phone': _phoneController.text,
          'new_password': _newPasswordController.text.isEmpty ? null : _newPasswordController.text,
        }),
      );

      final data = jsonDecode(response.body);
      setState(() {
        isLoading = false;
        if (data['success']) {
          successMessage = 'Profile berhasil diperbarui';
          _newPasswordController.clear();
        } else {
          errorMessage = data['message'];
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informasi Akun',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              enabled: false,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Nomor HP',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Nomor HP tidak boleh kosong';
                                }
                                if (!value.startsWith('62')) {
                                  return 'Nomor HP harus diawali dengan 62';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '* Kosongkan password jika tidak ingin mengubah',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _newPasswordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Password Baru',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value != null && value.isNotEmpty && value.length < 6) {
                                  return 'Password minimal 6 karakter';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red[900]),
                        ),
                      ),
                    if (successMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          successMessage!,
                          style: TextStyle(color: Colors.green[900]),
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _updateProfile();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}