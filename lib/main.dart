import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

// TODO: Substitua pelos valores do seu projeto Supabase
// Acesse: https://supabase.com → seu projeto → Project Settings → API
const _supabaseUrl = 'https://fkinninjwagavdimxowx.supabase.co';
const _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZraW5uaW5qd2FnYXZkaW14b3d4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkwNjQwMjYsImV4cCI6MjA5NDY0MDAyNn0.FUbMCubuveZ5YvviswE1Q0oInzCfiCXqOdZVUwr-hOs';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR');

  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
