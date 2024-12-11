import 'package:flutter/material.dart';
import '../sign_in_up/login_page.dart';
import '../sign_in_up/sign_up_page.dart';
//import '../sign_in_up/usos_sign.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool isSignIn = true;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double mainTitleFontSize = (screenWidth * 0.16).clamp(48, 80);
    double subtitleFontSize = (screenWidth * 0.08).clamp(20, 30);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('lib/assets/background.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(0.2),
                  BlendMode.lighten,
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.41,
                    height: MediaQuery.of(context).size.height * 0.18,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: Colors.black.withOpacity(0.5), width: 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          blurRadius: 3,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Image.asset(
                        'lib/assets/logo-new.png',
                        height: MediaQuery.of(context).size.height * 0.16,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Text(
                    "DormKey",
                    style: TextStyle(
                      fontSize: mainTitleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          offset: const Offset(2, 2),
                          blurRadius: 5,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "Akademik pod kontrolą",
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          blurRadius: 3,
                          offset: const Offset(1, 1),
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 110,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: screenHeight * 0.1,
            left: screenWidth * 0.2,
            right: screenWidth * 0.2,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: FractionallySizedBox(
                    widthFactor: 1.2,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 5,
                          ),
                        ],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                               SignUpPage(onTapClickListener: switchPage),
                          ));
                        },
                        child: Text(
                          "Zaczynamy!",
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.surface,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: FractionallySizedBox(
                    widthFactor: 1.2,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 5,
                          ),
                        ],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                LoginPage(onTapClickListener: switchPage),
                          ));
                        },
                        style: TextButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                        ),
                        child: Text(
                          "Masz już konto? Zaloguj się",
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  switchPage() => setState(() => isSignIn = !isSignIn);
}
