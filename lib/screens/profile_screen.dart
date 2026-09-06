import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
  });

  void _showMessage(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('TAMAM'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F4),
        elevation: 0,
        title: const Text(
          'PROFİL',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          30,
        ),
        children: [
          _profileHeader(context),
          const SizedBox(height: 26),

          const Text(
            'ŞEHİR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),

          _settingCard(
            icon: Icons.location_on_outlined,
            title: 'Ankara',
            subtitle: 'Seçili şehir',
            onTap: () {
              _showMessage(
                context,
                'Şehir',
                'İlk sürümde Ankara kullanılıyor.',
              );
            },
          ),

          const SizedBox(height: 24),

          const Text(
            'İLGİ ALANLARIN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),

          _interests(context),

          const SizedBox(height: 24),

          const Text(
            'AYARLAR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),

          _settingCard(
            icon: Icons.notifications_none_rounded,
            title: 'Bildirimler',
            subtitle: 'BUGÜN bildirimleri',
            onTap: () {
              _showMessage(
                context,
                'Bildirimler',
                'Bildirim ayarları bir sonraki sürümde açılacak.',
              );
            },
          ),

          const SizedBox(height: 10),

          _settingCard(
            icon: Icons.location_searching_rounded,
            title: 'Konum',
            subtitle: 'Yakınındaki içerikleri bul',
            onTap: () {
              _showMessage(
                context,
                'Konum',
                'Konum izni yönetimi bir sonraki aşamada eklenecek.',
              );
            },
          ),

          const SizedBox(height: 10),

          _settingCard(
            icon: Icons.lock_outline_rounded,
            title: 'Gizlilik',
            subtitle: 'Verilerini ve izinlerini yönet',
            onTap: () {
              _showMessage(
                context,
                'Gizlilik',
                'Gizlilik seçenekleri hazırlanıyor.',
              );
            },
          ),

          const SizedBox(height: 28),

          FilledButton(
            onPressed: () {
              _showMessage(
                context,
                'Hesap',
                'Giriş ve profil oluşturma ekranını şimdi hazırlıyoruz.',
              );
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            child: const Text(
              'GİRİŞ YAP / HESAP OLUŞTUR',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileHeader(BuildContext context) {
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () {
          _showMessage(
            context,
            'Profil',
            'Profil düzenleme ekranını bir sonraki aşamada ekleyeceğiz.',
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(21),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Misafir Kullanıcı',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Ankara · BUGÜN',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _interests(BuildContext context) {
    const interests = [
      '🎵 Müzik',
      '🎭 Tiyatro',
      '🍔 Yeme-İçme',
      '☕ Kahve',
      '🌳 Doğa',
      '🎨 Sanat',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: interests.map((interest) {
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              _showMessage(
                context,
                'İlgi alanı',
                '$interest seçildi.',
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              child: Text(
                interest,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _settingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}