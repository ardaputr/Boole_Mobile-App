import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'explore_screen.dart';
import 'search_screen.dart';
import 'compass_screen.dart';

// StatefulWidget untuk halaman utama dengan bottom navigation dan app bar yang dinamis
class HomeScreen extends StatefulWidget {
  // Menerima parameter userName dan email dari widget lain
  final String userName;
  final String email;

  const HomeScreen({super.key, required this.userName, required this.email});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Indeks tab yang sedang aktif pada bottom navigation
  int _currentIndex = 0;

  // List halaman (screens) yang akan dipanggil sesuai tab yang aktif
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // list halaman dengan widget statis dan profile yang menggunakan data user
    _pages = <Widget>[
      const ExploreScreen(),
      const SearchScreen(),
      const CompassScreen(),
      ProfileScreen(userName: widget.userName, email: widget.email),
    ];
  }

  // Fungsi untuk menghasilkan AppBar yang hanya muncul saat tab Explore (index 0) aktif
  PreferredSizeWidget? getAppBar() {
    // Jika tab selain Explore, kembalikan null (tidak ada app bar)
    if (_currentIndex != 0) return null;

    // Jika Explore aktif, buat app bar dengan desain lain
    return PreferredSize(
      // panjang app bar
      preferredSize: const Size.fromHeight(kToolbarHeight + 30),
      child: ClipRRect(
        //border biru app bar
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        child: Container(
          color: Colors.cyan, // warna app bar
          // padding dalam app bar
          padding: const EdgeInsets.fromLTRB(
            20, // kiri
            53, // atas
            20, // kanan
            20, // bawah
          ), // padding dalam app bar
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, ${widget.userName}!',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white, // warna teks nama
                      ),
                    ),
                    const Text(
                      'Discovering Nearby Places',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ), // font size dan warna teks
                    ),
                  ],
                ),
              ),
              Text(
                _getGreetingMessage(),
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white, // warna teks greeting
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 15) {
      return 'Good Afternoon';
    } else if (hour < 18) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: getAppBar(),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        // navigation belakang decoration
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.5),
              blurRadius: 20,
            ), // bayangan di nav
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            // border nav depan
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            selectedItemColor: Colors.cyan, //warna item yang dipilih
            unselectedItemColor: Colors.grey, //warna item yang tidak dipilih
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.explore),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.navigation),
                label: 'Compass',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            // selectedIconTheme: IconThemeData(
            //   color: Colors.blue, // Ganti warna ikon yang dipilih
            // ),
            // unselectedIconTheme: IconThemeData(
            //   color: Colors.orange, // Ganti warna ikon yang tidak dipilih
            // ),
          ),
        ),
      ),
    );
  }
}
