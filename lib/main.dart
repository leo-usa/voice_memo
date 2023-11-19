import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'files.dart';
import 'record.dart';
import 'settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool completedOnboarding = prefs.getBool('completedOnboarding') ?? false;

  runApp(completedOnboarding ? const MyApp() : const OnboardingApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Memo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Voice Memo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int currentPageIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: currentPageIndex == 1
          ? AppBar(
              title: Text(widget.title),
              actions: const [
                ResetOnboardingButton(), // Lisätään ResetOnboardingButton oikeaan yläkulmaan
              ],
            )
          : null,
      bottomNavigationBar: NavigationBar(
        animationDuration: const Duration(milliseconds: 1000),
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.folder),
            label: 'Files',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic),
            label: 'Record',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
        onDestinationSelected: (int index) async {
          if (index == 0) {
            // Check if "Files" destination is selected
            await updateFileNames(); // Call your async function here
          }
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
      ),
      body: <Widget>[
        const FilesPage(),
        const RecordPage(),
        const SettingsPage(),
      ][currentPageIndex],
    );
  }
}

// Onboarding, will be shown only the first time user enters the app
class OnboardingApp extends StatelessWidget {
  const OnboardingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: IntroductionScreen(
        dotsDecorator: DotsDecorator(
          activeColor: Colors.cyan,
          activeSize: const Size(18, 9),
          activeShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        pages: [
          PageViewModel(
            title: "Welcome to Voice Memo",
            body:
                "We're excited to have you on board! Our app is designed to make your professional life easier by transforming spoken words into text using the power of AI. Whether you're recording meetings, interviews, or any other conversations, we've got you covered.",
            image: Image.asset(
              "assets/img/logo_still.png",
              height: 70.0,
            ),
          ),
          PageViewModel(
            title: "Recording Made Easy!",
            body:
                "With Voice Memo, capturing important conversations has never been simpler. Just tap the 'Record' button and start speaking. We'll take care of the rest.",
            image: Image.asset(
              "assets/img/record_onboard.png",
              height: 120.0,
            ),
          ),
          PageViewModel(
            title: "Key Features",
            body:
                "After completing your recording, you can access the following features: an accurate text transcript, a cleaned transcript free from errors, a summary, and the original audio.",
            image: Image.asset(
              "assets/img/features_onboard.png",
              height: 120.0,
            ),
          ),
          PageViewModel(
            title: "Smooth Workflow",
            body:
                "Smart file organization in specific folders to easy access to them later. Focus on what matters most, and let us handle the rest. \n\n Welcome to a smarter way of working!",
            image: Image.asset(
              "assets/img/folder_onboard.png",
              height: 120.0,
            ),
          ),
        ],
        onDone: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('completedOnboarding', true);
          runApp(const MyApp());
        },
        onSkip: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('completedOnboarding', true);
          runApp(const MyApp());
        },
        showSkipButton: true,
        skip: const Text("Skip"),
        next: const Text("Next"),
        done: const Text("Get Started"),
      ),
    );
  }
}

// Reset onboarding -button while developing
class ResetOnboardingButton extends StatelessWidget {
  const ResetOnboardingButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('completedOnboarding', false);
        runApp(const OnboardingApp());
      },
      child: const Text("Reset Onboarding"),
    );
  }
}
