import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/city_preference_service.dart';
import 'city_offers_admin_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final CityPreferenceService _cityService = CityPreferenceService();

  static const List<String> _cities = [
    'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Aksaray', 'Amasya', 'Ankara', 'Antalya', 'Ardahan', 'Artvin', 'Aydın', 'Balıkesir', 'Bartın', 'Batman', 'Bayburt', 'Bilecik', 'Bingöl', 'Bitlis', 'Bolu', 'Burdur', 'Bursa', 'Çanakkale', 'Çankırı', 'Çorum', 'Denizli', 'Diyarbakır', 'Düzce', 'Edirne', 'Elazığ', 'Erzincan', 'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun', 'Gümüşhane', 'Hakkâri', 'Hatay', 'Iğdır', 'Isparta', 'İstanbul', 'İzmir', 'Kahramanmaraş', 'Karabük', 'Karaman', 'Kars', 'Kastamonu', 'Kayseri', 'Kırıkkale', 'Kırklareli', 'Kırşehir', 'Kilis', 'Kocaeli', 'Konya', 'Kütahya', 'Malatya', 'Manisa', 'Mardin', 'Mersin', 'Muğla', 'Muş', 'Nevşehir', 'Niğde', 'Ordu', 'Osmaniye', 'Rize', 'Sakarya', 'Samsun', 'Şanlıurfa', 'Siirt', 'Sinop', 'Sivas', 'Şırnak', 'Tekirdağ', 'Tokat', 'Trabzon', 'Tunceli', 'Uşak', 'Van', 'Yalova', 'Yozgat', 'Zonguldak',
  ];
  static const List<String> _interests = [
    '🎵 Müzik', '🎭 Tiyatro', '🍔 Yeme-İçme', '☕ Kahve', '🌳 Doğa', '🎨 Sanat',
    '🎬 Sinema', '🏛️ Tarih ve Müze', '🏃 Spor', '👨‍👩‍👧 Aile Etkinlikleri',
  ];

  String _city = CityPreferenceService.defaultCity;
  Set<String> _selectedInterests = {'🌳 Doğa', '🍔 Yeme-İçme'};
  bool _loading = true;
  bool _saving = false;
  bool _interestSaveNoticeShown = false;
  ScaffoldMessengerState? _messenger;
  User? _user;
  String? _displayName;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    _user = _client.auth.currentUser;
    try {
      _city = await _cityService.getSelectedCity();
      if (_user != null) {
        final row = await _client
            .from('profiles')
            .select('display_name, city, interests')
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
        } else {
          final preferences = await SharedPreferences.getInstance();
          final guestInterests = preferences.getStringList('bugun_guest_interests');
          if (guestInterests != null) _selectedInterests = guestInterests.toSet();
          _displayName ??= _user!.userMetadata?['display_name'] as String?;
          await _saveProfile();
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        final saved = prefs.getStringList('bugun_guest_interests');
        if (saved != null) _selectedInterests = saved.toSet();
      }
    } catch (error) {
      _message = 'Profil bilgileri yüklenemedi. İnternet bağlantını kontrol et.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('bugun_guest_interests', _selectedInterests.toList());
      return;
    }
    await _client.from('profiles').upsert({
      'id': user.id,
      'display_name': _displayName ?? user.userMetadata?['display_name'] as String?,
      'city': _city,
      'interests': _selectedInterests.toList(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> _savePreferences({bool showSuccess = true}) async {
    if (mounted) setState(() => _saving = true);
    try {
      await _cityService.saveSelectedCity(_city);
      await _saveProfile();
      if (mounted && showSuccess) _showSnack('Tercihlerin kaydedildi.');
    } catch (_) {
      if (mounted) _showSnack('Kaydedilemedi. Bağlantını kontrol edip tekrar dene.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _chooseCity() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _CityPickerSheet(
        cities: _cities,
        selectedCity: _city,
      ),
    );
    if (chosen == null || !mounted || chosen == _city) return;
    setState(() => _city = chosen);
    await _savePreferences(showSuccess: false);
    if (mounted) _showSnack('Şehir tercihi kaydedildi: $chosen');
  }

  Future<void> _toggleInterest(String interest) async {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
    // Persist every change, but show the success notice only once per visit.
    final showNotice = !_interestSaveNoticeShown;
    _interestSaveNoticeShown = true;
    await _savePreferences(showSuccess: showNotice);
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


  Future<void> _openWebPage(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return;
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) _showSnack('Bağlantı açılamadı. Daha sonra tekrar dene.');
    } catch (_) {
      if (mounted) _showSnack('Bağlantı açılamadı. Daha sonra tekrar dene.');
    }
  }

  Future<void> _contactUs() async {
    await _openWebPage('mailto:ssselimilhan@gmail.com?subject=BUG%C3%9CN%20-%20Bize%20ula%C5%9F%C4%B1n');
  }

  Future<void> _requestAccountDeletion() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      await _openWebPage('https://ssselimilhan-cell.github.io/Bu-G-n/account-deletion.html');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesap ve verileri sil'),
        content: const Text('Bu işlem hesap ve ilişkili verilerin silinmesi için talep e-postası oluşturur. Talebi gönderdikten sonra doğrulama gerekebilir. Parolanı veya doğrulama kodunu e-postaya ekleme.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('VAZGEÇ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('TALEP OLUŞTUR')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final email = Uri.encodeComponent(user.email ?? '');
    await _openWebPage('mailto:ssselimilhan@gmail.com?subject=BUG%C3%9CN%20hesap%20ve%20veri%20silme%20talebi&body=Merhaba%2C%0A%0ABUG%C3%9CN%20hesab%C4%B1m%C4%B1n%20ve%20ili%C5%9Fkili%20verilerimin%20silinmesini%20talep%20ediyorum.%0A%0AHesab%C4%B1mda%20kulland%C4%B1%C4%9F%C4%B1m%20e-posta%20adresi%3A%20$email%0A');
  }

  void _showAboutAndSources() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hakkında ve veri kaynakları'),
        content: const SingleChildScrollView(
          child: Text(
            'BUGÜN, şehir keşfi ve etkinlik bilgileri sunan bağımsız bir uygulamadır.\n\n'
            'Sinema film kataloğunda The Movie Database (TMDB) API kullanılır. '
            'This product uses the TMDB API but is not endorsed or certified by TMDB.\n\n'
            'TMDB, BUGÜN uygulamasını desteklemez veya onaylamaz. Film bilgileri ve afişler TMDB kaynaklıdır; '
            'Türkiye’deki gerçek sinema salonu ve seans saatleri TMDB film kataloğundan sağlanmaz.\n\n'
            'TMDB logo ve atıf koşulları: https://www.themoviedb.org/about/logos-attribution\n'
            'API koşulları ve ticari lisans: https://developer.themoviedb.org/docs/faq',
            style: TextStyle(height: 1.45),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('KAPAT'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _openWebPage('https://www.themoviedb.org/about/logos-attribution');
            },
            child: const Text('TMDB ATIF KOŞULLARI'),
          ),
        ],
      ),
    );
  }

  void _showPrivacy() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gizlilik ve verilerin'),
        content: const SingleChildScrollView(
          child: Text(
            'BUGÜN’de gizliliğin önemlidir. Uygulama, şehirindeki etkinlikleri ve gezilecek yerleri keşfetmene yardımcı olmak için aşağıdaki bilgileri kullanır.\n\n'
            'HESAP VE PROFİL\n'
            '• Hesap oluşturduğunda e-posta adresin, oturum açma ve hesap güvenliği amacıyla işlenir.\n'
            '• Profil adın, seçtiğin şehir ve ilgi alanların tercihlerini hesabınla ilişkilendirmek ve sana uygun içerikleri göstermek için saklanır.\n'
            '• Giriş yapmadan kullandığında seçtiğin şehir ve ilgi alanları cihazında saklanır.\n\n'
            'KONUM VE UYGULAMA İÇERİĞİ\n'
            '• Konum erişimi isteğe bağlıdır. İzin verdiğinde konumun yakındaki yerleri bulmak ve mesafeye göre sıralamak için kullanılabilir. Konum izni olmadan da şehir seçerek uygulamayı kullanabilirsin. Uygulama konumunu sürekli arka planda takip etmez.\n'
            '• Etkinlik, yer ve sinema bilgileri ilgili içerik sağlayıcılarından alınabilir. Harici bilet veya bilgi bağlantılarını açtığında ilgili hizmet sağlayıcının gizlilik koşulları geçerli olur.\n\n'
            'VERİLERİNİN KORUNMASI VE TALEPLER\n'
            '• Hesap ve profil verileri, uygulamanın çalışması için kullanılan Supabase hizmetlerinde işlenir. Bilgilerin reklam amacıyla satılmaz.\n'
            '• Kişisel verilerinle ilgili bilgi, düzeltme veya silme talebi için sssselimilhan@gmail.com adresinden bize ulaşabilirsin. Hesap silme talebini Profil bölümündeki “Hesabı ve verileri sil” seçeneğinden de başlatabilirsin.\n'
            '• Konum iznini cihaz ayarlarından istediğin zaman değiştirebilirsin.\n\n'
            'Gizlilik soruların için: sssselimilhan@gmail.com',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('KAPAT'))],
      ),
    );
  }

  void _showSnack(String text) {
    final messenger = _messenger ?? ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  void dispose() {
    _messenger?.hideCurrentSnackBar();
    super.dispose();
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
                  if (_client.auth.currentUser?.appMetadata['role'] == 'admin') ...[
                    const SizedBox(height: 14),
                    _settingCard(
                      icon: Icons.campaign_outlined,
                      title: 'Yönetici paneli · Şehir fırsatları',
                      subtitle: '81 ilde reklam kampanyaları ekle, düzenle ve yayın takvimini yönet',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(builder: (_) => const CityOffersAdminScreen()),
                      ),
                    ),
                  ],
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
                  const _SectionLabel('AYARLAR'),
                  const SizedBox(height: 10),
                  _settingCard(icon: Icons.location_searching_rounded, title: 'Konum izni', subtitle: 'Yakınındaki etkinlikleri sıralamaya yardımcı olur', onTap: _requestLocation),
                  const SizedBox(height: 10),
                  _settingCard(icon: Icons.lock_outline_rounded, title: 'Gizlilik ve veriler', subtitle: 'Hangi verilerin neden kullanıldığını öğren', onTap: _showPrivacy),
                  _settingCard(icon: Icons.info_outline_rounded, title: 'Hakkında ve veri kaynakları', subtitle: 'TMDB atfı ve veri kullanımı', onTap: _showAboutAndSources),
                  const SizedBox(height: 10),
                  _settingCard(icon: Icons.notifications_none_rounded, title: 'Bildirimler', subtitle: 'Anlık bildirimler bu sürümde etkin değil', onTap: () => _showSnack('Bildirim gönderimi henüz etkinleştirilmedi; şu anda bildirim izni istenmiyor.')),
                  const SizedBox(height: 24),
                  const _SectionLabel('YARDIM VE HESAP'),
                  const SizedBox(height: 10),
                  _settingCard(icon: Icons.mail_outline_rounded, title: 'Bize ulaşın', subtitle: 'E-posta ile destek al', onTap: _contactUs),
                  const SizedBox(height: 10),
                  _settingCard(icon: Icons.open_in_browser_rounded, title: 'Web üzerinden hesap silme', subtitle: 'Hesap silme talebi sayfasını aç', onTap: () => _openWebPage('https://ssselimilhan-cell.github.io/Bu-G-n/account-deletion.html')),
                  const SizedBox(height: 10),
                  _settingCard(icon: Icons.delete_outline_rounded, title: 'Hesabı ve verileri sil', subtitle: 'Hesap ve ilişkili verilerin silinmesini talep et', onTap: _requestAccountDeletion),
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


class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet({required this.cities, required this.selectedCity});

  final List<String> cities;
  final String selectedCity;

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.cities
        .where((city) => city.toLowerCase().contains(query.trim().toLowerCase()))
        .toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Şehir seç', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(
                  hintText: '81 il içinde ara',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Şehir bulunamadı.'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final city = filtered[index];
                        return ListTile(
                          title: Text(city),
                          trailing: city == widget.selectedCity ? const Icon(Icons.check_circle) : null,
                          onTap: () => Navigator.pop(context, city),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
