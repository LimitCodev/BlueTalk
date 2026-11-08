import '../../../data/contracts/repos.dart';
import '../../../data/models/models.dart';
import 'resumenes_repo.dart';

/// Decorador: cada evento va al registro de siempre **y** a su resumen
/// diario. Las features siguen llamando a `usageRepoProvider.record` sin
/// saber que existen los informes.
class UsageRepoConResumen implements UsageRepo {
  const UsageRepoConResumen(this._base, this._resumenes);

  final UsageRepo _base;
  final ResumenesRepo _resumenes;

  @override
  Future<void> record(UsageEvent event) async {
    await _resumenes.sumar(event);
    await _base.record(event);
  }

  @override
  Future<List<UsageEvent>> events() => _base.events();
}
