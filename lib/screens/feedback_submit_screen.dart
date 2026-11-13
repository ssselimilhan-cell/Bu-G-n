import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackSubmitScreen extends StatefulWidget {
  const FeedbackSubmitScreen({super.key});

  @override
  State<FeedbackSubmitScreen> createState() => _FeedbackSubmitScreenState();
}

class _FeedbackSubmitScreenState extends State<FeedbackSubmitScreen> {
  final _client = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  static const _categories = ['Öneri', 'Hata bildirimi', 'İçerik düzeltme', 'Diğer'];
  String _category = 'Öneri';
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = _client.auth.currentUser?.email ?? '';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      final user = _client.auth.currentUser;
      await _client.from('app_feedback').insert({
        'user_id': user?.id,
        'email': _emailController.text.trim().isEmpty
            ? user?.email
            : _emailController.text.trim(),
        'category': _category,
        'message': _messageController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geri bildirimin bize ulaştı. Teşekkür ederiz.')),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gönderilemedi. İnternet bağlantını kontrol edip tekrar dene.')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0DF),
      appBar: AppBar(
        title: const Text('BİZE ULAŞIN', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFFFF0DF),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'BUGÜN’ü geliştirmemize yardımcı ol. Önerilerini, karşılaştığın hataları veya içerik düzeltmelerini buradan bize iletebilirsin.',
                style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
              ),
              const SizedBox(height: 22),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Bildirim türü',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _categories
                    .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: _sending ? null : (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _messageController,
                minLines: 5,
                maxLines: 9,
                maxLength: 3000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Mesajın',
                  hintText: 'Önerini veya karşılaştığın sorunu ayrıntılı anlat...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) => value == null || value.trim().length < 5
                    ? 'Lütfen en az 5 karakterlik bir mesaj yaz.'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-posta (isteğe bağlı)',
                  hintText: 'Yanıt vermemizi istersen e-posta adresini yaz',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    return 'Geçerli bir e-posta adresi gir.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _sending ? null : _submit,
                icon: _sending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
                label: Text(_sending ? 'GÖNDERİLİYOR...' : 'GERİ BİLDİRİMİ GÖNDER'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Geri bildirimin yalnızca BUGÜN yönetim ekibi tarafından görüntülenir.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
