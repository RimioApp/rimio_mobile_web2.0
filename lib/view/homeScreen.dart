import 'dart:developer';
import 'package:Rimio/adHelper.dart';
import 'package:Rimio/providers/favoritos_provider.dart';
import 'package:Rimio/providers/order_provider.dart';
import 'package:Rimio/providers/product_provider.dart';
import 'package:Rimio/providers/publish_provider.dart';
import 'package:Rimio/providers/user_provider.dart';
import 'package:Rimio/providers/venta_provider.dart';
import 'package:Rimio/providers/vistoReciente_provider.dart';
import 'package:Rimio/view/models/categoria_model.dart';
import 'package:Rimio/view/searchPage.dart';
import 'package:Rimio/widgets/bottomBar.dart';
import 'package:Rimio/widgets/categoryWidget.dart';
import 'package:Rimio/widgets/productWidget.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:Rimio/widgets/itemTile.dart';
import 'package:provider/provider.dart';
//import 'package:google_mobile_ads/google_mobile_ads.dart';

class homeScreen extends StatefulWidget {
  const homeScreen({super.key});

  @override
  State<homeScreen> createState() => _homeScreenState();
}

class _homeScreenState extends State<homeScreen> {

  List ofertas = [
    ['Guitarra Ibanez Prestige', 'Nuevo', '\$120', 'Carabobo'],
    ['Bajo Fender', 'Usado', '\$169.99', 'Anzoátegui'],
    ['Teclado Korg', 'Nuevo', '\$1255', 'Dtto. Capital'],
    ['Batería Tama', 'Usado', '\$650', 'Aragua'],
    ['Mezclador Yamaha', 'Usado', '\$230', 'Miranda']
  ];

  List recientes = [
    ['Cuatro de concierto', 'Nuevo', '\$80', 'Barquisimeto'],
    ['Bajo Schecter', 'Usado', '\$130', 'Aragua'],
    ['Micrófono XML', 'Nuevo', '\$150', 'Dtto. Capital'],
    ['Amplificador Peavey Bandit 112', 'Usado', '\$650', 'Carabobo'],
    ['Guitarra Jackson', 'Usado', '\$1800', 'Anzoátegui']
  ];

  List cuerdas = [
    ['Violin', 'Usado', '\$150', 'Carabobo'],
    ['Bajo Warwick', 'Usado', '\$1500', 'Zulia'],
    ['Ukelele', 'Nuevo', '\$60', 'Barquisimeto'],
    ['Guitarra Clásica Yamaha', 'Nuevo', '\$650', 'Zulia'],
    ['Guitarra Acústica Martin & Co', 'Usado', '\$800', 'Dtto. Capital']
  ];

  List<CategoriaModel> categoriaLista = [
    CategoriaModel(id: 'Guitarras', name: 'Guitarras', image: 'assets/guitarra.png'),
    CategoriaModel(id: 'Bajos', name: 'Bajos', image: 'assets/bass.png'),
    CategoriaModel(id: 'Amps', name: 'Amps', image: 'assets/amp.png'),
    CategoriaModel(id: 'Baterias', name: 'Baterias', image: 'assets/bateria.png'),
    CategoriaModel(id: 'Teclados', name: 'Teclados', image: 'assets/teclado.png'),
    CategoriaModel(id: 'Folklore', name: 'Folklore', image: 'assets/tradicional.png'),
    CategoriaModel(id: 'Orquesta', name: 'Orquesta', image: 'assets/orquesta.png'),
    CategoriaModel(id: 'Dj', name: 'Dj', image: 'assets/dj.png'),
    CategoriaModel(id: 'Microfonos', name: 'Micrófonos', image: 'assets/microphone.png'),
    CategoriaModel(id: 'Aire', name: 'Aire', image: 'assets/aire.png'),
    CategoriaModel(id: 'Estudio', name: 'Estudio', image: 'assets/estudio.png'),
    CategoriaModel(id: 'Merch', name: 'Merch', image: 'assets/camisa.png'),
    CategoriaModel(id: 'Iluminacion', name: 'Iluminación', image: 'assets/spotlight.png'),
    CategoriaModel(id: 'Pedales', name: 'Pedales', image: 'assets/guitar-pedal.png'),
    CategoriaModel(id: 'Servicios', name: 'Servicios', image: 'assets/servicio.png'),
    CategoriaModel(id: 'Accesorios', name: 'Accesorios', image: 'assets/pick.png'),
    CategoriaModel(id: 'Repuestos', name: 'Repuestos', image: 'assets/metal.png'),
  ];

  bool isLoadingProd = true;

  Future<void> fetchFCT() async {
    final productsProvider = Provider.of<ProductsProvider>(context, listen: false);
    final favoritosProvider = Provider.of<FavoritosProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final publishProvider = Provider.of<PublishProvider>(context, listen: false);
    final ventaProvider = Provider.of<VentaProvider>(context, listen: false);
    final vistoProvider = Provider.of<VistoRecienteProvider>(context, listen: false);

    try {
      Future.wait({
        productsProvider.fetchProducts(),
        userProvider.fetchUserInfo(),
      });
      Future.wait({
        favoritosProvider.fetchWishlist(),
        orderProvider.fetchUserOrderslist(),
        publishProvider.fetchUserPublishlist(),
        ventaProvider.fetchUserVentalist(),
        vistoProvider.fetchVistolist(),
      });
    } catch (error) {
      log(error.toString());
    }
  }

  @override
  void didChangeDependencies() {
    if (isLoadingProd) {
      fetchFCT();
    }
    super.didChangeDependencies();
  }

  bool _isBannerAdReady = false;

  List<String> bannerImages = [];

  @override
  void initState() {
    super.initState();
    fetchBanners();
  }

  /// Fetching banners
  Future<void> fetchBanners() async {
    try {
      //final userDoc = await FirebaseFirestore.instance.collection("banners").doc('homescreenbanners').get();
      final ref1 = FirebaseStorage.instance.ref().child('bannerImages').child('banner1.jpg');
      final ref2 = FirebaseStorage.instance.ref().child('bannerImages').child('banner2.jpg');
      final ref3 = FirebaseStorage.instance.ref().child('bannerImages').child('banner3.jpg');
      final ref4 = FirebaseStorage.instance.ref().child('bannerImages').child('bannerUsa.png');

      String banner1 = await ref1.getDownloadURL();
      String banner2 = await ref2.getDownloadURL();
      String banner3 = await ref3.getDownloadURL();
      String banner4 = await ref4.getDownloadURL();

      bannerImages = [banner4, banner1, banner2, banner3];
    } catch (e) {}
  }
  /// /// /// /// ///


  @override
  Widget build(BuildContext context) {

    final productProvider = Provider.of<ProductsProvider>(context);
    final vistoProvider = Provider.of<VistoRecienteProvider>(context);

    for (var url in bannerImages) {
      precacheImage(NetworkImage(url),context);
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: 1000,
            child: Column(
              children: [
                const SizedBox(height: 5,),
                StreamBuilder(
                  stream: productProvider.fetchProductsStream(),
                  builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return const MaterialApp(
                        debugShowCheckedModeBanner: false,
                        home: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: SelectableText(snapshot.error.toString()),
                      );
                    } else if (snapshot.data == null) {
                      return const Center(
                          child: CircularProgressIndicator(color: Colors.deepPurple,)
                      );
                    }
                    return Container(
                      height: 250,
                      width: MediaQuery.of(context).size.width,
                      child: Swiper(
                        containerWidth: MediaQuery.of(context).size.width,
                        autoplay: true,
                        autoplayDelay: 5000,
                        duration: 2000,
                        curve: Curves.ease,
                        itemBuilder: (BuildContext context,int index){
                          return Image.network(bannerImages[index]);
                        },
                        itemCount: bannerImages.length,
                        // pagination: const SwiperPagination(
                        //     builder: SwiperPagination.dots
                        // ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 5,),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Categorías', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),),
                    ],
                  ),
                ),
                const SizedBox(height: 8,),
                SizedBox(
                  height: 80,
                  child: ListView(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      children: List.generate(categoriaLista.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: CategoryWidget(image: categoriaLista[index].image, categoria: categoriaLista[index].name),
                        );
                      })),
                ),
                Visibility(
                  visible: vistoProvider.getVisto.isNotEmpty,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0, left: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Visibility(
                            visible: productProvider.getProducts.isNotEmpty,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('Vistos recientemente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),),
                            )),
                      ],
                    ),
                  ),
                ),
                Visibility(
                  visible: vistoProvider.getVisto.isNotEmpty,
                  child: SizedBox(
                    height: 310,
                    width: double.maxFinite,
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: vistoProvider.getVisto.length < 10
                            ? vistoProvider.getVisto.length
                            : 10,
                        itemBuilder: (context, index){
                          return Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: ProductWidget(productId: vistoProvider.getVisto.values.toList()[index].productId,),
                          );
                        }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Visibility(
                          visible: productProvider.getProducts.isNotEmpty,
                          child: const Text('Publicaciones recientes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),)),
                      GestureDetector(
                          onTap: (){},
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, SearchPage.routeName);
                            },
                            child: Visibility(
                                visible: productProvider.getProducts.isNotEmpty,
                                child: const Text('Ver más', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.purple),)),)),
                    ],
                  ),
                ),
                Visibility(
                  visible: productProvider.getProducts.isNotEmpty,
                  child: SizedBox(
                    height: 310,
                    width: double.maxFinite,
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: productProvider.getProducts.length < 10
                            ? productProvider.getProducts.length
                            : 10,
                        itemBuilder: (context, index){
                          return ChangeNotifierProvider.value(
                              value: productProvider.getProducts[index],
                              child: itemTile());
                        }),
                  ),
                ),
                /*Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ofertas de la semana', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),),
                      GestureDetector(
                          onTap: (){},
                          child: const Text('Ver más', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.purple),)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 260,
                  width: double.maxFinite,
                  child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: ofertas.length,
                      itemBuilder: (context, index){
                        return itemTile(
                            producto: ofertas[index][0],
                            estado: ofertas[index][1],
                            ubicacion: ofertas[index][3],
                            precio: ofertas[index][2]);
                      }),
                ),
                const SizedBox(height: 20,),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Instrumentos de cuerdas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),),
                      GestureDetector(
                          onTap: (){},
                          child: const Text('Ver más', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.purple),)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 260,
                  width: double.maxFinite,
                  child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: cuerdas.length,
                      itemBuilder: (context, index){
                        return itemTile(
                            producto: cuerdas[index][0],
                            estado: cuerdas[index][1],
                            ubicacion: cuerdas[index][3],
                            precio: cuerdas[index][2]);
                      }),
                ),*/
              ],
            ),
          ),
        ),
      ),
    );
  }
}
