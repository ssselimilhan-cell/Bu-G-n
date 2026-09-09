import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Set<String> _selectedInterests = {
    '🌳 Doğa',
    '🍔 Yeme-İçme',
  };

  static const List<String> _interests = [
    '🎵 Müzik',
    '🎭 Tiyatro',
    '🍔 Yeme-İçme',
    '☕ Kahve',
    '🌳 Doğa',
    '🎨 Sanat',
  ];

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
              onPressed: () => Navigator.pop(context),
              child: const Text('TAMAM'),
            ),
          ],
        );
      },
    );
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F4),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'PROFİL',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            24,
          ),
          children: [
            _profileHeader(context),

            const SizedBox(height: 24),

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

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'İLGİ ALANLARIN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Text(
                  '${_selectedInterests.length} seçili',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            const Text(
              'Sana daha uygun öneriler gösterebilmemiz için ilgi alanlarını seç.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                height: 1.35,
              ),
            ),

            const SizedBox(height: 12),

            _buildInterests(),

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
                  'Bildirim ayarları hazırlanıyor.',
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
                  'Konum izinleri hazırlanıyor.',
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

            const SizedBox(height: 22),

            _accountButton(context),

            const SizedBox(height: 8),
          ],
        ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _buildInterests() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _interests.map((interest) {
        final selected =
            _selectedInterests.contains(interest);

        return Material(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () => _toggleInterest(interest),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 10,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    interest,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.add_circle_outline,
                    size: 16,
                    color: selected
                        ? Colors.white
                        : Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _accountButton(BuildContext context) {
    return FilledButton(
      onPressed: () {
        _showMessage(
          context,
          'Hesap',
          'Giriş ve hesap oluşturma ekranını bir sonraki aşamada ekleyeceğiz.',
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
