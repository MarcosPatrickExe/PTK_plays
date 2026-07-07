import '../data/models/PostModel.dart';
import '../data/repositories/PostRepository.dart';

class PostViewModel {
  final PostRepository _repository;
  PostViewModel(this._repository);

  Stream<List<PostModel>> streamPostagens() => _repository.streamPostagens();

  Future<void> votar({required String postId, required int indiceOpcao, required String uid}) =>
      _repository.votar(postId: postId, indiceOpcao: indiceOpcao, uid: uid);
}
