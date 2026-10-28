import 'dart:io';
import 'package:auto_sched_ai/branding/auto_sched_brand_assets.dart';

void main() {
  final outDir = Directory('assets/images');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  final full = File('${outDir.path}/full_logo.png');
  full.writeAsBytesSync(AutoSchedBrandAssets.fullLogoBytes);

  final icon = File('${outDir.path}/icon_logo.png');
  icon.writeAsBytesSync(AutoSchedBrandAssets.iconLogoBytes);

  print('Wrote: ${full.path}');
  print('Wrote: ${icon.path}');
}
