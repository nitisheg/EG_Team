import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/auth/auth_repository.dart';
import 'package:flutterquiz/features/auth/cubits/refer_and_earn_cubit.dart';
import 'package:flutterquiz/features/profile_management/cubits/delete_account_cubit.dart';
import 'package:flutterquiz/features/profile_management/cubits/update_user_details_cubit.dart';
import 'package:flutterquiz/features/profile_management/cubits/upload_profile_cubit.dart';
import 'package:flutterquiz/features/profile_management/profile_management_repository.dart';
import 'package:flutterquiz/ui/screens/badges_screen.dart';
import 'package:flutterquiz/ui/screens/home/home_screen.dart';
import 'package:flutterquiz/ui/screens/menu/menu_screen.dart';
import 'package:flutterquiz/ui/screens/profile/create_or_edit_profile_screen.dart';
import 'package:flutterquiz/ui/screens/rewards/rewards_screen.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();

  static Route<dynamic> route({int initialIndex = 0}) {
    return CupertinoPageRoute(
      builder: (_) => BottomNavScreen(
        initialIndex: initialIndex,
      ),
    );
  }
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  late int _selectedIndex;

  late final List<ValueNotifier<int>> _refreshNotifiers;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _refreshNotifiers = List.generate(5, (_) => ValueNotifier<int>(0));
  }

  List<Widget> get _screens => [
        ValueListenableBuilder<int>(
          valueListenable: _refreshNotifiers[0],
          builder: (context, value, _) {
            // Passing a UniqueKey will force HomeScreen to rebuild from scratch
            return HomeScreen(key: ValueKey(value));
          },
        ),
        ValueListenableBuilder<int>(
          valueListenable: _refreshNotifiers[1],
          builder: (context, value, _) {
            return RewardsScreen(key: ValueKey(value));
          },
        ),
        ValueListenableBuilder<int>(
          valueListenable: _refreshNotifiers[2],
          builder: (context, value, _) {
            return BadgesScreen(
              key: ValueKey(value),
            );
          },
        ),
        ValueListenableBuilder<int>(
          valueListenable: _refreshNotifiers[3],
          builder: (context, value, _) {
            return RewardsScreen(key: ValueKey(value));
          },
        ),
        ValueListenableBuilder<int>(
          valueListenable: _refreshNotifiers[4],
          builder: (context, value, _) {
            return MultiBlocProvider(
              providers: [
                BlocProvider<UploadProfileCubit>(
                  create: (_) =>
                      UploadProfileCubit(ProfileManagementRepository()),
                ),
                BlocProvider<ReferAndEarnCubit>(
                  create: (_) => ReferAndEarnCubit(AuthRepository()),
                ),
                BlocProvider<UpdateUserDetailCubit>(
                  create: (_) =>
                      UpdateUserDetailCubit(ProfileManagementRepository()),
                ),
              ],
              child: const CreateOrEditProfileScreen(
                args: CreateOrEditProfileScreenArgs(isNewUser: false),
              ),
            );
          },
        ),
      ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      // Trigger refresh by incrementing the notifier's value
      _refreshNotifiers[index].value++;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book),
              label: 'Learn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.workspace_premium),
              label: 'Badges',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard),
              label: 'Rewards',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
