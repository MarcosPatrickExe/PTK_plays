import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/PostModel.dart';

class PostRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<PostModel>> streamPostagens() {
    return _firestore
        .collection('posts')
        .orderBy('criadoEm', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }
}
