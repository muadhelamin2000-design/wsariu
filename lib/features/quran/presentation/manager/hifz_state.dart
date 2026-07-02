part of 'hifz_cubit.dart';

abstract class HifzState extends Equatable {
  const HifzState();

  @override
  List<Object> get props => [];
}

class HifzInitial extends HifzState {}

class HifzLoading extends HifzState {}

class HifzLoaded extends HifzState {
  final List<HifzPage> pages;
  final List<Map<String, dynamic>> weeklyReviews;

  const HifzLoaded(this.pages, {this.weeklyReviews = const []});

  @override
  List<Object> get props => [pages, weeklyReviews];
}

class HifzError extends HifzState {
  final String message;

  const HifzError(this.message);

  @override
  List<Object> get props => [message];
}
