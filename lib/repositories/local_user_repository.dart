import '../services/user_service.dart';
import 'user_repository.dart';

class LocalUserRepository implements UserRepository {
  LocalUserRepository({required UserService userService})
    : _userService = userService;

  final UserService _userService;

  @override
  Future<String> getUserId() => _userService.getUserId();
}
