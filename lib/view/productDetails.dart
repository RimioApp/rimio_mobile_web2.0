import 'dart:convert';
import 'dart:ui';
import 'dart:async';
import 'package:Rimio/adHelper.dart';
import 'package:Rimio/providers/favoritos_provider.dart';
import 'package:Rimio/providers/order_provider.dart';
import 'package:Rimio/providers/preguntaProvider.dart';
import 'package:Rimio/providers/product_provider.dart';
import 'package:Rimio/providers/publish_provider.dart';
import 'package:Rimio/providers/user_provider.dart';
import 'package:Rimio/providers/venta_provider.dart';
import 'package:Rimio/view/authPages/login.dart';
import 'package:Rimio/view/favoritos.dart';
import 'package:Rimio/view/home.dart';
import 'package:Rimio/view/models/categoria_model.dart';
import 'package:Rimio/view/models/product_model.dart';
import 'package:Rimio/view/models/user_model.dart';
import 'package:Rimio/view/rootScreen.dart';
import 'package:Rimio/view/searchPage.dart';
import 'package:Rimio/widgets/fav_button.dart';
import 'package:Rimio/widgets/publish_widget.dart';
import 'package:action_slider/action_slider.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;


class ProductDetails extends StatefulWidget {
  static const routeName = '/ProductDetails';
  const ProductDetails({super.key, this.productModel, this.productsProvider,});

  final ProductModel? productModel;
  final ProductsProvider? productsProvider;

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}


class _ProductDetailsState extends State<ProductDetails> {

  List<CategoriaModel> categoriaLista = [
    CategoriaModel(id: 'Guitarra', name: 'Guitarra', image: 'assets/guitarra.png'),
    CategoriaModel(id: 'Bateria', name: 'Bateria', image: 'assets/bateria.png'),
    CategoriaModel(id: 'Teclado', name: 'Teclado', image: 'assets/teclado.png'),
    CategoriaModel(id: 'Folklore', name: 'Folklore', image: 'assets/tradicional.png'),
    CategoriaModel(id: 'Orquesta', name: 'Orquesta', image: 'assets/orquesta.png'),
    CategoriaModel(id: 'Dj', name: 'Dj', image: 'assets/dj.png'),
    CategoriaModel(id: 'Aire', name: 'Aire', image: 'assets/aire.png'),
    CategoriaModel(id: 'Estudio', name: 'Estudio', image: 'assets/estudio.png'),
    CategoriaModel(id: 'Merch', name: 'Merch', image: 'assets/camisa.png'),
  ];

  final auth = FirebaseAuth.instance;
  Timer? timer;
  bool showModal = false;

  bool star1 = false;
  bool star2 = false;
  bool star3 = false;
  bool star4 = false;
  bool star5 = false;

  late bool calificado = false;

  @override
  void initState() {
    super.initState();
    loadCalificado();
  }

  void loadCalificado() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      calificado = prefs.getBool('calificado') ?? false;
    });
  }

  void saveCalificado() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setBool('calificado', calificado);
    });
  }

  Future<void> shareToWhatsApp(String text, String imageUrl) async {
    final String whatsAppUrl = 'whatsapp://send?text=$text&source=$imageUrl&data=$imageUrl';

    try {
      await launch(whatsAppUrl);
    } catch (e) {
      print('Could not launch $whatsAppUrl');
    }
  }

  TextEditingController _preguntaController = TextEditingController();
  TextEditingController _respuestaController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    Size size = MediaQuery.of(context).size;
    final productsProvider = Provider.of<ProductsProvider>(context);
    String? productId = ModalRoute.of(context)!.settings.arguments as String?;
    final getCurrentProduct = productsProvider.findByProdId(productId!);

    final favoritosProvider = Provider.of<FavoritosProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context);
    final ventaProvider = Provider.of<VentaProvider>(context);
    final preguntaProvider = Provider.of<PreguntaProvider>(context);
    final publishProvider = Provider.of<PublishProvider>(context);


    @override
    void dispose() {
      timer?.cancel();
      super.dispose();
    }


    UserModel? userModel;
    User? user = FirebaseAuth.instance.currentUser;
    bool _isLoading = false;

    Future<void> fetchUserInfo() async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      try {
        setState(() {
          _isLoading = true;
        });
        userModel = await userProvider.fetchUserInfo();
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }

    @override
    void initState() async {
      super.initState();
      fetchUserInfo();
    }

    Future sendEmail({
      required String name,
      required String email,
      required String subject,
      required String message,
    }) async {

      final serviceId = 'service_3v0pszg';
      final templateId = 'template_53tf042';
      final userId = 'oeIkDnH7heER4ZUR9';

      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
          url,
      headers: {
            'origin':'https://localhost',
            'Content-type':'application/json',
      },
      body: jsonEncode({
            'service_id': serviceId,
            'template_id': templateId,
            'user_id': userId,
        'template_params': {
              'user_name': name,
              'to_email': email,
              'user_subject': subject,
              'user_message': message,
        }
      }));
    }

    final Uri phoneNumber = Uri.parse('tel: ${getCurrentProduct!.userPhone}');
    final Uri whatsappNumber = Uri.parse('https://wa.me/${getCurrentProduct.userPhone}');

    final User? userId = auth.currentUser;

    Timestamp? stamp = getCurrentProduct!.createdAt; /// fecha de publicacion en String
    DateTime date = stamp!.toDate(); /// fecha de publicacion en formato DateTime
    DateTime today = DateTime.now(); /// fecha actual

    int dayInt = today.day;
    int monthInt = today.month;
    int yearInt = today.year;

    int publishDay = date.day;
    int publishMonth = date.month;
    int publishYear = date.year;

    int days = dayInt - publishDay;
    int month = monthInt - publishMonth;
    int year = yearInt - publishYear;

    List<String> productImages =
    [getCurrentProduct.productImage1,
      getCurrentProduct.productImage2,
      getCurrentProduct.productImage3,
      getCurrentProduct.productImage4];

    int userPoints = getCurrentProduct.userPoints;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: (){
          Navigator.pop(context);
        }, icon: const Icon(Icons.arrow_back_rounded, color: Colors.white,)),
        centerTitle: true,
        title: Image.asset(height: 40,'assets/Rimio_w.png'),
        elevation: 2,
        shadowColor: Colors.purpleAccent,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: favoritosProvider.getFavoritos.isNotEmpty
                  ? Badge(
                  label: Text('${favoritosProvider.getFavoritos.length}'),
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 30,))
                  : const Icon(Icons.favorite_rounded, color: Colors.white, size: 30,),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context){
                  return const Favoritos();
                }));
              },),
          ),
        ],
      ),
      body: getCurrentProduct == null
          ? const SizedBox.shrink()
          :Center(
            child: SingleChildScrollView(
              child: SizedBox(
        width: 500,
                child: Column(
                      children: [
                if (orderProvider.getUserOrders
                    .containsKey(productId) && int.parse(getCurrentProduct.productQty) < 1)
                             Stack(
                              children:[
                                FancyShimmerImage(
                                    boxFit: BoxFit.contain,
                                    height: size.height * 0.5,
                                    width: double.infinity,
                                    imageUrl: getCurrentProduct.productImage1),
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  height: size.height * 0.5,
                                  decoration: const BoxDecoration(
                                    color: Colors.black54
                                  ),
                                ),
                                calificado
                                    ? Container(
                                    height: 100,
                                    width: MediaQuery.of(context).size.width,
                                    decoration: const BoxDecoration(
                                        color: Colors.white70
                                    ),
                                    child: Center(child:
                                    Text('¡Ya calificaste a ${getCurrentProduct.displayName}!',
                                      style: const TextStyle(fontSize: 25, color: Colors.deepPurple), overflow: TextOverflow.ellipsis,)))
                                    : Column(
                                children: [
                                  const SizedBox(height: 150,),
                                  Container(
                                    height: 100,
                                    width: MediaQuery.of(context).size.width,
                                      decoration: const BoxDecoration(
                                        color: Colors.white70
                                      ),
                                      child: Center(child:
                                      Text('Califica a ${getCurrentProduct.displayName}',
                                        style: const TextStyle(fontSize: 25, color: Colors.deepPurple), overflow: TextOverflow.ellipsis,))),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(onPressed: () async {
                                        setState(() {
                                          star1 = !star1;
                                          star2 = false;
                                          star3 = false;
                                          star4 = false;
                                          star5 = false;
                                        });
                                        try {
                                          await FirebaseFirestore.instance.collection("users").doc(getCurrentProduct.userId).update({
                                            'points': userPoints+1,
                                          });
                                        } catch (e) {

                                        }
                                        try {
                                          await FirebaseFirestore.instance.collection("products").doc(getCurrentProduct.productId).update({
                                            'userPoints': userPoints+1,
                                          });

                                        } catch (e) {

                                        }
                                        star1
                                            ? calificado = true
                                            : calificado = false;
                                        saveCalificado();

                                        /// Email de calificacion hacia vendedor ///
                                        sendEmail(
                                            name: getCurrentProduct.displayName,
                                            email: getCurrentProduct.userEmail,
                                            subject: '¡Te han calificado!',
                                            message: '${user!.displayName} acaba de calificarte por la compra de ${getCurrentProduct.productTitle}');
                                        /// /// /// /// /// ///
                                        /// Email de calificacion hacia comprador ///
                                        sendEmail(
                                            name: '${user.displayName}',
                                            email: '${user.email}',
                                            subject: '¡Tu calificación ha sido recibida!',
                                            message: 'Acabas de calificar a ${getCurrentProduct.displayName} por la compra de ${getCurrentProduct.productTitle}');
                                        /// /// /// /// /// ///

                                      }, icon: Icon(star1 ? Icons.star_rate_rounded: Icons.star_border_rounded, color: Colors.orangeAccent, size: 50,)),
                                      IconButton(onPressed: () async {
                                        setState(() {
                                          star1 = true;
                                          star2 = !star2;
                                          star3 = false;
                                          star4 = false;
                                          star5 = false;
                                        });

                                        try {
                                          await FirebaseFirestore.instance.collection("users").doc(getCurrentProduct.userId).update({
                                            'points': userPoints+2,
                                          });
                                        } catch (e) {

                                        }
                                        try {
                                          await FirebaseFirestore.instance.collection("products").doc(getCurrentProduct.productId).update({
                                            'userPoints': userPoints+2,
                                          });

                                        } catch (e) {

                                        }
                                        star1
                                            ? calificado = true
                                            : calificado = false;
                                        saveCalificado();

                                        /// Email de calificacion hacia vendedor ///
                                        sendEmail(
                                            name: getCurrentProduct.displayName,
                                            email: getCurrentProduct.userEmail,
                                            subject: '¡Te han calificado!',
                                            message: '${user!.displayName} acaba de calificarte por la compra de ${getCurrentProduct.productTitle}');
                                        /// /// /// /// /// ///
                                        /// Email de calificacion hacia comprador ///
                                        sendEmail(
                                            name: '${user.displayName}',
                                            email: '${user.email}',
                                            subject: '¡Tu calificación ha sido recibida!',
                                            message: 'Acabas de calificar a ${getCurrentProduct.displayName} por la compra de ${getCurrentProduct.productTitle}');
                                        /// /// /// /// /// ///

                                      }, icon: Icon(star2 ? Icons.star_rate_rounded: Icons.star_border_rounded, color: Colors.orangeAccent, size: 50,)),
                                      IconButton(onPressed: () async {
                                        setState(() {
                                          star1 = true;
                                          star2 = true;
                                          star3 = !star3;
                                          star4 = false;
                                          star5 = false;
                                        });

                                        try {
                                          await FirebaseFirestore.instance.collection("users").doc(getCurrentProduct.userId).update({
                                            'points': userPoints+3,
                                          });
                                        } catch (e) {

                                        }
                                        try {
                                          await FirebaseFirestore.instance.collection("products").doc(getCurrentProduct.productId).update({
                                            'userPoints': userPoints+3,
                                          });

                                        } catch (e) {

                                        }
                                        star1
                                            ? calificado = true
                                            : calificado = false;
                                        saveCalificado();

                                        /// Email de calificacion hacia vendedor ///
                                        sendEmail(
                                            name: getCurrentProduct.displayName,
                                            email: getCurrentProduct.userEmail,
                                            subject: '¡Te han calificado!',
                                            message: '${user!.displayName} acaba de calificarte por la compra de ${getCurrentProduct.productTitle}');
                                        /// /// /// /// /// ///
                                        /// Email de calificacion hacia comprador ///
                                        sendEmail(
                                            name: '${user.displayName}',
                                            email: '${user.email}',
                                            subject: '¡Tu calificación ha sido recibida!',
                                            message: 'Acabas de calificar a ${getCurrentProduct.displayName} por la compra de ${getCurrentProduct.productTitle}');
                                        /// /// /// /// /// ///

                                      }, icon: Icon(star3 ? Icons.star_rate_rounded: Icons.star_border_rounded, color: Colors.orangeAccent, size: 50,)),
                                      IconButton(onPressed: () async {
                                        setState(() {
                                          star1 = true;
                                          star2 = true;
                                          star3 = true;
                                          star4 = !star4;
                                          star5 = false;
                                        });

                                        try {
                                          await FirebaseFirestore.instance.collection("users").doc(getCurrentProduct.userId).update({
                                            'points': userPoints+4,
                                          });
                                        } catch (e) {

                                        }
                                        try {
                                          await FirebaseFirestore.instance.collection("products").doc(getCurrentProduct.productId).update({
                                            'userPoints': userPoints+4,
                                          });

                                        } catch (e) {

                                        }
                                        star1
                                            ? calificado = true
                                            : calificado = false;
                                        saveCalificado();

                                        /// Email de calificacion hacia vendedor ///
                                        sendEmail(
                                            name: getCurrentProduct.displayName,
                                            email: getCurrentProduct.userEmail,
                                            subject: '¡Te han calificado!',
                                            message: '${user!.displayName} acaba de calificarte por la compra de ${getCurrentProduct.productTitle}');
                                        /// /// /// /// /// ///
                                        /// Email de calificacion hacia comprador ///
                                        sendEmail(
                                            name: '${user.displayName}',
                                            email: '${user.email}',
                                            subject: '¡Tu calificación ha sido recibida!',
                                            message: 'Acabas de calificar a ${getCurrentProduct.displayName} por la compra de ${getCurrentProduct.productTitle}');
                                        /// /// /// /// /// ///

                                      }, icon: Icon(star4 ? Icons.star_rate_rounded: Icons.star_border_rounded, color: Colors.orangeAccent, size: 50,)),
                                      IconButton(onPressed: () async {
                                        setState(() {
                                          star1 = true;
                                          star2 = true;
                                          star3 = true;
                                          star4 = true;
                                          star5 = !star5;
                                        });

                                        try {
                                          await FirebaseFirestore.instance.collection("users").doc(getCurrentProduct.userId).update({
                                            'points': userPoints+5,
                                          });
                                        } catch (e) {

                                        }
                                        try {
                                          await FirebaseFirestore.instance.collection("products").doc(getCurrentProduct.productId).update({
                                            'userPoints': userPoints+5,
                                          });

                                        } catch (e) {

                                        }
                                        star1
                                            ? calificado = true
                                            : calificado = false;
                                        saveCalificado();

                                        /// Email de calificacion hacia vendedor ///
                                        sendEmail(
                                            name: getCurrentProduct.displayName,
                                            email: getCurrentProduct.userEmail,
                                            subject: '¡Te han calificado!',
                                            message: '${user!.displayName} acaba de calificarte por la compra de ${getCurrentProduct.productTitle}');
                                        /// /// /// /// /// ///
                                        /// Email de calificacion hacia comprador ///
                                        sendEmail(
                                            name: '${user.displayName}',
                                            email: '${user.email}',
                                            subject: '¡Tu calificación ha sido recibida!',
                                            message: 'Acabas de calificar a ${getCurrentProduct.displayName} por la compra de ${getCurrentProduct.productTitle}');
                                        /// /// /// /// /// ///

                                      }, icon: Icon(star5 ? Icons.star_rate_rounded: Icons.star_border_rounded, color: Colors.orangeAccent, size: 50,)),
                                    ],
                                  )
                                ],
                              ),]
                            )
                            else Stack(
                              children: [
                                SizedBox(
                          height: 400,
                                child: Swiper(
                                  curve: Curves.ease,
                                  itemBuilder: (BuildContext context,int index){
                                    return FancyShimmerImage(
                                        boxFit: BoxFit.contain,
                                        imageUrl: productImages[index]);
                                  },
                                  itemCount: productImages.length,
                                  pagination: const SwiperPagination(
                                      builder: SwiperPagination.dots
                                  ),
                                  control: const SwiperControl(
                                    color: Colors.deepPurpleAccent,
                                  ),
                                ),
                              ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                        alignment: const Alignment(0, 0),
                                        height: 30,
                                        width: 100,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(50),
                                          color: Colors.grey.shade100,
                                        ),
                                        child: Text(
                                          getCurrentProduct.productState,
                                          style: const TextStyle(
                                              color: Colors.black54,
                                              overflow: TextOverflow.ellipsis),
                                        )),
                                  ],
                                ),
                                // Row(
                                //   mainAxisAlignment: MainAxisAlignment.end,
                                //   children: [
                                //     Container(
                                //         height: 35,
                                //         decoration: const BoxDecoration(
                                //           color: Colors.white,
                                //           shape: BoxShape.circle,
                                //         ),
                                //         child: IconButton(
                                //             onPressed: () async {
                                //               await shareToWhatsApp(
                                //                   '¡No te pierdas esta oferta de *${getCurrentProduct.productTitle}* a *\$${getCurrentProduct.productPrice}*, Solo en *Rimio*, ¡Descarga la App YA!',
                                //                   getCurrentProduct.productImage1);
                                //             },
                                //             icon: const Icon(Icons.share))),
                                //   ],
                                // ),
      ],
                            ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(getCurrentProduct.productTitle, style: const TextStyle(fontSize: 25),),
                                  const Text('Publicado por: ', style: TextStyle(fontSize: 12, color: Colors.grey),),
                                  const SizedBox(height: 10,),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () async {

                                          var userMap = {};

                                          /// FETCHING DE DATOS DEL USUARIO
                                          try {
                                            final userDoc = await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(getCurrentProduct.userId)
                                                .get();
                                            userMap = userDoc.data()!;
                                            final userDocDict =
                                            userDoc.data() as Map<String, dynamic>?;

                                            userModel = UserModel(
                                              userId: userDoc.get('userId'),
                                              userName: userDoc.get('userName'),
                                              userLastName: userDoc.get('userLastName'),
                                              displayName: userDoc.get('displayName'),
                                              phone: userDoc.get('phone'),
                                              location: userDoc.get('location'),
                                              userImage: userDoc.get('userImage'),
                                              userEmail: userDoc.get('userEmail'),
                                              createdAt: userDoc.get('createdAt'),
                                              points: userDoc.get('points'),
                                              userWish: userDocDict!.containsKey("userWish")
                                                  ? userDoc.get("userWish")
                                                  : [],
                                              userVenta: userDocDict!.containsKey("userVenta")
                                                  ? userDoc.get("userVenta")
                                                  : [],
                                              userPublish: userDocDict!.containsKey("userPublish")
                                                  ? userDoc.get("userPublish")
                                                  : [],
                                            );
                                          } on FirebaseException catch (e) {
                                            rethrow;
                                          } catch (e) {
                                            rethrow;
                                          }

                                          /// /// /// /// /// /// /// ///

                                          showModalBottomSheet(context: context, builder: (context){

                                            final date = userModel!.createdAt.toDate().year;
                                            final publishProvider = Provider.of<PublishProvider>(context);

                                            return Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: SizedBox(
                                                width: MediaQuery.of(context).size.width,
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Padding(
                                                            padding: const EdgeInsets.all(8.0),
                                                            child: CircleAvatar(
                                                              radius: 50,
                                                              backgroundImage: NetworkImage(userModel!.userImage),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 20,),
                                                          Padding(
                                                            padding: const EdgeInsets.all(8.0),
                                                            child: Column(
                                                              children: [
                                                                Text(userModel!.displayName, style: const TextStyle(fontSize: 25),),
                                                                const SizedBox(height: 15,),
                                                                if (userModel!.points < 10)
                                                                  Image.asset(
                                                                      height: 30, 'assets/bronze.png'),
                                                                if (userModel!.points >= 10 && userModel!.points < 30)
                                                                  Image.asset(
                                                                      height: 30, 'assets/silver.png'),
                                                                if (userModel!.points >= 30 && userModel!.points < 100)
                                                                  Image.asset(height: 30, 'assets/gold.png'),
                                                                if (userModel!.points >= 1000)
                                                                  Image.asset(height: 30, 'assets/medal.png'),
                                                                const SizedBox(width: 20)
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const Divider(),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.person, color: Colors.deepPurple,),
                                                          Padding(
                                                            padding: const EdgeInsets.all(8.0),
                                                            child: Text('${userModel!.userName} ${userModel!.userLastName}', style: const TextStyle(fontSize: 17),),
                                                          ),
                                                        ],
                                                      ),
                                                      const Divider(),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.location_pin, color: Colors.deepPurple,),
                                                          Padding(
                                                            padding: const EdgeInsets.all(8.0),
                                                            child: Text(userModel!.location, style: const TextStyle(fontSize: 17),),
                                                          ),
                                                        ],
                                                      ),
                                                      const Divider(),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.perm_contact_calendar_rounded, color: Colors.deepPurple,),
                                                          Padding(
                                                            padding: const EdgeInsets.all(8.0),
                                                            child: Text('Miembro desde: $date', style: const TextStyle(fontSize: 17),),
                                                          ),
                                                        ],
                                                      ),
                                                      const Divider(),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.music_note_rounded, color: Colors.deepPurple,),
                                                          Padding(
                                                            padding: const EdgeInsets.all(8.0),
                                                            child: Text('Artículos publicados: ${userModel!.userPublish!.length}', style: const TextStyle(fontSize: 17),),
                                                          ),
                                                        ],
                                                      ),
                                                      const Divider(),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.monetization_on_rounded, color: Colors.deepPurple,),
                                                          Padding(
                                                            padding: const EdgeInsets.all(8.0),
                                                            child: Text('Ventas: ${userModel!.userVenta!.length}', style: const TextStyle(fontSize: 17),),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                              enableDrag: true,
                                              showDragHandle: true,
                                              backgroundColor: Colors.white);
                                        },
                                        child: CircleAvatar(
                                          radius: 15,
                                          backgroundImage: NetworkImage(
                                              getCurrentProduct.userImage),
                                        ),
                                      ),
                                      const SizedBox(width: 10,),
                                      Text(getCurrentProduct.displayName, style: const TextStyle(fontSize: 15),),
                                      const SizedBox(width: 10),

                                      if(userPoints < 10)
                                        Image.asset(height: 20,'assets/bronze.png'),
                                      if(userPoints >= 10 && userPoints<30)
                                        Image.asset(height: 20,'assets/silver.png'),
                                      if(userPoints >= 30 && userPoints<100)
                                        Image.asset(height: 20,'assets/gold.png'),
                                      if(userPoints >= 1000)
                                        Image.asset(height: 20,'assets/medal.png'),

                                      const SizedBox(width: 20),
                                      Flexible(child: Text(timeago.format(date, locale: 'es'), style: const TextStyle(color: Colors.grey, overflow: TextOverflow.ellipsis),)),
                                    ],
                                  ),
                                ],
                              ),
                              ),
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_pin, color: Colors.deepPurple,),
                                      Text(getCurrentProduct.userLocation, style: const TextStyle(fontSize: 18),),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: getCurrentProduct.servicio
                                        ? Text('\$${getCurrentProduct.productPrice}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 25),)
                                        : Text('\$${getCurrentProduct.productPrice}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 30),),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        /*GestureDetector(
                          onTap: () async {

                          },
                          child: Container(
                            height: 50,
                            width: 50,
                            color: Colors.deepPurple,
                          ),
                        ),*/
                        if(getCurrentProduct.vendido == true) ... [
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SizedBox(
                                        height: 60,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              elevation: 3,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12)
                                              ),
                                              foregroundColor: Colors.white,
                                              backgroundColor: Colors.red
                                          ),
                                          onPressed: () {},
                                          child: const Text('Vendido', style: TextStyle(fontSize: 25),
                                          ),
                                        )
                                    )
                                ),
                              ),
                            ],
                          )
                        ] else ... [
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Visibility(
                                    visible: getCurrentProduct.vendido == true ? false:true,
                                    child: FavButton(
                                      productId: getCurrentProduct.productId,
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(height: 20,)
                                ],
                              ),
                            ),
                            (user!=null && getCurrentProduct.userId == userId!.uid)
                            ? Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  height: 60,
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          elevation: 3,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12)
                                          ),
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.grey.shade300
                                      ),
                                      onPressed: () {},
                                      child: const Text('Publicado por ti', style: TextStyle(fontSize: 25),
                                  ),
                                )
                              )
                            ),
                            )
                            : Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  height: 60,
                                  child: (orderProvider.getUserOrders
                                      .containsKey(productId) && int.parse(getCurrentProduct.productQty) < 1)
                                      ? Row(
                                    children: [
                                      Expanded(
                                        child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: SizedBox(
                                                height: 60,
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    elevation: 3,
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                        BorderRadius.circular(12)),
                                                    foregroundColor: Colors.white,
                                                    backgroundColor: Colors.red,
                                                  ),
                                                  onPressed: () {},
                                                  child: const Text(
                                                    'Vendido',
                                                    style: TextStyle(fontSize: 25),
                                                  ),
                                                ))),
                                      ),
                                    ],
                                  )
                                      : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(
                                                12)),
                                        foregroundColor: Colors.white,
                                        backgroundColor:
                                        Colors.deepPurple),
                                    child: Shimmer.fromColors(
                                        baseColor: Colors.white,
                                        highlightColor: Colors.white10,
                                        child: const Text(
                                          'Comprar',
                                          style:
                                          TextStyle(fontSize: 25),
                                        )),
                                    onPressed: () async {

                                      try {
                                        final userDoc = await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(user!.uid)
                                            .get();

                                        final userDocDict = userDoc.data();

                                        String status = userDoc.data()!['profile_status'];

                                        if (status == "pending") {
                                          String message =
                                              'Tu perfil no está verificado, por favor contacta al administrador.';
                                          showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                    content: Container(
                                                        height: 80,
                                                        width: 100,
                                                        child: Center(
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                            children: [
                                                              Text(message),
                                                              const SizedBox(height: 5),
                                                              InkWell(
                                                                onTap: () {
                                                                  Navigator.pop(context);
                                                                },
                                                                child: const Text(
                                                                  "Entendido",
                                                                  style: TextStyle(color: Colors.deepPurple),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        )));
                                              });
                                          return;
                                        }
                                      } catch (e) {

                                      }

                                      /// FETCHING DE DATOS DEL USUARIO
                                      try{
                                        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();

                                        final userDocDict = userDoc.data() as Map<String, dynamic>?;

                                        userModel = UserModel(
                                          userId: userDoc.get('userId'),
                                          userName: userDoc.get('userName'),
                                          userLastName: userDoc.get('userLastName'),
                                          displayName: userDoc.get('displayName'),
                                          phone: userDoc.get('phone'),
                                          location: userDoc.get('location'),
                                          userImage: userDoc.get('userImage'),
                                          userEmail: userDoc.get('userEmail'),
                                          createdAt: userDoc.get('createdAt'),
                                          points: userDoc.get('points'),
                                          userWish: userDocDict!.containsKey("userWish") ? userDoc.get("userWish") : [],);
                                      } on FirebaseException catch(e){
                                        rethrow;
                                      }catch(e){
                                        rethrow;
                                      }
                                      /// /// /// /// /// /// /// ///


                                      showDialog(context: context, builder: (context){
                                        return AlertDialog(
                                            content: Container(
                                                height: 80, width: 100,
                                                child: Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                    children: [
                                                      user == null
                                                          ?const Text('Debes iniciar sesión')
                                                          :const Text('Estamos preparando su compra...'),
                                                      const SizedBox(height: 5,),
                                                      const CircularProgressIndicator(color: Colors.deepPurple,),
                                                    ],
                                                  ),)));
                                      });


                                      Future.delayed(const Duration(seconds: 3), () async {
                                        Navigator.pop(context);

                                        user == null
                                            ? Navigator.push(
                                            context, MaterialPageRoute(builder: (context) {
                                          return const Login();
                                        }))
                                            : await showModalBottomSheet(
                                            enableDrag: false,
                                            context: context, builder: (context) {
                                          return SingleChildScrollView(
                                            child: Container(
                                              width: MediaQuery
                                                  .of(context)
                                                  .size
                                                  .width,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(15),
                                              ),
                                              child: Column(
                                                //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  const SizedBox(height: 20,),
                                                  const Text('Confirmación de compra',
                                                    style: TextStyle(fontSize: 25,
                                                        color: Colors.deepPurple),),
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                        top: 8.0, left: 8, right: 8),
                                                    child: Text(
                                                      'Luego de confirmar tu compra, contactarás al vendedor para acordar el pago y entrega del artículo.',),
                                                  ),
                                                  const Icon(
                                                    Icons.warning_amber_rounded, size: 50,
                                                    color: Colors.redAccent,),
                                                  const Padding(
                                                    padding: EdgeInsets.only(top: 5.0),
                                                    child: Text('Consejos de seguridad',
                                                      style: TextStyle(fontSize: 20,
                                                          color: Colors.deepPurple),),
                                                  ),
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                        left: 8, right: 8),
                                                    child: Text(
                                                        'Rimio nunca te pedirá contraseñas, PIN o códigos de verificación a través de Whatsapp, teléfono, SMS o Email.\n'
                                                            '\nNunca compartas tus datos ni contraseña con terceros.\n\n'
                                                            'Acuerda la entrega en sitios seguros.'),
                                                  ),
                                                  const SizedBox(height: 15,),
                                                  const Divider(),
                                                  Padding(
                                                      padding: const EdgeInsets.all(12.0),
                                                      child: ListTile(
                                                        title: Text(getCurrentProduct.productTitle),
                                                        trailing: Column(
                                                          children: [
                                                            const Text('Total a pagar:', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),),
                                                            Text('\$${getCurrentProduct.productPrice}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),),
                                                          ],
                                                        ),
                                                      )
                                                  ),
                                                  ActionSlider.standard(
                                                    icon: const Icon(Icons.credit_card,
                                                      color: Colors.white,),
                                                    loadingIcon: const CircularProgressIndicator(
                                                      color: Colors.white,),
                                                    successIcon: const Icon(
                                                      Icons.check, color: Colors.white,),
                                                    rolling: true,
                                                    child: const Text('Desliza para comprar',
                                                      style: TextStyle(fontSize: 20),),
                                                    action: (controller) async {
                                                      controller
                                                          .loading(); //starts loading animation
                                                      await Future.delayed(
                                                          const Duration(seconds: 3));
                                                      controller
                                                          .success();

                                                      try {
                                                        await orderProvider.addToUserOrdersListFirebase(
                                                          productId: getCurrentProduct.productId,
                                                          context: context,
                                                        );
                                                        await orderProvider.fetchUserOrderslist();
                                                      } catch (e) {

                                                      } finally {

                                                      }
                                                      try {
                                                        final User? user = auth.currentUser;
                                                        final uid = user!.uid;
                                                        final orderId = const Uuid().v4();
                                                        final productId = getCurrentProduct
                                                            .productId;
                                                        await FirebaseFirestore.instance
                                                            .collection("orders")
                                                            .doc('${getCurrentProduct.productTitle} ID:$orderId')
                                                            .set({
                                                          'orderId': orderId,
                                                          'userId': uid,
                                                          'productId': productId,
                                                          'productName': getCurrentProduct
                                                              .productTitle,
                                                          'productImage': getCurrentProduct
                                                              .productImage1,
                                                          'productPrice': getCurrentProduct
                                                              .productPrice,
                                                          'orderTime': Timestamp.now(),
                                                        });

                                                        try {
                                                          await FirebaseFirestore.instance.collection("products").doc('${getCurrentProduct.productTitle} ID:${getCurrentProduct.productId}').update({
                                                            'vendido': true,
                                                          });
                                                        } catch (e) {}

                                                        if(user.uid != getCurrentProduct.userId){
                                                          try {
                                                            await ventaProvider.addToUserVentaListFirebase(
                                                              productId: getCurrentProduct.productId,
                                                              context: context,
                                                              userId: getCurrentProduct.userId,
                                                              displayName: user.displayName,
                                                              userEmail: user.email,
                                                              ventaTime: Timestamp.now(),
                                                            );
                                                            await ventaProvider.fetchUserVentalist();
                                                          } catch (e) {

                                                          } finally {

                                                          }
                                                        }

                                                        /// Email de venta ///
                                                        sendEmail(
                                                            name: getCurrentProduct.displayName,
                                                            email: getCurrentProduct.userEmail,
                                                            subject: '¡Has Vendido!',
                                                            message: '${user!.displayName} acaba de ofertar por ${getCurrentProduct.productTitle},'
                                                                ' contáctalo al ${userModel!.phone} para acordar pago y entrega del artículo.');
                                                        /// /// /// /// /// ///
                                                        /// Email de compra ///
                                                        sendEmail(
                                                            name: '${user.displayName}',
                                                            email: '${user.email}',
                                                            subject: 'Confirmación de compra en Rimio de ${getCurrentProduct.productTitle}',
                                                            message: 'Acabas de ofertar por ${getCurrentProduct.productTitle},'
                                                                ' ID de orden: $orderId\n'
                                                                ' contacta a ${getCurrentProduct.displayName} al ${userModel!.phone} para acordar pago y entrega del artículo.');
                                                        /// /// /// /// /// ///

                                                        ScaffoldMessenger.of(context)
                                                            .showSnackBar(
                                                            const SnackBar(
                                                              duration: Duration(seconds: 3),
                                                              elevation: 10,
                                                              content: Center(
                                                                child: Text(
                                                                  '¡Compra realizada con éxito!',
                                                                  style: TextStyle(
                                                                      color: Colors.white,
                                                                      fontWeight: FontWeight
                                                                          .bold,
                                                                      fontSize: 15),),
                                                              ),
                                                              backgroundColor: Colors
                                                                  .deepPurple,));
                                                      } catch (e) {
                                                        print(e);
                                                      } finally {

                                                      }
                                                      print('comprar');
                                                      await Future.delayed(
                                                          const Duration(seconds: 1));

                                                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context){return const RootScreen();}), (route) => false);

                                                      await showDialog(context: context, builder: (context){
                                                        return AlertDialog(

                                                          contentPadding: const EdgeInsets.all(8),
                                                          content: SizedBox(
                                                            height: 300,
                                                            width: 300,
                                                            child: Column(
                                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                              children: [
                                                                const Text('Contacta a:', style: TextStyle(fontSize: 20),),
                                                                const SizedBox(width: 20,),
                                                                CircleAvatar(
                                                                  radius: 20,
                                                                  backgroundImage: NetworkImage(getCurrentProduct.userImage),
                                                                ),
                                                                Flexible(child: Text(getCurrentProduct.userEmail, style: const TextStyle(fontSize: 20), overflow: TextOverflow.ellipsis,)),
                                                                const SizedBox(width: 20,),
                                                                Row(
                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                  children: [
                                                                    ElevatedButton.icon(
                                                                      onPressed: () async {
                                                                        canLaunchUrl(phoneNumber);
                                                                        if (!await launchUrl(phoneNumber)) {
                                                                          throw Exception('Could not launch $phoneNumber');
                                                                        }
                                                                      },
                                                                      style: ElevatedButton.styleFrom(
                                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                                          backgroundColor: Colors.deepPurple,
                                                                          foregroundColor: Colors.white),
                                                                      icon: const Icon(Icons.call),
                                                                      label: const Text('Llamar'),
                                                                    ),
                                                                    const SizedBox(width: 10,),
                                                                    ElevatedButton(
                                                                      onPressed: () async {
                                                                        launchUrl(whatsappNumber);
                                                                      },
                                                                      style: ElevatedButton.styleFrom(
                                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                                          backgroundColor: Colors.green,
                                                                          foregroundColor: Colors.white),
                                                                      child: Row(
                                                                        children: [
                                                                          Image.asset(height: 30,'assets/social.png'),
                                                                          const SizedBox(width: 8,),
                                                                          const Text('WhatsApp'),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                const Padding(
                                                                  padding: EdgeInsets.all(8.0),
                                                                  child: Text('Te hemos enviado un correo con la información de contacto.'),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      });
                                                    },
                                                  ),
                                                  const SizedBox(height: 20,),
                                                ],
                                              ),
                                            ),
                                          );
                                        });
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Visibility(
                                  visible: int.parse(getCurrentProduct.productQty) > 1 ? true:false,
                                  child: Text('¡${getCurrentProduct.productQty} Unidades disponibles!'),
                                ),
                              ),
                            ],
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Descripción', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),),
                              Column(
                                children: [
                                  TextButton(
                                      onPressed: (){
                                    Navigator.pushNamed(context, SearchPage.routeName, arguments: getCurrentProduct.productCategory);
                                  }, child: Text(getCurrentProduct.productCategory))
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(getCurrentProduct.productDescription, style: const TextStyle(fontSize: 15),)),
                        ),
                        const SizedBox(height: 10,),
                          const SizedBox(height: 10,),
                          if(user==null) ... [
                            Column(
                              children: [
                                const Divider(),
                                const Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Row(
                                    children: [
                                      Text('Preguntas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 350,
                                  child: TextFormField(
                                    textCapitalization: TextCapitalization.sentences,
                                    controller: _preguntaController,
                                    maxLines: 5,
                                    maxLength: 150,
                                    obscureText: false,
                                    keyboardType: TextInputType.multiline,
                                    decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.all(20),
                                        hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                                        hintText: 'Escribe tu pregunta...',
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12)
                                        )
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: SizedBox(
                                    width: 500,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)
                                        ),
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.deepPurple,
                                      ),
                                      onPressed: () async {
                                        if (user != null) {
                                          try {
                                            await preguntaProvider.addPreguntaToFirebase(
                                              pregunta: _preguntaController.text,
                                              productId: productId,
                                              context: context,
                                              productTitle: getCurrentProduct.productTitle,
                                              displayName: getCurrentProduct.displayName,
                                              userImage: getCurrentProduct.userImage,
                                              emisorEmail: user.email,
                                            );
                                          } catch (e) {

                                          } finally {
                                            _preguntaController.clear();
                                          }
                                        } else {Navigator.push(context, MaterialPageRoute(builder: (context){
                                          return const Login();
                                        }));}
                                      },
                                      child: const Text('Preguntar', style: TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Visibility(
                              visible: getCurrentProduct.userId != user.uid ? true:false,
                              child: Column(
                                children: [
                                  const Divider(),
                                  const Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: Row(
                                      children: [
                                        Text('Preguntas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 350,
                                    child: TextFormField(
                                      textCapitalization: TextCapitalization.sentences,
                                      controller: _preguntaController,
                                      maxLines: 5,
                                      maxLength: 150,
                                      obscureText: false,
                                      keyboardType: TextInputType.multiline,
                                      decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.all(20),
                                          hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                                          hintText: 'Escribe tu pregunta...',
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12)
                                          )
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: SizedBox(
                                      width: 500,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          elevation: 3,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12)
                                          ),
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.deepPurple,
                                        ),
                                        onPressed: () async {
                                          if (user != null) {

                                            if (_preguntaController.text.isEmpty) {
                                              showDialog(context: context, builder: (context){
                                                return const AlertDialog(
                                                  content: Text('El campo se encuentra vacío, escriba su pregunta',  style: TextStyle(fontSize: 18),),
                                                );
                                              });
                                            } else {

                                            try {
                                              await preguntaProvider.addPreguntaToFirebase(
                                                pregunta: _preguntaController.text,
                                                productId: productId,
                                                context: context,
                                                productTitle: getCurrentProduct.productTitle,
                                                displayName: getCurrentProduct.displayName,
                                                userImage: user.photoURL,
                                                emisorEmail: user.email,
                                              );

                                              /// Email de pregunta ///
                                              sendEmail(
                                                  name: getCurrentProduct.displayName,
                                                  email: getCurrentProduct.userEmail,
                                                  subject: '¡${user.displayName} te ha preguntado por ${getCurrentProduct.productTitle}!',
                                                  message: _preguntaController.text);

                                              /// /// /// /// /// ///
                                              /// Email de confirmacion de envio ///
                                              sendEmail(
                                                name: '${user.displayName}',
                                                email: '${user.email}',
                                                subject: '¡Tu pregunta ha sido enviada con éxito!',
                                                message: 'Tu pregunta ha sido enviada con éxito a ${getCurrentProduct.displayName} de ${getCurrentProduct.productTitle}'
                                                    '\n\nTu pregunta: ${_preguntaController.text}',);
                                              /// /// /// /// /// ///

                                            } catch (e) {

                                            } finally {
                                              _preguntaController.clear();
                                            }
                                          }} else {Navigator.push(context, MaterialPageRoute(builder: (context){
                                            return const Login();
                                          }));}
                                        },
                                        child: const Text('Preguntar', style: TextStyle(fontSize: 20),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]
                        ],
                        const SizedBox(height: 10,),
                        Visibility(
                          visible: user != null ? true : false,
                          child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('products')
                                  .doc(
                                  '${getCurrentProduct.productTitle} ID:${getCurrentProduct.productId}')
                                  .collection('preguntas')
                                  .orderBy('createAt', descending: true)
                                  .snapshots(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<QuerySnapshot> snapshot) {
                                return snapshot.hasData
                                    ? SizedBox(
                                  height: 200,
                                  width: 550,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: snapshot.data!.docs
                                          .map((DocumentSnapshot document) {
                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Stack(children: [
                                            Center(child: Column(
                                              children: [
                                                Stack(
                                                  children: [
                                                    Container(
                                                        padding:
                                                        const EdgeInsets.all(12),
                                                        width: 350,
                                                        decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                            BorderRadius.circular(
                                                                12),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                  blurRadius: 5,
                                                                  color: Colors
                                                                      .grey.shade300)
                                                            ]),
                                                        child: Column(
                                                          children: [
                                                            Row(
                                                              children: [
                                                                CircleAvatar(
                                                                  radius: 20,
                                                                  backgroundImage:
                                                                  NetworkImage(
                                                                      document[
                                                                      'imagen']),
                                                                ),
                                                                const SizedBox(
                                                                  width: 15,
                                                                ),
                                                                Text(
                                                                    document['emisor']),
                                                                const SizedBox(width: 20,),
                                                              ],
                                                            ),
                                                            Padding(
                                                              padding:
                                                              const EdgeInsets.all(
                                                                  8.0),
                                                              child: Row(
                                                                children: [
                                                                  SizedBox(
                                                                      width: 300,
                                                                      child: Text(
                                                                        document[
                                                                        'pregunta'],
                                                                        style:
                                                                        const TextStyle(
                                                                          color: Colors
                                                                              .black87,
                                                                        ),
                                                                      )),
                                                                ],
                                                              ),
                                                            ),
                                                            Divider(thickness: 0.5, color: Colors.grey.shade300,),
                                                            StreamBuilder<QuerySnapshot>(
                                                                stream: FirebaseFirestore.instance
                                                                    .collection('products')
                                                                    .doc(
                                                                    '${getCurrentProduct.productTitle} ID:${getCurrentProduct.productId}')
                                                                    .collection('preguntas')
                                                                    .orderBy('createAt', descending: true)
                                                                    .snapshots(),
                                                                builder: (BuildContext context,
                                                                    AsyncSnapshot<QuerySnapshot> snapshot) {
                                                                  return snapshot.hasData
                                                                      ? SizedBox(
                                                                    //height: 60,
                                                                    width: 550,
                                                                    child: Column(
                                                                      children: snapshot.data!.docs
                                                                          .map((DocumentSnapshot document) {
                                                                        return Row(
                                                                          mainAxisAlignment: MainAxisAlignment.end,
                                                                          children: [
                                                                            SizedBox(
                                                                              width: 300,
                                                                              child: Text(
                                                                                document[
                                                                                'respuesta'],
                                                                                style:
                                                                                const TextStyle(
                                                                                  color: Colors
                                                                                      .black87,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        );
                                                                      }).toList(),
                                                                    ),
                                                                  )
                                                                      : const CircularProgressIndicator();
                                                                }),
                                                          ],
                                                        )),
                                                    if (getCurrentProduct.userId ==
                                                        user!.uid) ...[
                                                      Positioned(
                                                          right: 0,
                                                          top: 0,
                                                          child: FloatingActionButton(
                                                            onPressed: () async {
                                                              await showDialog(context: context, builder: (context){
                                                                return AlertDialog(
                                                                  content: SizedBox(
                                                                    height: 240,
                                                                    child: Column(
                                                                      children: [
                                                                        SizedBox(
                                                                          width: 350,
                                                                          child: TextFormField(
                                                                            textCapitalization: TextCapitalization.sentences,
                                                                            controller: _respuestaController,
                                                                            maxLines: 5,
                                                                            maxLength: 150,
                                                                            obscureText: false,
                                                                            keyboardType: TextInputType.multiline,
                                                                            decoration: InputDecoration(
                                                                                contentPadding: const EdgeInsets.all(20),
                                                                                hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                                                                                hintText: 'Escribe tu respuesta...',
                                                                                filled: true,
                                                                                fillColor: Colors.white,
                                                                                border: OutlineInputBorder(
                                                                                    borderRadius: BorderRadius.circular(12)
                                                                                )
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(height: 5,),
                                                                        ElevatedButton(
                                                                          style: ElevatedButton.styleFrom(
                                                                            elevation: 3,
                                                                            shape: RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.circular(12)
                                                                            ),
                                                                            foregroundColor: Colors.white,
                                                                            backgroundColor: Colors.deepPurple,
                                                                          ),
                                                                          onPressed: () async {

                                                                            if (_respuestaController.text.isEmpty) {
                                                                              showDialog(context: context, builder: (context){
                                                                                return const AlertDialog(
                                                                                  content: Text('El campo se encuentra vacío, escriba su respuesta', style: TextStyle(fontSize: 18),),
                                                                                );
                                                                              });
                                                                            } else {

                                                                              /// Email de respuesta ///
                                                                              sendEmail(
                                                                                  name: document['emisor'],
                                                                                  email: document['emisorEmail'],
                                                                                  subject: '¡${getCurrentProduct.displayName} te ha respondido por ${getCurrentProduct.productTitle}!',
                                                                                  message: _respuestaController.text);

                                                                              /// /// /// /// /// ///
                                                                              /// Email de confirmacion de envio ///
                                                                              sendEmail(
                                                                                name: '${getCurrentProduct.displayName}',
                                                                                email: '${getCurrentProduct.userEmail}',
                                                                                subject: '¡Tu respuesta ha sido enviada con éxito!',
                                                                                message: 'Tu respuesta ha sido enviada con éxito a ${document['emisor']} de ${getCurrentProduct.productTitle}'
                                                                                    '\n\nTu respuesta: ${_respuestaController.text}',);
                                                                              /// /// /// /// /// ///

                                                                              try {
                                                                                await preguntaProvider.addRespuestaToFirebase(
                                                                                  respuesta: _respuestaController.text,
                                                                                  productId: productId,
                                                                                  context: context,
                                                                                  productTitle: getCurrentProduct.productTitle,
                                                                                );
                                                                              } catch (e) {

                                                                              } finally {
                                                                                _respuestaController.clear();
                                                                              }
                                                                            }},
                                                                          child: const Text('Enviar respuesta', style: TextStyle(fontSize: 20),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                );
                                                              });
                                                            },
                                                            child: const Icon(
                                                              Icons.send_rounded,
                                                              size: 25,
                                                              color: Colors.deepPurple,
                                                            ),
                                                          )),
                                                    ] else ...[
                                                      const SizedBox.shrink()
                                                    ]
                                                  ],
                                                ),
                                              ],
                                            ),
                                            ),
                                          ]),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                )
                                    : const CircularProgressIndicator();
                              }),
                        ),
                      ],
                ),
              ),
            ),
          ),
    );
  }
}

