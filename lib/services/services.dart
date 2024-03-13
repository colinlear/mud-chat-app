import 'package:aachat/services/connection_service.dart';
import 'package:aachat/services/data_service.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

Future<void> setup() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  final dataService = DataService();
  await dataService.init();
  getIt.registerSingleton<DataService>(dataService);

  getIt.registerLazySingleton<ConnectionService>(
    () => ConnectionService(
      Uri.parse("ws://localhost:3000"),
    ),
  );
}
