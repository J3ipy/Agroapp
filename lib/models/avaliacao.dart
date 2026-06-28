import 'package:cloud_firestore/cloud_firestore.dart';

class Avaliacao {
  final String id;
  final String consumidorUid;
  final double nota;
  final String comentario;
  final Timestamp data;

  Avaliacao({
    required this.id,
    required this.consumidorUid,
    required this.nota,
    required this.comentario,
    required this.data,
  });

  static Avaliacao fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Avaliacao(
      id: doc.id,
      consumidorUid: (d['consumidorUid'] ?? '').toString(),
      nota: (d['nota'] ?? 5).toDouble(),
      comentario: (d['comentario'] ?? '').toString(),
      data: d['data'] as Timestamp? ?? Timestamp.now(),
    );
  }
}