import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/city_food.dart';

class CityFoodDetailScreen extends StatelessWidget {
  final CityFood food;
  const CityFoodDetailScreen({super.key,required this.food});
  Future<void> _openMap(BuildContext context) async {
    final u=Uri.tryParse((food.mapUrl??'').trim());
    if(u==null||!await launchUrl(u,mode:LaunchMode.externalApplication)){
      if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Harita bağlantısı açılamadı.')));
    }
  }
  @override Widget build(BuildContext context){
    final hasVenue=[food.whereToEat,food.venueName,food.venueAddress,food.mapUrl].any((v)=>(v??'').trim().isNotEmpty);
    return Scaffold(backgroundColor:const Color(0xFFFFF0DF),appBar:AppBar(title:const Text('Ne Yenir?'),backgroundColor:const Color(0xFFFFF0DF),surfaceTintColor:Colors.transparent),
      body:ListView(padding:const EdgeInsets.fromLTRB(18,8,18,28),children:[
        if((food.imageUrl??'').trim().isNotEmpty)ClipRRect(borderRadius:BorderRadius.circular(18),child:Image.network(food.imageUrl!,height:210,width:double.infinity,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox.shrink())),
        const SizedBox(height:16),Text(food.city.toUpperCase(),style:const TextStyle(color:Color(0xFF1268B3),fontSize:12,letterSpacing:1.3,fontWeight:FontWeight.w800)),
        const SizedBox(height:6),Text(food.name.toUpperCase(),style:const TextStyle(fontSize:26,height:1.12,fontWeight:FontWeight.w900)),
        if((food.shortDescription??'').trim().isNotEmpty)...[const SizedBox(height:12),Text(food.shortDescription!,style:const TextStyle(fontSize:15,color:Colors.black87,height:1.5,fontWeight:FontWeight.w600))],
        if((food.longDescription??'').trim().isNotEmpty)...[const SizedBox(height:18),Text(food.longDescription!,style:const TextStyle(fontSize:14,height:1.65,color:Colors.black87))],
        const SizedBox(height:24),
        Container(width:double.infinity,padding:const EdgeInsets.fromLTRB(18,20,18,20),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:const Color(0xFFFFD7BE))),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('NEREDE YENİR?',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900,color:Color(0xFF9C4D1C),letterSpacing:.5)),const SizedBox(height:12),
            if(!hasVenue)const Text('Bu yemek için mekân bilgisi henüz eklenmemiş.',style:TextStyle(color:Colors.black54,height:1.45)) else ...[
              if((food.whereToEat??'').trim().isNotEmpty)Text(food.whereToEat!,style:const TextStyle(fontSize:14,height:1.6)),
              if((food.venueName??'').trim().isNotEmpty)...[const SizedBox(height:12),Text(food.venueName!,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w800))],
              if((food.venueAddress??'').trim().isNotEmpty)...[const SizedBox(height:5),Text(food.venueAddress!,style:const TextStyle(fontSize:13,color:Colors.black54,height:1.4))],
              if((food.mapUrl??'').trim().isNotEmpty)...[const SizedBox(height:14),OutlinedButton.icon(onPressed:()=>_openMap(context),icon:const Icon(Icons.map_outlined),label:const Text('Haritada göster'))],
            ],
          ])),
      ]));
  }
}
