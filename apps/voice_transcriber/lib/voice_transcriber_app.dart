import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/voice_transcriber_dependencies.dart';
import 'features/session/presentation/cubit/voice_session_cubit.dart';
import 'features/session/presentation/pages/voice_transcriber_page.dart';

class VoiceTranscriberApp extends StatefulWidget {
  const VoiceTranscriberApp({super.key});

  @override
  State<VoiceTranscriberApp> createState() => _VoiceTranscriberAppState();
}

class _VoiceTranscriberAppState extends State<VoiceTranscriberApp> {
  late final VoiceTranscriberDependencies _dependencies;

  @override
  void initState() {
    super.initState();
    _dependencies = VoiceTranscriberDependencies.bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VoiceSessionCubit>.value(
      value: _dependencies.sessionCubit,
      child: MaterialApp(
        title: 'Voice Transcriber',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const VoiceTranscriberPage(),
      ),
    );
  }
}
