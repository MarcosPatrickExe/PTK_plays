import '../data/models/PostModel.dart';
import '../data/repositories/PostRepository.dart';

class PostViewModel {
  final PostRepository _repository;
  PostViewModel(this._repository);

  Stream<List<PostModel>> streamPostagens() => _repository.streamPostagens();
}
