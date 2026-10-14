import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home_screen.dart';
import 'my_list_screen.dart';
import 'profile_screen.dart';
import 'admin/admin_dashboard.dart';
import '../models/kdrama_model.dart';
import '../models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  final supabase = Supabase.instance.client;

  // Limpiar campos de texto al cambiar de pantalla
  void _clearFields() {
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
  }

  // Traductor de errores técnicos a mensajes amigables
  String _getFriendlyError(String errorCode, String originalMessage) {
    if (originalMessage.contains('SocketException') || originalMessage.contains('Network') || originalMessage.contains('connection abort')) {
      return "Hubo un problema de conexión. Verifica tu internet e intenta de nuevo.";
    }
    if (originalMessage.contains('Invalid login credentials') || errorCode.contains('invalid_credentials')) {
      return "El correo o la contraseña son incorrectos.";
    }
    if (originalMessage.contains('Email not confirmed') || errorCode.contains('email_not_confirmed')) {
      return "Tu correo electrónico aún no ha sido confirmado.";
    }
    if (originalMessage.contains('rate limit') || errorCode.contains('over_email_send_rate_limit')) {
      return "Demasiados intentos seguidos. Espera un momento antes de volver a intentar.";
    }
    if (originalMessage.contains('Password should be') || originalMessage.contains('characters')) {
      return "La contraseña es muy corta. Debe tener al menos 6 caracteres.";
    }
    if (originalMessage.contains('User already registered') || errorCode.contains('user_already_exists')) {
      return "Este correo ya está registrado. Intenta iniciar sesión.";
    }
    return "Ocurrió un error inesperado. Por favor, verifica tus datos.";
  }

  void _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLogin && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, llena todos los campos"), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      if (_isLogin) {
        final AuthResponse res = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (res.user != null) {
          bool isAdmin = email == "admin@kdrama.com"; 

          if (isAdmin) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UserMainScreen()),
            );
          }
        }
      } else {
        final AuthResponse res = await supabase.auth.signUp(
          email: email,
          password: password,
          data: {'name': name},
        );

        if (res.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("¡Cuenta creada con éxito! Ya puedes iniciar sesión"), backgroundColor: Colors.green),
          );
          setState(() {
            _isLogin = true;
            _clearFields();
          });
        }
      }
    } catch (e) {
      final friendlyMessage = _getFriendlyError(e.toString(), e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyMessage), backgroundColor: Colors.red),
      );
    }
  }

  // Inicio de sesión con Google forzando la selección de cuentas
  Future<void> _signInWithGoogle() async {
    try {
      const webClientId = '72836483619-38pdhgt2nvum522bp6c3dok1kcn5l65b.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );
      
      await googleSignIn.signOut(); // Fuerza el selector de cuentas
      
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw 'No se pudo obtener el token de Google.';
      }

      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        bool isAdmin = response.user!.email == "admin@kdrama.com";
        if (isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UserMainScreen()),
          );
        }
      }
    } catch (e) {
      final friendlyMessage = _getFriendlyError(e.toString(), e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyMessage), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF1493), Color(0xFFFF69B4), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.movie_filter_rounded, size: 60, color: Color(0xFFFF1493)),
                    const SizedBox(height: 10),
                    Text(
                      _isLogin ? "¡Bienvenido a K-Dramas!" : "Crear Nueva Cuenta",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _isLogin ? "Inicia sesión en la nube" : "Regístrate para empezar a ver",
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 25),

                    if (!_isLogin) ...[
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: "Nombre completo",
                          prefixIcon: const Icon(Icons.person, color: Color(0xFFFF1493)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],

                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Correo electrónico",
                        prefixIcon: const Icon(Icons.email, color: Color(0xFFFF1493)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFFFF1493)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 25),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF1493),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _submit,
                      child: Text(
                        _isLogin ? "INICIAR SESIÓN" : "REGISTRARSE",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 15),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Colors.grey, width: 0.5),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.g_mobiledata, size: 32, color: Colors.red),
                      label: const Text("Continuar con Google", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: _signInWithGoogle,
                    ),
                    const SizedBox(height: 15),

                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _clearFields();
                        });
                      },
                      child: Text(
                        _isLogin ? "¿No tienes cuenta? Regístrate aquí" : "¿Ya tienes cuenta? Inicia sesión",
                        style: const TextStyle(color: Color(0xFFFF1493), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UserMainScreen extends StatefulWidget {
  const UserMainScreen({super.key});

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _currentIndex = 0;
  List<KdramaModel> _kdramas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchKdramasFromSupabase();
  }

  Future<void> _fetchKdramasFromSupabase() async {
    try {
      final response = await Supabase.instance.client.from('kdramas').select();
      
      final loadedKdramas = (response as List).map((map) {
        return KdramaModel(
          id: map['id'],
          titulo: map['titulo'],
          genero: map['genero'],
          descripcion: map['descripcion'],
          imagen: map['imagen'],
          isFav: map['isFav'] == 1 || map['isFav'] == true,
          rating: (map['rating'] ?? 4.5).toDouble(),
          episodios: [
            EpisodeModel(title: "Episodio 1", duration: "60 min", videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")
          ],
        );
      }).toList();

      setState(() {
        _kdramas = loadedKdramas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF1493))),
      );
    }

    final currentUser = UserModel(
      name: Supabase.instance.client.auth.currentUser?.userMetadata?['name'] ?? 'Usuario',
      email: Supabase.instance.client.auth.currentUser?.email ?? '',
      password: '',
      role: 'user',
    );

    final List<Widget> userScreens = [
      HomeScreen(user: currentUser, kdramas: _kdramas, onDataChanged: _fetchKdramasFromSupabase),
      MyListScreen(allKdramas: _kdramas, onListChanged: _fetchKdramasFromSupabase),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: userScreens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFFF1493),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Mi Lista"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }
}