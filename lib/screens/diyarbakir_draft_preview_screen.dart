import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DiyarbakirDraftPreviewScreen extends StatefulWidget {
  const DiyarbakirDraftPreviewScreen({super.key});

  @override
  State<DiyarbakirDraftPreviewScreen> createState() =>
      _DiyarbakirDraftPreviewScreenState();
}

class _DiyarbakirDraftPreviewScreenState
    extends State<DiyarbakirDraftPreviewScreen> {
  late final Future<Map<String, dynamic>> _draftFuture =
      _loadDraft();
  String _search = '';
  String _category = 'Tümü';

  Future<Map<String, dynamic>> _loadDraft() async {
    final raw = await rootBundle.loadString(
      'data/place_pilots/diyarbakir_draft.json',
    );
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diyarbakır Yer Taslağı'),
        actions: [
          IconButton(
            tooltip: 'Test hakkında',
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'BUGÜN - Diyarbakır Test',
              applicationVersion: '0.1.4-test',
              children: const [
                Text('Bu ayrı test uygulaması, paket içine eklenmiş JSON taslağını çevrimdışı gösterir. Canlı Supabase verisini değiştirmez ve mevcut BUGÜN uygulamasının yerine geçmez.'),
              ],
            ),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _draftFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Taslak dosyası açılamadı. Bu test APK içindeki veri dosyasını kontrol etmek gerekiyor.'),
              ),
            );
          }

          final draft = snapshot.data!;
          final places = (draft['places'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
          final categories = <String>{
            'Tümü',
            ...places.map((p) => (p['category'] ?? 'Diğer').toString()),
          }.toList()
            ..sort((a, b) => a == 'Tümü' ? -1 : (b == 'Tümü' ? 1 : a.compareTo(b)));

          final filtered = places.where((place) {
            final category = (place['category'] ?? 'Diğer').toString();
            final text = _normalize([
              place['name'] ?? '',
              place['district'] ?? '',
              place['category'] ?? '',
              place['short_description'] ?? '',
            ].join(' '));
            return (_category == 'Tümü' || category == _category) &&
                text.contains(_normalize(_search.trim()));
          }).toList();

          final withCoordinates = places.where((p) =>
              p['latitude'] is num && p['longitude'] is num).length;
          return Column(
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xFFFFF0D6),
                padding: const EdgeInsets.all(12),
                child: const Text(
                  'TEST TASLAĞI • Yayımlanmış veri değildir. Bu ekrandaki kayıtlar canlı uygulamaya aktarılmaz. Konum ve kaynak doğrulaması bekleyen kayıtlar bulunur.',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  onChanged: (value) => setState(() => _search = value),
                  decoration: InputDecoration(
                    hintText: 'Yer, ilçe veya açıklama ara',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _search = ''),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = categories[index];
                    return ChoiceChip(
                      label: Text(item),
                      selected: _category == item,
                      onSelected: (_) => setState(() => _category = item),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${filtered.length} / ${places.length} aday yer',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text('$withCoordinates konumlu'),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('Aramayla eşleşen yer bulunamadı.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final place = filtered[index];
                          final hasCoordinates = place['latitude'] is num &&
                              place['longitude'] is num;
                          return Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          (place['name'] ?? 'İsimsiz yer').toString(),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        hasCoordinates ? Icons.location_on_outlined : Icons.location_off_outlined,
                                        size: 20,
                                        color: hasCoordinates ? Colors.green.shade700 : Colors.orange.shade800,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text('${place['district'] ?? 'İlçe belirtilmemiş'} • ${place['category'] ?? 'Diğer'}'),
                                  const SizedBox(height: 8),
                                  Text((place['short_description'] ?? 'Açıklama henüz eklenmemiş.').toString()),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _statusChip(hasCoordinates ? 'Koordinat var • doğrulama bekliyor' : 'Koordinat eksik'),
                                      _statusChip('Yayımlanmadı'),
                                    ],
                                  ),
                                  if (hasCoordinates) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '${(place['latitude'] as num).toStringAsFixed(5)}, ${(place['longitude'] as num).toStringAsFixed(5)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                  if (place['editorial_note'] != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Editör notu: ${place['editorial_note']}',
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusChip(String label) => Chip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
      );
}