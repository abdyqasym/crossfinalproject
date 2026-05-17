// ignore_for_file: directives_ordering
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:build_runner_core/build_runner_core.dart' as _i1;
import 'package:riverpod_generator/builder.dart' as _i2;
import 'package:json_serializable/builder.dart' as _i3;
import 'package:drift_dev/integrations/build.dart' as _i4;
import 'package:source_gen/builder.dart' as _i5;
import 'package:chopper_generator/chopper_generator.dart' as _i6;
import 'package:build_resolvers/builder.dart' as _i7;
import 'dart:isolate' as _i8;
import 'package:build_runner/build_runner.dart' as _i9;
import 'dart:io' as _i10;

final _builders = <_i1.BuilderApplication>[
  _i1.apply(
    r'riverpod_generator:riverpod_generator',
    [_i2.riverpodBuilder],
    _i1.toDependentsOf(r'riverpod_generator'),
    hideOutput: true,
    appliesBuilders: const [r'source_gen:combining_builder'],
  ),
  _i1.apply(
    r'json_serializable:json_serializable',
    [_i3.jsonSerializable],
    _i1.toDependentsOf(r'json_serializable'),
    hideOutput: true,
    appliesBuilders: const [r'source_gen:combining_builder'],
  ),
  _i1.apply(
    r'drift_dev:preparing_builder',
    [_i4.preparingBuilder],
    _i1.toNoneByDefault(),
    hideOutput: true,
    appliesBuilders: const [r'drift_dev:cleanup'],
  ),
  _i1.apply(
    r'drift_dev:drift_dev',
    [
      _i4.discover,
      _i4.analyzer,
      _i4.driftBuilder,
    ],
    _i1.toDependentsOf(r'drift_dev'),
    hideOutput: true,
    appliesBuilders: const [
      r'source_gen:combining_builder',
      r'drift_dev:preparing_builder',
    ],
  ),
  _i1.apply(
    r'source_gen:combining_builder',
    [_i5.combiningBuilder],
    _i1.toNoneByDefault(),
    hideOutput: false,
    appliesBuilders: const [r'source_gen:part_cleanup'],
  ),
  _i1.apply(
    r'drift_dev:analyzer',
    [
      _i4.discover,
      _i4.analyzer,
    ],
    _i1.toNoneByDefault(),
    hideOutput: true,
    appliesBuilders: const [r'drift_dev:preparing_builder'],
  ),
  _i1.apply(
    r'drift_dev:not_shared',
    [_i4.driftBuilderNotShared],
    _i1.toNoneByDefault(),
    hideOutput: false,
  ),
  _i1.apply(
    r'drift_dev:modular',
    [_i4.modular],
    _i1.toNoneByDefault(),
    hideOutput: false,
    appliesBuilders: const [r'drift_dev:analyzer'],
  ),
  _i1.apply(
    r'chopper_generator:chopper_generator',
    [_i6.chopperGeneratorFactory],
    _i1.toRoot(),
    hideOutput: false,
  ),
  _i1.apply(
    r'build_resolvers:transitive_digests',
    [_i7.transitiveDigestsBuilder],
    _i1.toAllPackages(),
    isOptional: true,
    hideOutput: true,
    appliesBuilders: const [r'build_resolvers:transitive_digest_cleanup'],
  ),
  _i1.applyPostProcess(
    r'build_resolvers:transitive_digest_cleanup',
    _i7.transitiveDigestCleanup,
  ),
  _i1.applyPostProcess(
    r'source_gen:part_cleanup',
    _i5.partCleanup,
  ),
  _i1.applyPostProcess(
    r'drift_dev:cleanup',
    _i4.driftCleanup,
  ),
];
void main(
  List<String> args, [
  _i8.SendPort? sendPort,
]) async {
  var result = await _i9.run(
    args,
    _builders,
  );
  sendPort?.send(result);
  _i10.exitCode = result;
}
