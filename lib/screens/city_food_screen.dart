import 'package:flutter/material.dart';
import '../models/city_food.dart';
import '../services/city_food_service.dart';
import 'city_food_detail_screen.dart';

class CityFoodScreen extends StatefulWidget {
  final String city;
  const CityFoodScreen({super.key, required this.city});
  @override State<CityFoodScreen> createState() => _CityFoodScreenState();
}
class _CityFoodScreenState extends State<CityFoodScreen> {
  final _service = CityFoodService();
  late Future<List<CityFood>> _foods;
  @override void initState() { super.initState(); _foods = _service.getPublishedFoods(widget.city); }
  @override void didUpdateWidget(covariant CityFoodScreen old) { super.didUpdateWidget(old); if (old.city != widget.city) _foods = _service.getPublishedFoods(widget.city); }
  Future<void> _reload() async { final f = _service.getPublishedFoods(widget.city); setState(() => _foods = f); await f; }
  Future<void> _suggest() async {
    final name = TextEditingController(); final note = TextEditingController(); final key = GlobalKey<FormState>();
    final accepted = await showDialog<bool>(context: context, builder: (dc) => AlertDialog(
      title: const Text('Yemek öner'),
      content: Form(key: key, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${widget.city} için listede görmek istediğin yemeği bize önerebilirsin.', style: const TextStyle(color: Colors.black54)), const SizedBox(height: 14),
        TextFormField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Yemek adı *', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Yemek adını yaz.' : null),
        const SizedBox(height: 10), TextFormField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Açıklama veya not (isteğe bağlı)', border: OutlineInputBorder())),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(dc, false), child: const Text('VAZGEÇ')), FilledButton(onPressed: () { if (key.currentState!.validate()) Navigator.pop(dc, true); }, child: const Text('ÖNERİYİ GÖNDER'))],
    ));
    if (accepted == true && mounted) {
      try { await _service.submitSuggestion(city: widget.city, foodName: name.text, note: note.text); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Önerin alındı. Yönetici incelemesinden sonra yayımlanabilir.'))); }
      catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Öneri gönderilemedi. Lütfen daha sonra tekrar dene.'))); }
    }
    name.dispose(); note.dispose();
  }
  @override Widget build(BuildContext context) => FutureBuilder<List<CityFood>>(future: _foods, builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
    if (snapshot.hasError) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Yemek önerileri yüklenemedi.'), TextButton(onPressed: _reload, child: const Text('Tekrar dene'))]));
    final foods = snapshot.data ?? const <CityFood>[];
    return RefreshIndicator(onRefresh: _reload, child: ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 28), children: [
      Text(widget.city.toUpperCase(), style: const TextStyle(fontSize: 12, letterSpacing: 1.4, color: Color(0xFF1268B3), fontWeight: FontWeight.w800)), const SizedBox(height: 5),
      const Text('ŞEHRİN LEZZETLERİ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 14),
      if (foods.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 34), child: Column(children: [Icon(Icons.ramen_dining_outlined, size: 48, color: Color(0xFF1268B3)), SizedBox(height: 12), Text('Bu şehir için henüz yemek önerisi eklenmemiş.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54))]))
      else for (final food in foods) Padding(padding: const EdgeInsets.only(bottom: 10), child: Material(color: Colors.white, borderRadius: BorderRadius.circular(16), child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => CityFoodDetailScreen(food: food))), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Container(width: 38, height: 38, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFFFF0E6), borderRadius: BorderRadius.circular(12)), child: Text('${food.sortOrder}', style: const TextStyle(color: Color(0xFFB85C20), fontWeight: FontWeight.w900))), const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(food.name.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: .25)), if ((food.shortDescription ?? '').trim().isNotEmpty) ...[const SizedBox(height: 5), Text(food.shortDescription!, style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.35))]])), const SizedBox(width: 6), const Icon(Icons.chevron_right, color: Colors.black45)
      ]))))),
      const SizedBox(height: 18), OutlinedButton.icon(onPressed: _suggest, icon: const Icon(Icons.add_comment_outlined), label: const Text('ÖNER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .6)), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56), foregroundColor: const Color(0xFF1268B3), side: const BorderSide(color: Color(0xFF1268B3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
      const SizedBox(height: 8), const Text('Önerilerin yönetici tarafından incelendikten sonra yayımlanır.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.black45)),
    ]));
  });
}
