import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/db_service.dart';
import '../services/export_service.dart';
import 'registro_screen.dart';
import 'login_screen.dart';
import 'directorio_screen.dart'; // <-- Importación del nuevo módulo agregada

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final DatabaseService _dbService = DatabaseService();
  
  // Variables de estado
  bool isProcessing = false;
  String codigoEscaneado = "Ningún código detectado";
  String idEmpleadoActual = "Cargando...";
  String zonaActual = "Cargando...";
  String loteActual = "Cargando...";

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  // Extrae los datos fijos del operario que tiene el teléfono
  Future<void> _cargarDatosUsuario() async {
    User? usuario = FirebaseAuth.instance.currentUser;
    if (usuario != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('empleados').doc(usuario.uid).get();
        if (doc.exists && mounted) {
          setState(() {
            idEmpleadoActual = doc.get('id_empleado') ?? 'No asignado';
            zonaActual = doc.get('zona') ?? 'Sin Zona';
            loteActual = doc.get('lote') ?? 'Sin Lote';
          });
        }
      } catch (e) {
        debugPrint('Error al cargar datos del usuario: $e');
      }
    }
  }

  // Lógica de registro automatizada (Sin ventanas de ingreso manual)
  void procesarCodigoQR(String empleadoIdScaneado) async {
    setState(() {
      codigoEscaneado = empleadoIdScaneado;
      isProcessing = true;
    }); 

    // Aquí inyectamos automáticamente la Zona y el Lote del usuario actual
    bool accesoPermitido = await _dbService.registrarAcceso(
      empleadoIdScaneado, 
      zonaActual, 
      lote: loteActual
    );

    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(accesoPermitido ? 'ACCESO PERMITIDO' : 'ACCESO DENEGADO - Alerta BPM'),
        backgroundColor: accesoPermitido ? Colors.green : Colors.red,
      ),
    );

    setState(() => isProcessing = false);
  }

  // Controlador de hardware para la cámara a demanda
  void mostrarEscanerQR(BuildContext context) {
    final MobileScannerController cameraController = MobileScannerController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              AppBar(
                title: const Text("Escáner - Comedor VIPI"),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      cameraController.dispose();
                      Navigator.pop(context);
                    },
                  )
                ],
              ),
              Expanded(
                child: MobileScanner(
                  controller: cameraController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        // Apagamos hardware, cerramos ventana y procesamos
                        cameraController.dispose();
                        Navigator.pop(context);
                        procesarCodigoQR(barcode.rawValue!);
                        break;
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) => cameraController.dispose()); // Failsafe de memoria
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control / Auditoría'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar Reporte',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generando archivo...')));
              await ExportService().exportarLogsACSV();
            },
          ),
          IconButton(
            icon: const Icon(Icons.group), // <-- Botón del Directorio agregado
            tooltip: 'Directorio de Personal',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DirectorioScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Registrar Personal',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistroScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: Center(
        child: isProcessing 
          ? const CircularProgressIndicator()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.admin_panel_settings, size: 80, color: Colors.blueGrey),
                const SizedBox(height: 20),
                Text("Operario: $idEmpleadoActual", style: const TextStyle(fontSize: 16)),
                Text("Zona: $zonaActual | Lote: $loteActual", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () => mostrarEscanerQR(context),
                  icon: const Icon(Icons.qr_code_scanner, size: 28),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text("ESCANEAR QR", style: TextStyle(fontSize: 18)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  "Último escaneo:\n$codigoEscaneado", 
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black54)
                ),
              ],
            ),
      ),
    );
  }
}