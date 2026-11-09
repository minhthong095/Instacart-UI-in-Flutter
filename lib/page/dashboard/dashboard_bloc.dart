import 'package:flutter_bloc/flutter_bloc.dart';

import '../../mock system/mock_system.dart';

sealed class DashboardEvent {
  const DashboardEvent();
}

final class DashboardStarted extends DashboardEvent {
  const DashboardStarted();
}

sealed class DashboardState {
  const DashboardState();
}

final class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

final class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

final class DashboardLoaded extends DashboardState {
  DashboardLoaded({
    required List<Store> headerStores,
    required List<StoreDisplay> displays,
    required List<Store> allStores,
  }) : headerStores = List.unmodifiable(headerStores),
       displays = List.unmodifiable(displays),
       allStores = List.unmodifiable(allStores);

  final List<Store> headerStores;
  final List<StoreDisplay> displays;
  final List<Store> allStores;
}

final class DashboardFailure extends DashboardState {
  const DashboardFailure(this.error);

  final Object error;
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({required this.service}) : super(const DashboardInitial()) {
    on<DashboardStarted>(_load);
  }

  final DashboardService service;

  Future<void> _load(
    DashboardStarted event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardInitial) return;
    emit(const DashboardLoading());
    try {
      // Keep sampling order stable, and never resample in a widget build.
      final header = await service.getStoreDisplayOnHeader();
      final displays = await service.getStoreDisplays();
      final all = await service.getAllStores();
      if (header == null || displays == null || all == null) {
        emit(const DashboardFailure('Store data is unavailable.'));
        return;
      }
      emit(
        DashboardLoaded(
          headerStores: header,
          displays: displays,
          allStores: all,
        ),
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(DashboardFailure(error));
    }
  }
}
