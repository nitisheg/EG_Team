import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/features/settings/settings_local_data_source.dart';

class ThemeState {
  const ThemeState(this.appTheme);

  final AppTheme appTheme;
}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit(this.settingsLocalDataSource)
      : super(
          ThemeState(
            settingsLocalDataSource.theme == darkThemeKey
                ? AppTheme.dark
                : AppTheme.light,
          ),
        );

  SettingsLocalDataSource settingsLocalDataSource;

  void changeTheme(AppTheme appTheme) {
    settingsLocalDataSource.theme =
        appTheme == AppTheme.dark ? darkThemeKey : lightThemeKey;
    emit(ThemeState(appTheme));
  }
}
