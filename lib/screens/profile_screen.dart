import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/city_preference_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final CityPreferenceService _cityService = CityPreferenceService();

  static const List<String> _cities = [
    'Adana',
    'Adıyaman',
    'Afyonkarahisar',
    'Ağrı',
    'Amasya',
    'Ankara',
    'Antalya',
    'Artvin',
    'Aydın',
    'Balıkesir',
    'Bilecik',
    'Bingöl',
    'Bitlis',
    'Bolu',
    'Burdur',
    'Bursa',
    'Çanakkale',
    'Çankırı',
    'Çorum',
    'Denizli',
    'Diyarbakır',
    'Edirne',
    'Elazığ',
    'Erzincan',
    'Erzurum',
    'Eskişehir',
    'Gaziantep',
    'Giresun',
    'Gümüşhane',
    'Hakkâri',
    'Hatay',
    'Isparta',
    'Mersin',
    'İstanbul',
    'İzmir',
    'Kars',
    'Kastamonu',
    'Kayseri',
    'Kırklareli',
    'Kırşehir',
    'Kocaeli',
    'Konya',
    'Kütahya',
    'Malatya',
    'Manisa',
    'Kahramanmaraş',
    'Mardin',
    'Muğla',
    'Muş',
    'Nevşehir',
    'Niğde',
    'Ordu',
    'Rize',
    'Sakarya',
    'Samsun',
    'Siirt',
    'Sinop',
    'Sivas',
    'Tekirdağ',
    'Tokat',
    'Trabzon',
    'Tunceli',
    'Şanlıurfa',
    'Uşak',
    'Van',
    'Yozgat',
    'Zonguldak',
    'Aksaray',
    'Bayburt',
    'Karaman',
    'Kırıkkale',
    'Batman',
    'Şırnak',
    'Bartın',
    'Ardahan',
    'Iğdır',
    'Yalova',
    'Karabük',
    'Kilis',
    'Osmaniye',
    'Düzce'
  ];
  static const List<String> _interests = [
    '🎵 Müzik', '🎭 Tiyatro', '🍔 Yeme-İçme', '☕ Kahve', '🌳 Doğa', '🎨 Sanat',
    '🎬 Sinema', '🏛️ Tarih ve Müze', '🏃 Spor', '👨‍👩‍👧 Aile Etkinlikleri',
  ];

  String _city = CityPreferenceService.defaultCity;
  Set<String> _selectedInterests = {'🌳 Doğa', '🍔 Yeme-İçme'};
  int _budgetLevel = 3;
  double _radiusKm = 10;
  int _visitDurationMin = 120;
  String _preferredTransport = 'Farketmez';
  bool _loading = true;
  bool _saving = false;
  User? _user;
  String? _displayName;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    _user = _client.auth.currentUser;
    try {
      _city = await _cityService.getSelectedCity();
      if (_user != null) {
        final row = await _client
            .from('profiles')
            .select('display_name, city, interests, budget_level, preferred_radius_km, preferred_visit_duration_min, preferred_transport')
            .eq('id', _user!.id)
            .maybeSingle();
        if (row != null) {
          _displayName = row['display_name'] as String?;
          final profileCity = row['city'] as String?;
          if (profileCity != null && profileCity.isNotEmpty) _city = profileCity;
          final interests = row['interests'];
          if (interests is List) {
            _selectedInterests = interests.map((e) => e.toString()).toSet();
          }
          _budgetLevel = (row['budget_level'] as num?)?.toInt() ?? _budgetLevel;
          _radiusKm = (row['preferred_radius_km'] as num?)?.toDouble() ?? _radiusKm;
          _visitDurationMin = (row['preferred_visit_duration_min'] as num?)?.toInt() ?? _visitDurationMin;
          _preferredTransport = row['preferred_transport'] as String? ?? _preferredTransport;
        } else {
          final preferences = await SharedPreferences.getInstance();
          _loadLocalPreferences(preferences);
          _displayName ??= _user!.userMetadata?['display_name'] as String?;
          await _saveProfile();
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        _loadLocalPreferences(prefs);
      }
    } catch (error) {
      _message = 'Profil bilgileri yüklenemedi. İnternet bağlantını kontrol et.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _loadLocalPreferences(SharedPreferences prefs) {
    final saved = prefs.getStringList('bugun_guest_interests');
    if (saved != null) _selectedInterests = saved.toSet();
    _budgetLevel = prefs.getInt('bugun_budget_level') ?? _budgetLevel;
    _radiusKm = prefs.getDouble('bugun_radius_km') ?? _radiusKm;
    _visitDurationMin = prefs.getInt('bugun_visit_duration_min') ?? _visitDurationMin;
    _preferredTransport = prefs.getString('bugun_transport') ?? _preferredTransport;
  }

  Future<void> _saveProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('bugun_guest_interests', _selectedInterests.toList());
      await prefs.setInt('bugun_budget_level', _budgetLevel);
      await prefs.setDouble('bugun_radius_km', _radiusKm);
      await prefs.setInt('bugun_visit_duration_min', _visitDurationMin);
      await prefs.setString('bugun_transport', _preferredTransport);
      return;
    }
    await _client.from('profiles').upsert({
      'id': user.id,
      'display_name': _displayName ?? user.userMetadata?['display_name'] as String?,
      'city': _city,
      'interests': _selectedInterests.toList(),
      'budget_level': _budgetLevel,
      'preferred_radius_km': _radiusKm,
      'preferred_visit_duration_min': _visitDurationMin,
      'preferred_transport': _preferredTransport,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> _savePreferences() async {
    setState(() => _saving = true);
    try {
      await _cityService.saveSelectedCity(_city);
      await _saveProfile();
      if (mounted) _showSnack('Tercihlerin kaydedildi.');
    } catch (_) {
      if (mounted) _showSnack('Kaydedilemedi. Bağlantını kontrol edip tekrar dene.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _chooseCity() async {
    var query = '';
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final filteredCities = _cities
              .where((city) => city.toLowerCase().contains(query.trim().toLowerCase()))
              .toList();
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.78,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Şehir seç',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      autofocus: true,
                      onChanged: (value) => setModalState(() => query = value),
                      decoration: InputDecoration(
                        hintText: '81 şehir içinde ara',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  Expanded(
                    child: filteredCities.isEmpty
                        ? const Center(child: Text('Şehir bulunamadı.'))
                        : ListView.builder(
                            itemCount: filteredCities.length,
                            itemBuilder: (context, index) {
                              final city = filteredCities[index];
                              return ListTile(
                                title: Text(city),
                                trailing: city == _city ? const Icon(Icons.check) : null,
                                onTap: () => Navigator.pop(context, city),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (chosen == null || !mounted) return;
    setState(() => _city = chosen);
    await _savePreferences();
  }

  Future<void> _toggleInterest(String interest) async {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
    await _savePreferences();
  }

  Future<void> _openAccount() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AccountDialog(client: _client),
    );
    if (result == true && mounted) await _loadProfile();
  }

  Future<void> _signOut() async {
    try {
      await _client.auth.signOut();
      if (!mounted) return;
      setState(() {
        _user = null;
        _displayName = null;
      });
      await _loadProfile();
      if (mounted) _showSnack('Oturum kapatıldı. Cihazındaki şehir tercihi korundu.');
    } catch (_) {
      if (mounted) _showSnack('Çıkış yapılamadı. Tekrar dene.');
    }
  }

  Future<void> _requestLocation() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konum neden gerekli?'),
        content: const Text(
          'Konumun, yakınındaki etkinlikleri sıralamak ve mesafe tahmini yapmak için kullanılır. '
          'Konum izni isteğe bağlıdır. İzin vermezsen de seçtiğin şehirde etkinlik arayabilirsin. '
          'Bu uygulama konumunu sürekli arka planda takip etmez.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ŞİMDİ DEĞİL')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('DEVAM ET')),
        ],
      ),
    );
    if (proceed != true) return;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) _showSnack('Cihaz konumu kapalı. Açmadan da şehir seçerek devam edebilirsin.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        if (mounted) _showSnack('Konum izni ayarlardan kapalı. İstersen ayarlardan açabilirsin.');
        await Geolocator.openAppSettings();
      } else if (permission == LocationPermission.denied) {
        if (mounted) _showSnack('Konum izni verilmedi. Şehir seçerek devam edebilirsin.');
      } else if (mounted) {
        _showSnack('Konum izni etkin. Yakınlık sıralaması kullanılabilir.');
      }
    } catch (_) {
      if (mounted) _showSnack('Konum alınamadı. Şehir seçerek kullanmaya devam edebilirsin.');
    }
  }

  Future<void> _requestNotifications() async {
    final explain = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildirim izni'),
        content: const Text(
          'İzin verirsen BUGÜN etkinlik hatırlatmaları ve seçtiğin içeriklerle ilgili bildirimler gönderebilir. '
          'İzin isteğe bağlıdır; reddedersen uygulamanın diğer özelliklerini kullanmaya devam edebilirsin. '
          'Bildirim izni, henüz sunucu tarafında etkinleştirilmemiş bildirim kampanyalarının çalıştığı anlamına gelmez.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ŞİMDİ DEĞİL')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('DEVAM ET')),
        ],
      ),
    );
    if (explain != true || !mounted) return;
    try {
      final status = await Permission.notification.request();
      if (!mounted) return;
      if (status.isGranted || status.isLimited) {
        _showSnack('Bildirim izni verildi. Bildirim gönderimi sunucu yapılandırmasına bağlıdır.');
      } else if (status.isPermanentlyDenied) {
        _showSnack('Bildirim izni kapalı. İstersen uygulama ayarlarından açabilirsin.');
        await openAppSettings();
      } else {
        _showSnack('Bildirim izni verilmedi. Uygulamayı kullanmaya devam edebilirsin.');
      }
    } catch (_) {
      if (mounted) _showSnack('Bildirim izni kontrol edilemedi.');
    }
  }

  void _showPrivacy() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gizlilik ve verilerin'),
        content: const SingleChildScrollView(
          child: Text(
            'BUGÜN, şehirdeki etkinlik ve gezilecek yerleri bulmana yardımcı olur.\n\n'
            '• Hesap açarsan e-posta adresin Supabase Auth tarafından oturum açma ve hesap güvenliği için işlenir.\n'
            '• Profil adı, seçtiğin şehir ve ilgi alanların hesabına kaydedilir; yalnızca giriş yaptığın hesabın kendi profilini okuyup değiştirmesine izin veren erişim kuralları kullanılmalıdır.\n'
            '• Giriş yapmadan seçtiğin şehir ve ilgi alanları bu cihazda saklanır.\n'
            '• Konum izni isteğe bağlıdır; yakınlık sıralaması için kullanılır. İzin vermeden de uygulamayı kullanabilirsin.\n'
            '• Etkinlik araması için etkinlik/yer verileri Supabase sunucusundan alınır. Bilet satın alma işlemleri ilgili sağlayıcının sitesinde yapılabilir.\n\n'
            'Bu ekran uygulama içi bilgilendirmedir; yayına çıkmadan önce işletmeci iletişim bilgileri, veri saklama süreleri, kullanıcı hakları ve başvuru yöntemiyle birlikte hukuken gözden geçirilmiş bir Gizlilik Politikası ve gerekiyorsa KVKK aydınlatma metni yayımlanmalıdır.',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('KAPAT'))],
      ),
    );
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _user != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F4),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('PROFİL', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  if (_message != null) ...[
                    Text(_message!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                  ],
                  _profileHeader(signedIn),
                  const SizedBox(height: 24),
                  const _SectionLabel('ŞEHİR'),
                  const SizedBox(height: 10),
                  _settingCard(
                    icon: Icons.location_on_outlined,
                    title: _city,
                    subtitle: signedIn ? 'Hesabına kaydedilen şehir' : 'Bu cihazda kaydedilen şehir',
                    onTap: _chooseCity,
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    const Expanded(child: _SectionLabel('İLGİ ALANLARIN')),
                    Text('${_selectedInterests.length} seçili', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ]),
                  const SizedBox(height: 8),
                  const Text('Sana uygun etkinlikleri bulmak için ilgilendiğin konuları seç.', style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: _interests.map((interest) {
                    final selected = _selectedInterests.contains(interest);
                    return FilterChip(
                      label: Text(interest),
                      selected: selected,
                      onSelected: (_) => _toggleInterest(interest),
                      selectedColor: Colors.black,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
                      backgroundColor: Colors.white,
                      side: BorderSide.none,
                    );
                  }).toList()),
                  const SizedBox(height: 24),
                  const _SectionLabel('PLAN TERCİHLERİ'),
                  const SizedBox(height: 8),
                  const Text(
                    'Önerilerde bütçeni, ulaşım tercihini ve ne kadar zaman ayırabileceğini dikkate al.',
                    style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bütçe', style: TextStyle(fontWeight: FontWeight.w800)),
                        DropdownButtonFormField<int>(
                          value: _budgetLevel,
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('Ücretsiz')),
                            DropdownMenuItem(value: 1, child: Text('Düşük bütçe')),
                            DropdownMenuItem(value: 2, child: Text('Orta bütçe')),
                            DropdownMenuItem(value: 3, child: Text('Sınırlama yok')),
                          ],
                          onChanged: (value) async {
                            if (value == null) return;
                            setState(() => _budgetLevel = value);
                            await _savePreferences();
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Expanded(child: Text('Ulaşım', style: TextStyle(fontWeight: FontWeight.w800))),
                            DropdownButton<String>(
                              value: _preferredTransport,
                              items: const [
                                DropdownMenuItem(value: 'Farketmez', child: Text('Farketmez')),
                                DropdownMenuItem(value: 'Yürüyerek', child: Text('Yürüyerek')),
                                DropdownMenuItem(value: 'Toplu taşıma', child: Text('Toplu taşıma')),
                                DropdownMenuItem(value: 'Araç', child: Text('Araç')),
                              ],
                              onChanged: (value) async {
                                if (value == null) return;
                                setState(() => _preferredTransport = value);
                                await _savePreferences();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Expanded(child: Text('Yakınlık yarıçapı', style: TextStyle(fontWeight: FontWeight.w800))),
                            Text('${_radiusKm.round()} km'),
                          ],
                        ),
                        Slider(
                          value: _radiusKm.clamp(1.0, 50.0).toDouble(),
                          min: 1,
                          max: 50,
                          divisions: 49,
                          label: '${_radiusKm.round()} km',
                          onChanged: (value) => setState(() => _radiusKm = value),
                          onChangeEnd: (_) => _savePreferences(),
                        ),
                        const SizedBox(height: 8),
                        const Text('Ayırabileceğin süre', style: TextStyle(fontWeight: FontWeight.w800)),
                        DropdownButtonFormField<int>(
                          value: _visitDurationMin,
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items: const [
                            DropdownMenuItem(value: 60, child: Text('Yaklaşık 1 saat')),
                            DropdownMenuItem(value: 120, child: Text('Yaklaşık 2 saat')),
                            DropdownMenuItem(value: 240, child: Text('Yaklaşık 4 saat')),
                            DropdownMenuItem(value: 480, child: Text('Tam gün')),
                          ],
                          onChanged: (value) async {
                            if (value == null) return;
                            setState(() => _visitDurationMin = value);
                            await _savePreferences();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel('AYARLAR'),
                  const SizedBox(height: 10),
                  _settingCard(icon: Icons.location_searching_rounded, title: 'Konum izni', subtitle: 'Yakınındaki etkinlikleri sıralamaya yardımcı olur', onTap: _requestLocation),
                  const SizedBox(height: 10),
                  _settingCard(icon: Icons.lock_outline_rounded, title: 'Gizlilik ve veriler', subtitle: 'Hangi verilerin neden kullanıldığını öğren', onTap: _showPrivacy),
                  const SizedBox(height: 10),
                  _settingCard(icon: Icons.notifications_none_rounded, title: 'Bildirimler', subtitle: 'Bildirim iznini yönet', onTap: _requestNotifications),
                  const SizedBox(height: 22),
                  if (!signedIn)
                    FilledButton(
                      onPressed: _openAccount,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
                      child: const Text('GİRİŞ YAP / HESAP OLUŞTUR', style: TextStyle(fontWeight: FontWeight.w900)),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('ÇIKIŞ YAP'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
                    ),
                  if (_saving) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _savePreferences, child: const Text('TERCİHLERİ KAYDET')),
                ],
              ),
            ),
    );
  }

  Widget _profileHeader(bool signedIn) {
    final name = _displayName ?? _user?.userMetadata?['display_name'] as String?;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(26)),
      child: Row(children: [
        Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.person_outline_rounded, size: 34)),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(signedIn ? (name?.isNotEmpty == true ? name! : 'BUGÜN kullanıcısı') : 'Misafir Kullanıcı', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(signedIn ? (_user?.email ?? 'Hesabın bağlı') : 'Hesap açmadan kullanabilirsin', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 3),
          Text('$_city · BUGÜN', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
      ]),
    );
  }

  Widget _settingCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Icon(icon, size: 23),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 11)),
            ])),
            const Icon(Icons.chevron_right_rounded),
          ]),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1));
}

class _AccountDialog extends StatefulWidget {
  final SupabaseClient client;
  const _AccountDialog({required this.client});
  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _creating = false;
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      if (_creating) {
        final response = await widget.client.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'display_name': _name.text.trim()},
        );
        final user = response.user;
        if (user != null && response.session != null) {
          final city = await CityPreferenceService().getSelectedCity();
          final preferences = await SharedPreferences.getInstance();
          final interests = preferences.getStringList('bugun_guest_interests') ??
              ['🌳 Doğa', '🍔 Yeme-İçme'];
          await widget.client.from('profiles').upsert({
            'id': user.id,
            'display_name': _name.text.trim(),
            'city': city,
            'interests': interests,
          });
          if (mounted) Navigator.pop(context, true);
        } else {
          setState(() => _error = 'Hesap oluşturma isteği gönderildi. E-posta adresine gelen doğrulama bağlantısını aç, ardından giriş yap.');
        }
      } else {
        await widget.client.auth.signInWithPassword(email: _email.text.trim(), password: _password.text);
        if (mounted) Navigator.pop(context, true);
      }
    } on AuthException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'İşlem tamamlanamadı. İnternet bağlantını ve Supabase Auth ayarlarını kontrol et.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_email.text.trim().isEmpty || !_email.text.contains('@')) {
      setState(() => _error = 'Şifre sıfırlama bağlantısı için önce e-posta adresini yaz.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await widget.client.auth.resetPasswordForEmail(_email.text.trim());
      setState(() => _error = 'Şifre sıfırlama bağlantısı e-posta adresine gönderildiyse gelen kutunu kontrol et.');
    } on AuthException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Şifre sıfırlama isteği gönderilemedi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_creating ? 'Hesap oluştur' : 'Giriş yap'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_creating) TextFormField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Adın'), validator: (value) => (value == null || value.trim().isEmpty) ? 'Adını yaz.' : null),
            TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], decoration: const InputDecoration(labelText: 'E-posta'), validator: (value) => (value == null || !value.contains('@')) ? 'Geçerli bir e-posta yaz.' : null),
            TextFormField(controller: _password, obscureText: _hidePassword, autofillHints: _creating ? const [AutofillHints.newPassword] : const [AutofillHints.password], decoration: InputDecoration(labelText: 'Şifre', suffixIcon: IconButton(icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _hidePassword = !_hidePassword))), validator: (value) => (value == null || value.length < 6) ? 'Şifre en az 6 karakter olmalı.' : null),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
            if (!_creating) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _busy ? null : _resetPassword, child: const Text('Şifremi unuttum'))),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('KAPAT')),
        TextButton(onPressed: _busy ? null : () => setState(() { _creating = !_creating; _error = null; }), child: Text(_creating ? 'GİRİŞ YAP' : 'HESAP OLUŞTUR')),
        FilledButton(onPressed: _busy ? null : _submit, child: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_creating ? 'OLUŞTUR' : 'GİRİŞ')),
      ],
    );
  }
}
