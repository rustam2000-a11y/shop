import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Инициализация Firebase

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartModel()), // Модель корзины
        ChangeNotifierProvider(create: (context) => OrderModel()), // Модель заказа
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthStateHandler(), // Начальная страница
    );
  }
}

// Проверка состояния аутентификации
class AuthStateHandler extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          // Если пользователь уже вошел в систему, перенаправляем на главную страницу
          return HomePage();
        } else {
          // Если пользователь не аутентифицирован, показываем экран входа
          return LoginPage();
        }
      },
    );
  }
}

// Страница входа
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late FirebaseAuth _auth;

  @override
  void initState() {
    _auth = FirebaseAuth.instance;
    super.initState();
  }

  Future<void> _login() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Перейти на главную страницу
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка входа: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Войти')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Пароль'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('Войти'),
            ),
            TextButton(
              onPressed: () {
                // Переход на страницу регистрации
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              child: Text('Зарегистрироваться'),
            ),
          ],
        ),
      ),
    );
  }
}

// Страница регистрации
class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _register() async {
    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пароли не совпадают')),
      );
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Перейти на главную страницу
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка регистрации: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Регистрация')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Пароль'),
              obscureText: true,
            ),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(labelText: 'Повторите пароль'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: Text('Зарегистрироваться'),
            ),
          ],
        ),
      ),
    );
  }
}

// Главная страница для авторизованных пользователей
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0; // Индекс текущей страницы
  final List<Widget> _pages = [MainTabPage(), CatalogPage(), CartPage(), AccountPage()]; // Список страниц

  // Метод для выхода из аккаунта
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Главная страница'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages, // Отображение текущей страницы
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.black, // Цвет текста для активного элемента
        unselectedItemColor: Colors.black45,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.black),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag, color: Colors.black),
            label: 'Каталог',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart, color: Colors.black),
            label: 'Корзина',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle, color: Colors.black),
            label: 'Аккаунт',
          ),
        ],
      ),
    );
  }
}

// Главная страница "Он" и "Она"
class MainTabPage extends StatefulWidget {
  @override
  _MainTabPageState createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black45,
          indicatorColor: Colors.black,
          tabs: [
            Tab(text: 'Он'),
            Tab(text: 'Она'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              OnPage(), // Страница "Он" с картинками
              ShePage(), // Страница "Она" с placeholder
            ],
          ),
        ),
      ],
    );
  }
}



class OnPage extends StatelessWidget {
  Future<List<Map<String, dynamic>>> _fetchMenThings() async {
    try {
      // Запрашиваем все мужские товары
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('things')
          .where('typ', isEqualTo: 'man')
          .get(); // Получаем все товары без лимита

      List<Map<String, dynamic>> things = [];
      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        // Получаем URL картинки из Firebase Storage по пути
        String imgUrl = '';
        try {
          imgUrl = await FirebaseStorage.instance
              .ref(data['img']) // Путь к изображению
              .getDownloadURL();
        } catch (e) {
          print("Error loading image: $e");
        }

        things.add({
          'name': data['name'],
          'price': data['price'],
          'imgUrl': imgUrl, // URL изображения или пустая строка, если ошибка
        });
      }
      return things;
    } catch (e) {
      print("Error fetching data: $e");
      return [];
    }
  }

  // Функция для показа BottomSheet
  void _showProductDetails(BuildContext context, Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Позволяет контролировать высоту листа
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9, // Высота 90% экрана
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Кнопка закрытия (крестик) с современным стилем
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 24,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Изображение товара с тенью и адаптируемой высотой
              Center(
                child: Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                    image: DecorationImage(
                      image: NetworkImage(product['imgUrl']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Название товара с более современным стилем
              Text(
                product['name'],
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),

              // Цена товара с элегантным стилем
              Text(
                '\$${product['price'].toString()}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 30),

              // Описание или информация о продукте (можно добавить описание товара)
              Text(
                "Этот товар – лучший выбор для вас! Качественный материал и стильный дизайн. Доступен в разных цветах.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              Spacer(),

              // Кнопка "Добавить в корзину" с плавным стилем
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Provider.of<CartModel>(context, listen: false).addItem(product);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("${product['name']} добавлен в корзину!"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(Icons.add_shopping_cart, color: Colors.white),
                  label: Text(
                    "Добавить в корзину",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrangeAccent, // Цвет кнопки
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20), // Отступ снизу
            ],
          ),
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchMenThings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator()); // Показываем загрузку
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No items found'));
        }

        // Список товаров
        List<Map<String, dynamic>> things = snapshot.data!;

        // Разделяем товары: первые 4 куртки для сетки, следующие 4 для горизонтальной строки, остальные для списка
        List<Map<String, dynamic>> jackets = things.take(4).toList(); // Первые 4 куртки
        List<Map<String, dynamic>> horizontalItems = things.skip(4).take(4).toList(); // Следующие 4 для горизонтального списка
        List<Map<String, dynamic>> otherThings = things.skip(8).toList(); // Остальные товары для вертикального списка

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Сетка из первых 4 курток
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.count(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: List.generate(jackets.length, (index) {
                    var item = jackets[index];

                    return GestureDetector(
                      onTap: () => _showProductDetails(context, item), // Показать BottomSheet
                      child: Container(
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16), // Закругленные углы
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ], // Тени для элементов
                          image: item['imgUrl'] != ''
                              ? DecorationImage(
                            image: NetworkImage(item['imgUrl']),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8), // Белый полупрозрачный фон
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, -3),
                                ),
                              ], // Мягкая тень наверху
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  item['name'],
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4), // Отступ между названием и ценой
                                Text(
                                  '\$${item['price'].toString()}',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              SizedBox(height: 20), // Отступ перед горизонтальной строкой
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  "Популярные",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),

              // Горизонтальная строка контейнеров для следующих 4 товаров
              SizedBox(
                height: 150, // Высота для горизонтального списка
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: horizontalItems.length,
                  itemBuilder: (context, index) {
                    var item = horizontalItems[index];
                    return GestureDetector(
                      onTap: () => _showProductDetails(context, item), // Показать BottomSheet
                      child: Container(
                        width: 150,
                        margin: EdgeInsets.symmetric(horizontal: 8), // Отступы между контейнерами
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16), // Закругленные углы
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                          image: item['imgUrl'] != ''
                              ? DecorationImage(
                            image: NetworkImage(item['imgUrl']),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  item['name'],
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '\$${item['price'].toString()}',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 20), // Отступ перед вертикальным списком

              // Вертикальный список для остальных товаров
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  physics: NeverScrollableScrollPhysics(), // Запрещаем внутреннюю прокрутку
                  shrinkWrap: true, // Встраиваем список в ScrollView
                  itemCount: otherThings.length,
                  itemBuilder: (context, index) {
                    var item = otherThings[index];
                    return GestureDetector(
                      onTap: () => _showProductDetails(context, item), // Показать BottomSheet
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16), // Закругленные углы
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ], // Тени для элементов
                          image: item['imgUrl'] != ''
                              ? DecorationImage(
                            image: NetworkImage(item['imgUrl']),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  item['name'],
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '\$${item['price'].toString()}',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}









// Страница "Она" (можете настроить её самостоятельно)
class ShePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Женские товары'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('things')
            .where('typ', isEqualTo: 'wom')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Товары не найдены'));
          }

          final products = snapshot.data!.docs;

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Количество столбцов в сетке
              crossAxisSpacing: 10.0, // Расстояние между столбцами
              mainAxisSpacing: 10.0,  // Расстояние между строками
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              var product = products[index].data() as Map<String, dynamic>;
              String imagePath = product['img']; // Пусть к изображению, например 'products/6623705.png'

              return FutureBuilder<String>(
                future: _getImageUrl(imagePath), // Загружаем URL изображения
                builder: (context, imgSnapshot) {
                  if (imgSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (imgSnapshot.hasError || !imgSnapshot.hasData) {
                    return Icon(Icons.image_not_supported); // Показать, если не удалось загрузить изображение
                  }

                  return Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Image.network(
                            imgSnapshot.data!, // Загруженный URL изображения
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            product['name'],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '\$${product['price']}',
                            style: TextStyle(fontSize: 14, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Метод для загрузки URL изображения из Firebase Storage
  Future<String> _getImageUrl(String imgPath) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(imgPath); // Создаем ссылку на файл
      String url = await ref.getDownloadURL(); // Получаем URL
      return url;
    } catch (e) {
      print('Ошибка загрузки изображения: $e');
      return ''; // Возвращаем пустую строку в случае ошибки
    }
  }
}

// Пример страницы Каталога
class CatalogPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Каталог'),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Кнопка для мужского каталога
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FilteredProductListPage(type: 'man'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Мужское',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            SizedBox(width: 20), // Отступ между кнопками

            // Кнопка для женского каталога
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FilteredProductListPage(type: 'wom'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                backgroundColor: Colors.pinkAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Женское',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// Пример страницы Корзины
class CartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context); // Получаем доступ к модели корзины

    return Scaffold(
      appBar: AppBar(
        title: Text('Корзина'),
      ),
      body: Column(
        children: [
          // Список товаров в корзине
          Expanded(
            child: cart.cartItems.isEmpty
                ? Center(
              child: Text('Корзина пуста'),
            )
                : ListView.builder(
              itemCount: cart.cartItems.length,
              itemBuilder: (context, index) {
                var item = cart.cartItems[index];
                return ListTile(
                  leading: Image.network(item['imgUrl']),
                  title: Text(item['name']),
                  subtitle: Text('\$${item['price']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      cart.removeItem(index); // Удаление товара
                    },
                  ),
                );
              },
            ),
          ),
          // Общая сумма внизу страницы
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Общая сумма:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${cart.totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Кнопка для перехода к оформлению заказа
                ElevatedButton(
                  onPressed: () {
                    // Переход на страницу оформления заказа (Design)
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Design()),
                    );
                  },
                  child: Text('Перейти к оформлению'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class Design extends StatefulWidget {
  @override
  _DesignState createState() => _DesignState();
}

class _DesignState extends State<Design> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _paymentMethod = 'Карта';

  void _placeOrder(double totalPrice) {
    final String name = _nameController.text;
    final String surname = _surnameController.text;
    final String city = _cityController.text;
    final String address = _addressController.text;

    if (name.isEmpty || surname.isEmpty || city.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Пожалуйста, заполните все поля'),
        ),
      );
    } else {
      // Сохраняем заказ в OrderModel через Provider
      Provider.of<OrderModel>(context, listen: false)
          .placeOrder(name, surname, totalPrice);

      // Переход на страницу аккаунта
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AccountPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context); // Получаем данные корзины

    return Scaffold(
      appBar: AppBar(
        title: Text('Оформление заказа'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Имя',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _surnameController,
              decoration: InputDecoration(
                labelText: 'Фамилия',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'Город',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Адрес',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Сумма заказа: \$${cart.totalPrice.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            ListTile(
              title: const Text('Карта'),
              leading: Radio<String>(
                value: 'Карта',
                groupValue: _paymentMethod,
                onChanged: (String? value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Наличные'),
              leading: Radio<String>(
                value: 'Наличные',
                groupValue: _paymentMethod,
                onChanged: (String? value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
              ),
            ),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () => _placeOrder(cart.totalPrice),
                child: Text('Оформить заказ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartModel extends ChangeNotifier {
  final List<Map<String, dynamic>> _cartItems = [];

  // Возвращаем список товаров в корзине
  List<Map<String, dynamic>> get cartItems => _cartItems;

  // Добавляем товар в корзину
  void addItem(Map<String, dynamic> item) {
    _cartItems.add(item);
    notifyListeners(); // Уведомляем о изменениях
  }

  // Удаляем товар из корзины
  void removeItem(int index) {
    _cartItems.removeAt(index);
    notifyListeners();
  }

  // Рассчитываем общую сумму товаров в корзине
  double get totalPrice {
    double total = 0.0;
    for (var item in _cartItems) {
      double price = item['price'] is String ? double.tryParse(item['price']) ?? 0.0 : item['price'];
      total += price;
    }
    return total;
  }
}
class FilteredProductListPage extends StatefulWidget {
  final String type;

  const FilteredProductListPage({Key? key, required this.type}) : super(key: key);

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<FilteredProductListPage> {
  String selectedCategory = '';

  List<String> getCategories() {
    if (widget.type == 'man') {
      return ['Куртка', 'Футболка', 'Кофта', 'Джинсы'];
    } else {
      return ['Кофта', 'Футболка'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type == 'man' ? 'Мужские товары' : 'Женские товары'),
      ),
      body: Column(
        children: [
          // Фильтры в виде кнопок
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: getCategories().map((category) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    child: Text(category),
                  ),
                );
              }).toList(),
            ),
          ),
          // Список товаров
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('things')
                  .where('typ', isEqualTo: widget.type)
              // Если выбран фильтр, добавляем условие
                  .where('name', whereIn: selectedCategory.isNotEmpty ? [selectedCategory] : null)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Товары не найдены'));
                }

                final products = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    var product = products[index].data() as Map<String, dynamic>;

                    return FutureBuilder<String>(
                      future: _getImageUrl(product['img']), // Загружаем URL изображения
                      builder: (context, imgSnapshot) {
                        if (imgSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (imgSnapshot.hasError || imgSnapshot.data == '') {
                          return ListTile(
                            leading: Icon(Icons.image_not_supported), // Иконка, если изображение не загрузилось
                            title: Text(product['name']),
                            subtitle: Text('\$${product['price']}'),
                          );
                        }

                        // Отображаем товар с изображением
                        return ListTile(
                          leading: Image.network(
                            imgSnapshot.data!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          title: Text(product['name']),
                          subtitle: Text('\$${product['price']}'),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _getImageUrl(String imgPath) async {
    try {
      // Получаем полный путь к изображению в Firebase Storage
      final ref = FirebaseStorage.instance.ref().child(imgPath);
      // Получаем URL для загрузки
      String url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      // Если ошибка, возвращаем пустую строку или иконку по умолчанию
      print('Ошибка загрузки изображения: $e');
      return '';
    }
  }
}
// Пример страницы Аккаунта
class AccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Получаем данные о заказе из OrderModel через Provider
    final orderModel = Provider.of<OrderModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Аккаунт'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ваш аккаунт',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            // Проверяем, есть ли данные о заказе
            if (orderModel.hasOrder) ...[
              Text('Имя: ${orderModel.name}', style: TextStyle(fontSize: 18)),
              Text('Фамилия: ${orderModel.surname}', style: TextStyle(fontSize: 18)),
              SizedBox(height: 16),
              Text(
                'Сумма последнего заказа: \$${orderModel.totalPrice!.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18, color: Colors.green),
              ),
            ] else ...[
              Text('Заказов пока нет', style: TextStyle(fontSize: 18, color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }
}
  class OrderModel extends ChangeNotifier {
    String? name;
    String? surname;
    double? totalPrice;

    // Метод для сохранения заказа
    void placeOrder(String name, String surname, double totalPrice) {
      this.name = name;
      this.surname = surname;
      this.totalPrice = totalPrice;
      notifyListeners();
    }

    // Проверка наличия заказа
    bool get hasOrder => name != null && surname != null && totalPrice != null;
  }




