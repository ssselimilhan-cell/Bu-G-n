import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
    await _savePreferences();
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
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                children: [
                  if (_message != null) ...[
                    Text(_message!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                  ],
                  _profileHeader(signedIn),
                  const SizedBox(height: 18),
                  const _SectionLabel('ŞEHİR'),
                  const SizedBox(height: 10),
                  _settingCard(
                    icon: Icons.location_on_outlined,
                    title: _city,
                    subtitle: signedIn ? 'Hesabına kaydedilen şehir' : 'Bu cihazda kaydedilen şehir',
                    onTap: _chooseCity,
                  ),
                  const SizedBox(height: 18),
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
                  const SizedBox(height: 18),
                  const _SectionLabel('AYARLAR'),
                  const SizedBox(height: 10),
                  _settingCard(icon: Icons.location_searching_rounded, title: 'Konum izni', subtitle: 'Yakınındaki etkinlikleri sıralamaya yardımcı olur', onTap: _requestLocation),
                  const SizedBox(height: 10),
                  _settingCard(icon: Icons.lock_outline_rounded, title: 'Gizlilik ve veriler', subtitle: 'Hangi verilerin neden kullanıldığını öğren', onTap: _showPrivacy),
                  const SizedBox(height: 10),
                  _settingCard(icon: Icons.notifications_none_rounded, title: 'Bildirimler', subtitle: 'Anlık bildirimler bu sürümde etkin değil', onTap: () => _showSnack('Bildirim gönderimi henüz etkinleştirilmedi; şu anda bildirim izni istenmiyor.')),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF3FB), Color(0xFFFFF1E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6E9EC)),
      ),
      child: Row(children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(Icons.wb_twilight_rounded, size: 32, color: Color(0xFFE87935)),
        ),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            signedIn ? (name?.isNotEmpty == true ? name! : 'BUGÜN kullanıcısı') : 'Misafir Kullanıcı',
            style: const TextStyle(color: Color(0xFF183B5B), fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            signedIn ? (_user?.email ?? 'Hesabın bağlı') : 'Hesap açmadan kullanabilirsin',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF52616D), fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text('$_city · BUGÜN', style: const TextStyle(color: Color(0xFF52616D), fontSize: 11)),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Icon(icon, size: 21, color: const Color(0xFF2769A6)),
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
