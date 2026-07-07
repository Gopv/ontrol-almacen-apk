import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> exportarLogsACSV() async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('logs_acceso')
          .orderBy('timestamp', descending: true)
          .get();

      // Cabeceras exactas para tu reporte
      List<List<dynamic>> filasCSV = [
        ['ID_Empleado', 'Zona', 'Lote_Asignado', 'Fecha', 'Hora']
      ];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        String fechaStr = 'N/A';
        String horaStr = 'N/A';
        
        // 1. INTENTA LEER EL NUEVO FORMATO DE TEXTO DIRECTO
        if (data.containsKey('fecha_hora_exacta') && data['fecha_hora_exacta'] != null) {
          String fechaExacta = data['fecha_hora_exacta'];
          List<String> partes = fechaExacta.split(' '); // Separa "DD/MM/YYYY" de "HH:MM"
          if (partes.length == 2) {
            fechaStr = partes[0];
            horaStr = partes[1];
          } else {
            fechaStr = fechaExacta;
          }
        } 
        // 2. RESPALDO PARA REGISTROS VIEJOS DE PRUEBAS ANTERIORES
        else if (data['timestamp'] != null) {
          Timestamp ts = data['timestamp'];
          DateTime dt = ts.toDate();
          fechaStr = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
          horaStr = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
        }

        // Mapeo blindado de las columnas
        filasCSV.add([
          data['empleadoId'] ?? 'Desconocido',
          data['zona'] ?? 'Sin Zona',
          data['loteAsignado'] ?? 'Sin Asignar',
          fechaStr,
          horaStr
        ]);
      }

      String csvCadenas = const ListToCsvConverter().convert(filasCSV);
      final directorio = await getTemporaryDirectory();
      final rutaArchivo = "${directorio.path}/reporte_trazabilidad.csv";
      File archivo = File(rutaArchivo);
      await archivo.writeAsString(csvCadenas);

      // Personalizado para identificar rápidamente los archivos del proyecto
      await Share.shareXFiles([XFile(rutaArchivo)], text: 'Reporte de trazabilidad - Proyecto SIGCA Comedor VIPI.');

    } catch (e) {
      print("Error crítico exportando a CSV: $e");
    }
  }
}