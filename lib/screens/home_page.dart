import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rentool/main.dart';
import 'package:rentool/services/auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();

  Size get _size => MediaQuery.of(context).size;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (_size.width > 530)
              const Padding(
                padding: EdgeInsets.only(right: 20),
                child: Text('Rentool'),
              ),
            Flexible(
              child: Center(
                child: buildSearchBar(),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            iconSize: 30,
            splashRadius: 20,
            icon: const Icon(Icons.language),
            onPressed: () {
              // ChangeLanguage

              // get the index of the current locale
              var crntLocale = Locale(AppLocalizations.of(context)!.localeName);
              var localeIndex = AppLocalizations.supportedLocales.indexOf(crntLocale);

              var next =
                  AppLocalizations.supportedLocales[(localeIndex + 1) % AppLocalizations.supportedLocales.length];
              MyApp.of(context)!.setLocale(next);
            },
          ),
          IconButton(
            iconSize: 30,
            splashRadius: 20,
            icon: const CircleAvatar(),
            onPressed: () {
              AuthServices.signOut();
            },
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Center(
        child: Text(AppLocalizations.of(context)!.rentool),
      ),
    );
  }

  Container buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.blue[300],
      ),
      width: 500,
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          icon: Icon(Icons.search),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
