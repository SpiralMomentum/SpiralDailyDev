
import 'package:equatable/equatable.dart';
import 'package:ui_components/card/info.dart';

enum InfoShelfStatus { initial, loading, success, failure }

extension InfoShelfStatusEX on InfoShelfStatus {
  bool get isInitial => this == InfoShelfStatus.initial;
  bool get isLoading => this == InfoShelfStatus.loading;
  bool get isSuccess => this == InfoShelfStatus.success;
  bool get isFailure => this == InfoShelfStatus.failure;
}

final class InfoShelfState extends Equatable {
  final InfoShelfStatus status;
  final List<Info> info;

  const InfoShelfState({
    this.status = InfoShelfStatus.initial,
    required this.info,
  }) ;

  InfoShelfState copyWith({
    InfoShelfStatus? status,
    List<Info>? info,
  }) {
    return InfoShelfState(
      status: status ?? this.status,
      info: info ?? this.info,
    );
  }

  @override
  List<Object?> get props => [status, info];
}