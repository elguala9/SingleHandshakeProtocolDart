// AUTO-GENERATED - DO NOT CHANGE
// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import, unused_import, lines_longer_than_80_chars, cascade_invocations
import 'package:singleton_manager/singleton_manager.dart';
import '../impl/socket/dual/dual_shsp_socket_wrapper.dart';
import 'dart:io';
import 'package:meta/meta.dart';
import '../../shsp.dart';

class DualShspSocketWrapperDI extends DualShspSocketWrapper implements ISingletonStandardDI {

  DualShspSocketWrapperDI() : super.emptyForDI();

  factory DualShspSocketWrapperDI.initializeDI() {
    final instance = DualShspSocketWrapperDI();
    instance.initializeDI();
    return instance;
  }

  @override
  void initializeDI() {
    dualSocket = SingletonDIAccess.get<IDualShspSocketAuto>();
  }
}
