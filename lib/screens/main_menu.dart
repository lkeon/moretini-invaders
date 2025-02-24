import 'package:flutter/material.dart';
import 'dart:io';
import 'settings_menu.dart';
import 'select_spaceship.dart';

// Represents the main menu screen of Spacescape, allowing
// players to start the game or modify in-game settings.
class MainMenu extends StatelessWidget {
  const MainMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    "assets/images/T_PurpleBackground_Version2_Layer1.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Game title.
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 50.0),
                  child: Text(
                    'MORETINI\nINVADERS',
                    style: TextStyle(
                      fontSize: 50.0,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 20.0,
                          color: Colors.black,
                          offset: Offset(0, 0),
                        )
                      ],
                    ),
                  ),
                ),

                // Play button.
                SizedBox(
                  width: MediaQuery.of(context).size.width / 3,
                  child: ElevatedButton(
                    onPressed: () {
                      // Push and replace current screen (i.e MainMenu) with
                      // SelectSpaceship(), so that player can select a spaceship.
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const SelectSpaceship(),
                        ),
                      );
                    },
                    child: const Text('Play'),
                  ),
                ),

                // Settings button.
                SizedBox(
                  width: MediaQuery.of(context).size.width / 3,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsMenu(),
                        ),
                      );
                    },
                    child: const Text('Settings'),
                  ),
                ),

                // Quit App button.
                SizedBox(
                  width: MediaQuery.of(context).size.width / 3,
                  child: ElevatedButton(
                    onPressed: () => exit(0),
                    child: const Text('Quit App'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
