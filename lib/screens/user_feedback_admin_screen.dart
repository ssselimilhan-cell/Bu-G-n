import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserFeedbackAdminScreen extends StatefulWidget {
  const UserFeedbackAdminScreen({super.key});

  @override
  State<UserFeedbackAdminScreen> createState() => _UserFeedbackAdminScreenState();
}

class _UserFeedbackAdminScreenState extends State<UserFeedbackAdminScreen> {
  final _client = Supabase.instance.client;
  static const _filters = ['Tümü', 'Öneri', 'Hata bildirimi', 'İçerik düzeltme', 'Diğer'];
  static const _statuses = <String, String>{
    'new': 'Yeni',
    'reviewing': 'İnceleniyor',
    'answered': 'Yanıtlandı',
    'closed': 'Kapatıldı',
  };
  String _filter = 'Tümü';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  final Set<String> _busyIds = <String>{};

  bool get _isAdmin => _client.auth.currentUser?.appMetadata['role'] == 'admin';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_isAdmin) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Bu alan yalnızca yöneticilere açıktır.';
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _client
          .from('app_feedback')
          .select('id,user_id,email,category,message,app_version,status,created_at')
          .order('created_at', ascending: false)
          .limit(300);
      if (!mounted) return;
      setState(() {
        _items = rows.whereType<Map<String, dynamic>>().toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Geri bildirimler yüklenemedi. Yönetici okuma iznini ve veritabanı güncellemesini kontrol et.';
      });
    }
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 'Tarih bilinmiyor';
    return DateFormat('d MMM yyyy · HH:mm', 'tr_TR').format(date.toLocal());
  }

  Future<void> _changeStatus(Map<String, dynamic> item, String status) async {
    final id = item['id']?.toString();
    if (id == null || id.isEmpty || _busyIds.contains(id)) return;
    setState(() => _busyIds.add(id));
    try {
      await _client.from('app_feedback').update({'status': status}).eq('id', id);
      if (!mounted) return;
      setState(() {
        item['status'] = status;
        _busyIds.remove(id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Durum güncellendi: ${_statuses[status]}')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busyIds.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Durum güncellenemedi. Yönetici güncelleme iznini kontrol et.')),
      );
    }
  }

  Future<void> _deleteFeedback(Map<String, dynamic> item) async {
    final id = item['id']?.toString();
    if (id == null || id.isEmpty || _busyIds.contains(id)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Geri bildirim silinsin mi?'),
        content: const Text('Bu kayıt kalıcı olarak silinecek. Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyIds.add(id));
    try {
      await _client.from('app_feedback').delete().eq('id', id);
      if (!mounted) return;
      setState(() {
        _items.removeWhere((entry) => entry['id']?.toString() == id);
        _busyIds.remove(id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geri bildirim silindi.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busyIds.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geri bildirim silinemedi. Yönetici silme iznini kontrol et.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kullanıcı geri bildirimleri')),
        body: const Center(child: Text('Bu alan yalnızca yöneticilere açıktır.')),
      );
    }
    final visible = _filter == 'Tümü'
        ? _items
        : _items.where((item) => item['category'] == _filter).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        title: const Text('KULLANICI GERİ BİLDİRİMLERİ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: const Color(0xFFF7F7F5),
        surfaceTintColor: Colors.transparent,
        actions: [IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: DropdownButtonFormField<String>(
              value: _filter,
              decoration: const InputDecoration(labelText: 'Bildirim türü', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
              items: _filters.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _filter = value);
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
                    : visible.isEmpty
                        ? const Center(child: Text('Bu filtrede henüz geri bildirim yok.'))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: visible.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = visible[index];
                              final email = item['email']?.toString().trim() ?? '';
                              final status = item['status']?.toString() ?? 'new';
                              final id = item['id']?.toString() ?? '';
                              final busy = _busyIds.contains(id);
                              return Card(
                                color: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: Color(0xFFE8E8E5)),
                                ),
                                child: ExpansionTile(
                                  leading: const Icon(Icons.feedback_outlined),
                                  title: Text(item['category']?.toString() ?? 'Genel', style: const TextStyle(fontWeight: FontWeight.w800)),
                                  subtitle: Text('${_date(item['created_at'])} · ${_statuses[status] ?? status}'),
                                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SelectableText(item['message']?.toString() ?? ''),
                                    if (email.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      SelectableText('E-posta: $email'),
                                    ],
                                    if (item['app_version'] != null) ...[
                                      const SizedBox(height: 6),
                                      Text('Uygulama sürümü: ${item['app_version']}'),
                                    ],
                                    if (item['user_id'] != null) ...[
                                      const SizedBox(height: 6),
                                      Text('Kullanıcı hesabı: ${item['user_id']}'),
                                    ],
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        const Text('Durum:', style: TextStyle(fontWeight: FontWeight.w700)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: _statuses.containsKey(status) ? status : 'new',
                                            isExpanded: true,
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                              border: OutlineInputBorder(),
                                            ),
                                            items: _statuses.entries
                                                .map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value)))
                                                .toList(),
                                            onChanged: busy ? null : (value) {
                                              if (value != null && value != status) _changeStatus(item, value);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: busy ? null : () => _deleteFeedback(item),
                                        icon: busy
                                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                            : const Icon(Icons.delete_outline, color: Colors.red),
                                        label: const Text('Geri bildirimi sil', style: TextStyle(color: Colors.red)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${visible.length} geri bildirim gösteriliyor', style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ),
        ],
      ),
    );
  }
}
