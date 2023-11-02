import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: const Center(
        child: Column(
          children: [
            DecoratedBox(
              decoration: rowUnderline,
              child: Padding(
                padding: EdgeInsets.all(rowPadding),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 16.0, right: 14.0),
                      child: Icon(Icons.wifi_off),
                    ),
                    Text('Offline Mode'),
                    Spacer(),
                    Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: Switch(
                        value: true,
                        onChanged: null,
                      ),
                    )
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: rowUnderline,
              child: Padding(
                padding: EdgeInsets.all(rowPadding),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 16.0, right: 14.0),
                      child: Icon(Icons.save),
                    ),
                    Text('Autosave'),
                    Spacer(),
                    Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: Switch(
                        value: true,
                        onChanged: null,
                      ),
                    )
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: rowUnderline,
              child: Padding(
                padding: EdgeInsets.all(rowPadding),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Icon(Icons.euro),
                    ),
                    TextButton(
                        onPressed: null,
                        child: Text('Subscription plan',
                            style: TextStyle(color: Colors.white)))
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: rowUnderline,
              child: Padding(
                padding: EdgeInsets.all(rowPadding),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Icon(Icons.shield),
                    ),
                    TextButton(
                        onPressed: null,
                        child: Text('Privacy Policy',
                            style: TextStyle(color: Colors.white)))
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: rowUnderline,
              child: Padding(
                padding: EdgeInsets.all(rowPadding),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Icon(Icons.question_mark),
                    ),
                    TextButton(
                        onPressed: null,
                        child: Text('Help & Support',
                            style: TextStyle(color: Colors.white)))
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

const double rowPadding = 16.0;

const rowUnderline = BoxDecoration(
    border: Border(
        bottom:
            BorderSide(color: Color.fromARGB(130, 255, 255, 255), width: 1)));
