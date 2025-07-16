import 'package:flutter/material.dart';
import 'package:flutterquiz/core/navigation/route_args.dart';

/// Extension on BuildContext to add type-safe navigation methods
extension NavigationExtension on BuildContext {
  /// Pop the current route and optionally return a result
  void pop<T extends Object?>([T? result]) {
    Navigator.of(this).pop<T>(result);
  }

  /// Check if the current route can be popped
  bool get canPop => Navigator.of(this).canPop();

  /// Pop the current route if possible
  void shouldPop<T extends Object?>([T? result]) {
    if (canPop) {
      pop<T>(result);
    }
  }

  /// Push a named route with type-safe arguments
  Future<T?> pushNamed<T extends Object?, A extends RouteArgs>(
    String routeName, {
    A? arguments,
  }) {
    return Navigator.of(this).pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  /// Push a named route and remove all previous routes
  Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?,
      A extends RouteArgs>(
    String routeName, {
    A? arguments,
    TO? result,
  }) {
    return Navigator.of(this).pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  /// Push a named route and remove all previous routes
  Future<T?> pushNamedAndRemoveUntil<T extends Object?, A extends RouteArgs>(
    String routeName, {
    A? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) {
    return Navigator.of(this).pushNamedAndRemoveUntil<T>(
      routeName,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }

  /// Push a route and wait for a result
  Future<T?> push<T extends Object?, A extends RouteArgs>(
    Route<T> route, {
    A? arguments,
  }) {
    return Navigator.of(this).push<T>(route);
  }

  /// Push a route and replace the current route
  Future<T?> pushReplacement<T extends Object?, TO extends Object?,
      A extends RouteArgs>(
    Route<T> route, {
    A? arguments,
    TO? result,
  }) {
    return Navigator.of(this).pushReplacement<T, TO>(route);
  }

  /// Push a route and remove all previous routes
  Future<T?> pushAndRemoveUntil<T extends Object?, A extends RouteArgs>(
    Route<T> route, {
    A? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) {
    return Navigator.of(this).pushAndRemoveUntil<T>(
      route,
      predicate ?? (route) => false,
    );
  }
}
