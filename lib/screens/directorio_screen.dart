import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'perfil_screen.dart'; // Crearemos este archivo en el siguiente paso

class DirectorioScreen extends StatelessWidget {
  const DirectorioScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directorio del Personal'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay personal registrado aún.'));
          }

          final usuarios = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              var data = usuarios[index].data() as Map<String, dynamic>;
              String docId = usuarios[index].id;
              
              // Variables extraídas de Firestore
              String nombre = data['nombre'] ?? 'Sin Nombre';
              String apellido = data['apellido'] ?? '';
              String rol = data['rol'] ?? 'Operario';
              String fotoUrl = data['foto_url'] ?? '';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                    child: fotoUrl.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 30) : null,
                  ),
                  title: Text("$nombre $apellido".trim(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Rol: $rol'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navega al perfil detallado enviando los datos del usuario seleccionado
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PerfilScreen(usuarioId: docId, datosUsuario: data),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}