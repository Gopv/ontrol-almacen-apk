import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> registrarAcceso(String empleadoId, String zona, {String lote = 'Sin Asignar'}) async {
    try {
      DocumentSnapshot doc = await _db.collection('usuarios').doc(empleadoId).get();
      
      if (doc.exists) {
        bool bpmAprobado = doc.get('bpmAprobado') ?? false;
        
        if (!bpmAprobado) {
          return false; 
        }

        // Capturamos la fecha y hora exactas del dispositivo
        DateTime momentoActual = DateTime.now();
        String fechaHoraFormateada = "${momentoActual.day}/${momentoActual.month}/${momentoActual.year} ${momentoActual.hour}:${momentoActual.minute}";

        await _db.collection('logs_acceso').add({
          'empleadoId': empleadoId,
          'zona': zona,
          'loteAsignado': lote,
          'timestamp': FieldValue.serverTimestamp(), // Se mantiene para el control interno de Firestore
          'fecha_hora_exacta': fechaHoraFormateada,  // ¡Nuevo! Texto directo para que el Excel lo capture sin errores
        });
        
        return true; 
      }
      return false;
    } catch (e) {
      print("Error registrando acceso: $e");
      return false;
    }
  }
}