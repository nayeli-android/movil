import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart'; 
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  bool _isUploading = false;

  // Función para editar perfil (Nombre) en Supabase Auth Metadata
  void _showEditProfileDialog(BuildContext context, String currentName) {
    final nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Editar Perfil", style: TextStyle(color: Color(0xFFFF1493), fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: "Nombre completo",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF1493), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              try {
                // Actualizar metadatos del usuario en Supabase Auth
                await supabase.auth.updateUser(
                  UserAttributes(data: {'name': nameController.text.trim()}),
                );
                setState(() {}); // Refrescar vista
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Perfil actualizado en la nube"), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error al actualizar: $e"), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("Guardar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Función para cambiar contraseña con Supabase Auth
  void _showChangePasswordDialog(BuildContext context) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cambiar Contraseña", style: TextStyle(color: Color(0xFFFF1493), fontWeight: FontWeight.bold)),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: "Nueva contraseña",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF1493), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              try {
                await supabase.auth.updateUser(
                  UserAttributes(password: passwordController.text.trim()),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Contraseña actualizada con éxito"), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("Actualizar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = supabase.auth.currentUser;
    final userName = currentUser?.userMetadata?['name'] ?? 'Usuario K-Drama';
    final userEmail = currentUser?.email ?? 'correo@ejemplo.com';
    final userAvatarUrl = currentUser?.userMetadata?['avatar_url']; // URL de la foto si existe

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Mi Cuenta", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFFF1493))),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF1493), Color(0xFFFF69B4)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        backgroundImage: userAvatarUrl != null ? NetworkImage(userAvatarUrl) : null,
                        child: userAvatarUrl == null
                            ? Text(
                                userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                                style: const TextStyle(color: Color(0xFFFF1493), fontSize: 28, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          // Coloca esto dentro de la función o acción de la cámara en ProfileScreen:
                          onTap: () async {
                            try {
                              // 1. Abrir la galería para seleccionar una imagen
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 300, // Reducimos tamaño para que cargue rápido
                                maxHeight: 300,
                                imageQuality: 80,
                              );

                              if (image == null) return; // Si el usuario canceló, no hacemos nada

                              setState(() => _isUploading = true);

                              // 2. Preparar el archivo y la ruta única en Supabase Storage
                              final userId = supabase.auth.currentUser!.id;
                              final fileBytes = await image.readAsBytes();
                              // En lugar de usar split('.').pop(), usa esto para evitar el error:
                              final fileExt = image.path.split('.').last;
                              final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
                              final filePath = 'profiles/$fileName';

                              // 3. Subir el archivo al Bucket 'avatars'
                              await supabase.storage.from('avatars').uploadBinary(
                                filePath,
                                fileBytes,
                                fileOptions: FileOptions(upsert: true, contentType: 'image/$fileExt'),
                              );

                              // 4. Obtener la URL pública de la imagen recién subida
                              final imageUrl = supabase.storage.from('avatars').getPublicUrl(filePath);

                              // 5. Guardar la URL en los metadatos del usuario en Supabase Auth
                              await supabase.auth.updateUser(
                                UserAttributes(data: {'avatar_url': imageUrl}),
                              );

                              setState(() => _isUploading = false);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("¡Foto de perfil actualizada con éxito!"), backgroundColor: Colors.green),
                              );
                            } catch (e) {
                              setState(() => _isUploading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error al subir la imagen: $e"), backgroundColor: Colors.red),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, size: 16, color: Color(0xFFFF1493)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(userEmail, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text("Configuración de Cuenta", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            _buildProfileOption(
              icon: Icons.edit_outlined, 
              title: "Editar información personal", 
              subtitle: "Actualiza tu nombre en la nube", 
              onTap: () => _showEditProfileDialog(context, userName),
            ),
            _buildProfileOption(
              icon: Icons.lock_outline, 
              title: "Cambiar contraseña", 
              subtitle: "Modifica tu clave de acceso en Supabase", 
              onTap: () => _showChangePasswordDialog(context),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text("CERRAR SESIÓN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: () async {
                await supabase.auth.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFFF1493).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFFFF1493)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}