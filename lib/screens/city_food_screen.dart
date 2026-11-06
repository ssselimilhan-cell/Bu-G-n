import 'package:flutter/material.dart';
import '../models/city_food.dart';
import '../services/city_food_service.dart';
import 'city_food_detail_screen.dart';

class CityFoodScreen extends StatefulWidget {
  final String city;
  const CityFoodScreen({super.key,required this.city});
  @override State<CityFoodScreen> createState()=>_CityFoodScreenState();
}
class _CityFoodScreenState extends State<CityFoodScreen> {
  final _service=CityFoodService();
  late Future<List<CityFood>> _foods;
  @override void initState(){super.initState();_foods=_service.getPublishedFoods(widget.city);}
  @override void didUpdateWidget(covariant CityFoodScreen old){super.didUpdateWidget(old);if(old.city!=widget.city)_foods=_service.getPublishedFoods(widget.city);}
  Future<void> _reload() async {final f=_service.getPublishedFoods(widget.city);setState(()=>_foods=f);await f;}
  @override Widget build(BuildContext context)=>FutureBuilder<List<CityFood>>(future:_foods,builder:(context,s){
    if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
    if(s.hasError)return Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('Yemek önerileri yüklenemedi.'),TextButton(onPressed:_reload,child:const Text('Tekrar dene'))]));
    final foods=s.data??const <CityFood>[];
    if(foods.isEmpty)return Center(child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.ramen_dining_outlined,size:48,color:Color(0xFF1268B3)),const SizedBox(height:12),Text(widget.city,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),const SizedBox(height:8),const Text('Bu şehir için henüz yemek önerisi eklenmemiş.',textAlign:TextAlign.center,style:TextStyle(color:Colors.black54))])));
    return RefreshIndicator(onRefresh:_reload,child:ListView(padding:const EdgeInsets.fromLTRB(16,14,16,24),children:[
      Text(widget.city.toUpperCase(),style:const TextStyle(fontSize:12,letterSpacing:1.4,color:Color(0xFF1268B3),fontWeight:FontWeight.w800)),
      const SizedBox(height:5),const Text('ŞEHRİN LEZZETLERİ',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:14),
      for(final food in foods) Padding(padding:const EdgeInsets.only(bottom:10),child:Material(color:Colors.white,borderRadius:BorderRadius.circular(16),child:InkWell(borderRadius:BorderRadius.circular(16),onTap:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>CityFoodDetailScreen(food:food))),child:Padding(padding:const EdgeInsets.all(16),child:Row(children:[
        Container(width:38,height:38,alignment:Alignment.center,decoration:BoxDecoration(color:const Color(0xFFFFF0E6),borderRadius:BorderRadius.circular(12)),child:Text('${food.sortOrder}',style:const TextStyle(color:Color(0xFFB85C20),fontWeight:FontWeight.w900))),
        const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(food.name.toUpperCase(),style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900,letterSpacing:.25)),
          if((food.shortDescription??'').trim().isNotEmpty)...[const SizedBox(height:5),Text(food.shortDescription!,style:const TextStyle(fontSize:12,color:Colors.black54,height:1.35))],
        ])),const SizedBox(width:6),const Icon(Icons.chevron_right,color:Colors.black45)
      ]))))),
    ]));
  });
}
