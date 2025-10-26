// web/index.dart → main.dart entry
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:fractal_wallet/main.dart' as app;

void main() {
  setUrlStrategy(PathUrlStrategy());
  app.main();
}
