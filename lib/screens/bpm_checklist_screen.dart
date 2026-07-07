import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'qr_generator_screen.dart';

class BpmChecklistScreen extends StatefulWidget {
  final String empleadoId;
  const BpmChecklistScreen({Key? key, required this.empleadoId}) : super(key: key);

  @override
  _BpmChecklistScreenState createState() => _BpmChecklistScreenState();
}

class _BpmChecklistScreenState extends State<BpmChecklistScreen> {
  bool _sinSintomas = false;
  bool _uniformeLimpio = false;
  bool _manosLavadas = false;
  bool _cargando = false;

  bool get _formularioValido => _sinSintomas && _uniformeLimpio && _manosLavadas;

  Future<void> _guardarChecklist() async {
    if (!_formularioValido) return;
    setState(() => _cargando = true);

    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(widget.empleadoId).update({
        'bpmAprobado': true,
        'fechaUltimoChecklist': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => QrGeneratorScreen(empleadoId: widget.empleadoId)));
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Protocolo Inocuidad (BPM)')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  CheckboxListTile(title: const Text('Sin síntomas de enfermedad.'), value: _sinSintomas, onChanged: (val) => setState(() => _sinSintomas = val!)),
                  CheckboxListTile(title: const Text('Uniforme limpio e indumentaria completa.'), value: _uniformeLimpio, onChanged: (val) => setState(() => _uniformeLimpio = val!)),
                  CheckboxListTile(title: const Text('Manos lavadas y desinfectadas.'), value: _manosLavadas, onChanged: (val) => setState(() => _manosLavadas = val!)),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _formularioValido ? _guardarChecklist : null,
                    child: const Text('Generar Acceso QR'),
                  ),
                ],
              ),
            ),
    );
  }
}