import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/services/khatma_service.dart';
import '../../data/services/hifz_service.dart';
import 'hifz_model.dart';

abstract class QuranTaskState extends Equatable {
  @override
  List<Object?> get props => [];
}

class QuranTaskInitial extends QuranTaskState {}
class QuranTaskLoading extends QuranTaskState {}
class QuranTaskLoaded extends QuranTaskState {
  final List<KhatmaModel> khatmas;
  final List<HifzTask> hifzTasks;
  QuranTaskLoaded(this.khatmas, this.hifzTasks);
  
  @override
  List<Object?> get props => [khatmas, hifzTasks];
}

class QuranTaskCubit extends Cubit<QuranTaskState> {
  QuranTaskCubit() : super(QuranTaskInitial());

  void loadAll() {
    emit(QuranTaskLoading());
    final k = KhatmaService.getAllKhatmas();
    final h = HifzService.getAllTasks();
    emit(QuranTaskLoaded(k, h));
  }

  Future<void> toggleKhatmaPage(String id, int page) async {
    await KhatmaService.togglePage(id, page);
    loadAll();
  }

  Future<void> toggleHifzPage(String id, int page) async {
    await HifzService.togglePageInTask(id, page);
    loadAll();
  }
}
