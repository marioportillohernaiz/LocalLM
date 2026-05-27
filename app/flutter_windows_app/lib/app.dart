import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'macos_app.dart';
import 'windows_app.dart';

class LocalLMApp extends StatelessWidget {
  const LocalLMApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && Platform.isMacOS) {
      return const LocalLMMacosApp();
    }

    return const LocalLMWindowsApp();
  }
}
