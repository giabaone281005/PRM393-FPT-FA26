import 'study_repository.dart';

class MascotRepository {
  static Future<({String hat, String glasses})> fetchMascotGear(
    String kidId,
  ) async {
    final data = Map<String, dynamic>.from(
      await StudyRepository.rpc('get_wardrobe', {'p_kid': kidId}) as Map,
    );
    return (hat: data['hat'] as String, glasses: data['glasses'] as String);
  }
}
