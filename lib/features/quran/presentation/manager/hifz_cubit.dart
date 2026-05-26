import 'package:flutter_bloc/flutter_bloc.dart';

abstract class HifzState {}
class HifzInitial extends HifzState {}
class HifzLoading extends HifzState {}
class HifzLoaded extends HifzState {}
class HifzError extends HifzState {
  final String message;
  HifzError(this.message);
}

class HifzCubit extends Cubit<HifzState> {
  HifzCubit() : super(HifzInitial());

  Future<void> addPage(int page) async {
    // Dummy implementation
  }
}
