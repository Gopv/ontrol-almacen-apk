import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PerfilScreen extends StatefulWidget {
  final String usuarioId;
  final Map<String, dynamic> datosUsuario;

  const PerfilScreen({Key? key, required this.usuarioId, required this.datosUsuario}) : super(key: key);

  @override
  _PerfilScreenState createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String? _fotoUrlActual;
  bool _subiendoImagen = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fotoUrlActual = widget.datosUsuario['foto_url'];
  }

  // --- LÓGICA PARA CAPTURAR Y SUBIR LA FOTO ---
  Future<void> capturarYSubirFoto() async {
    try {
      // 1. Abre la cámara del teléfono (preferiblemente la frontal)
      final XFile? imagenCapturada = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 70, // Comprime la imagen para no saturar la base de datos
      );

      if (imagenCapturada == null) return; // Si el usuario cancela, no hace nada

      setState(() => _subiendoImagen = true);

      // 2. Prepara el archivo y la ruta en Firebase Storage
      File archivoFisico = File(imagenCapturada.path);
      String nombreArchivo = 'fotos_perfil/${widget.usuarioId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference refStorage = FirebaseStorage.instance.ref().child(nombreArchivo);

      // 3. Sube la imagen a la nube
      UploadTask uploadTask = refStorage.putFile(archivoFisico);
      TaskSnapshot snapshot = await uploadTask;
      String urlDescarga = await snapshot.ref.getDownloadURL();

      // 4. Actualiza la base de datos (Firestore) con el nuevo enlace de la foto
      await FirebaseFirestore.instance.collection('usuarios').doc(widget.usuarioId).update({
        'foto_url': urlDescarga,
      });

      // 5. Refresca la pantalla
      setState(() {
        _fotoUrlActual = urlDescarga;
        _subiendoImagen = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto actualizada exitosamente')));

    } catch (e) {
      setState(() => _subiendoImagen = false);
      print("Error al subir imagen: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al subir la fotografía'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    String nombreCompleto = "${widget.datosUsuario['nombre'] ?? ''} ${widget.datosUsuario['apellido'] ?? ''}".trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Operario'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- SECCIÓN DE LA FOTOGRAFÍA ---
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _fotoUrlActual != null && _fotoUrlActual!.isNotEmpty
                      ? NetworkImage(_fotoUrlActual!)
                      : null,
                  child: _fotoUrlActual == null || _fotoUrlActual!.isEmpty
                      ? const Icon(Icons.person, size: 80, color: Colors.grey)
                      : null,
                ),
                if (_subiendoImagen)
                  const Positioned.fill(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.blue,
                    onPressed: _subiendoImagen ? null : capturarYSubirFoto,
                    child: const Icon(Icons.camera_alt, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- SECCIÓN DE LOS DATOS ---
            Text(nombreCompleto.isEmpty ? "Sin Nombre" : nombreCompleto, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(widget.datosUsuario['rol'] ?? 'Operario', style: const TextStyle(fontSize: 18, color: Colors.blueGrey)),
            const Divider(height: 40, thickness: 1),

            _construirFilaDatos(Icons.badge, "ID Empleado", widget.datosUsuario['id_empleado'] ?? 'No asignado'),
            _construirFilaDatos(Icons.email, "Correo", widget.datosUsuario['correo'] ?? 'No disponible'),
            _construirFilaDatos(Icons.location_on, "Zona Actual", widget.datosUsuario['zona'] ?? 'No asignada'),
            _construirFilaDatos(Icons.inventory_2, "Lote Asignado", widget.datosUsuario['lote'] ?? 'No asignado'),
            
            const SizedBox(height: 20),
            
            // Indicador visual de si el operario tiene permiso BPM
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: (widget.datosUsuario['bpmAprobado'] == true) ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(10)
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon((widget.datosUsuario['bpmAprobado'] == true) ? Icons.check_circle : Icons.warning, 
                       color: (widget.datosUsuario['bpmAprobado'] == true) ? Colors.green : Colors.red),
                  const SizedBox(width: 10),
                  Text((widget.datosUsuario['bpmAprobado'] == true) ? "Aprobado BPM" : "BPM Pendiente / Denegado", 
                       style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para hacer la lista de datos más limpia
  Widget _construirFilaDatos(IconData icono, String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icono, color: Colors.blueGrey, size: 28),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiqueta, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}