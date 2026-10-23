import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CityOffersScreen extends StatefulWidget {
  const CityOffersScreen({super.key, required this.city});
  final String city;

  @override
  State<CityOffersScreen> createState() => _CityOffersScreenState();
}

class _CityOffersScreenState extends State<CityOffersScreen> {
  final _client = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _offers;
  bool _saving = false;

  bool get _isAdmin =>
      _client.auth.currentUser?.appMetadata['role'] == 'admin';

  @override
  void initState() {
    super.initState();
    _offers = _load();
  }

  @override
  void didUpdateWidget(covariant CityOffersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.city != widget.city) _offers = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await _client.from('offers').select(
      'id,city,title,description,discount_text,source_url,starts_at,ends_at'
    ).eq('is_active', true).ilike('city', widget.city.trim())
      .order('created_at', ascending: false).limit(100);
    return rows.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> _createOffer() async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    final description = TextEditingController();
    final discount = TextEditingController();
    final sourceUrl = TextEditingController();
    final city = TextEditingController(text: widget.city);
    final form = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Şehir fırsatı ekle'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Fırsat başlığı *'), validator: (v) => (v == null || v.trim().length < 3) ? 'En az 3 karakter gir.' : null),
              TextFormField(controller: city, decoration: const InputDecoration(labelText: 'Şehir *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Şehir gerekli.' : null),
              TextFormField(controller: description, decoration: const InputDecoration(labelText: 'Açıklama'), maxLines: 3),
              TextFormField(controller: discount, decoration: const InputDecoration(labelText: 'İndirim / fırsat metni')),
              TextFormField(controller: sourceUrl, decoration: const InputDecoration(labelText: 'Kaynak bağlantısı (https://...)'), keyboardType: TextInputType.url),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('İPTAL')),
          FilledButton(onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(dialogContext, {
                'title': title.text.trim(), 'city': city.text.trim(),
                'description': description.text.trim(), 'discount_text': discount.text.trim(),
                'source_url': sourceUrl.text.trim(),
              });
            }
          }, child: const Text('KAYDET')),
        ],
      ),
    );
    title.dispose(); description.dispose(); discount.dispose(); sourceUrl.dispose(); city.dispose();
    if (form == null || !mounted) return;
    final user = _client.auth.currentUser;
    if (user == null || !_isAdmin) {
      _message('Yalnızca yönetici şehir fırsatı ekleyebilir.');
      return;
    }
    final link = form['source_url']!;
    if (link.isNotEmpty) {
      final uri = Uri.tryParse(link);
      if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
        _message('Kaynak bağlantısı http:// veya https:// ile başlamalı.');
        return;
      }
    }
    setState(() => _saving = true);
    try {
      await _client.from('offers').insert({
        'title': form['title'], 'city': form['city'],
        'description': form['description']!.isEmpty ? null : form['description'],
        'discount_text': form['discount_text']!.isEmpty ? null : form['discount_text'],
        'source_url': link.isEmpty ? null : link,
        'created_by': user.id, 'is_active': true, 'trust_score': 100,
      });
      if (!mounted) return;
      setState(() => _offers = _load());
      _message('Şehir fırsatı yayınlandı.');
    } catch (_) {
      _message('Kaydedilemedi. Yönetici yetkisini ve 011 numaralı Supabase migration\'ını kontrol et.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openSource(String? value) async {
    if (value == null || value.trim().isEmpty) return;
    final uri = Uri.tryParse(value);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _message(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async { final next = _load(); setState(() => _offers = next); await next; },
          child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _offers,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(24), children: const [
                SizedBox(height: 90), Icon(Icons.local_offer_outlined, size: 48),
                SizedBox(height: 12), Text('Şehir fırsatları yüklenemedi.', textAlign: TextAlign.center),
                SizedBox(height: 8), Text('Bağlantını kontrol et veya ekranı aşağı çekerek yenile.', textAlign: TextAlign.center),
              ]);
            }
            final rows = snapshot.data ?? [];
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                Text('${widget.city} fırsatları', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('Yayınlanan indirimler ve yerel fırsatlar.', style: TextStyle(height: 1.4)),
                if (_isAdmin) ...[
                  const SizedBox(height: 14),
                  FilledButton.icon(onPressed: _saving ? null : _createOffer, icon: const Icon(Icons.add), label: Text(_saving ? 'Kaydediliyor…' : 'Şehir fırsatı ekle')),
                ],
                const SizedBox(height: 18),
                if (rows.isEmpty)
                  Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: const Text('Bu şehir için henüz yayınlanmış fırsat yok. Fırsatlar yönetici tarafından eklendiğinde burada görünür.'))
                else
                  ...rows.map((row) => Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: const Icon(Icons.local_offer_outlined, size: 30),
                      title: Text(row['title']?.toString() ?? 'Şehir fırsatı', style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Text([
                        if ((row['discount_text'] ?? '').toString().isNotEmpty) row['discount_text'].toString(),
                        if ((row['description'] ?? '').toString().isNotEmpty) row['description'].toString(),
                        row['city']?.toString() ?? widget.city,
                      ].join('\n'))),
                      trailing: row['source_url'] is String ? const Icon(Icons.open_in_new) : null,
                      onTap: () => _openSource(row['source_url'] as String?),
                    ),
                  )),
              ],
            );
          },
          ),
        ),
      ),
    );
  }
}
