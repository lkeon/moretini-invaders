import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/parallax.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/overlays/pause_menu.dart';
import '../widgets/overlays/pause_button.dart';
import '../widgets/overlays/game_over_menu.dart';

import '../models/player_data.dart';
import '../models/spaceship_details.dart';

import 'enemy.dart';
import 'health_bar.dart';
import 'player.dart';
import 'bullet.dart';
import 'command.dart';
import 'power_ups.dart';
import 'enemy_manager.dart';
import 'meteor_manager.dart';
import 'power_up_manager.dart';
import 'audio_player_component.dart';

// This class is responsible for initializing and running the game-loop.
class MoretiniInvaders extends FlameGame
    with
        HasDraggables,
        HasTappables,
        HasCollisionDetection,
        HasKeyboardHandlerComponents {
  // Stores a reference to player component.
  late Player _player;

  // Stores a reference to the meteor spritesheet.
  late List<Sprite> meteorSprites;

  // Store bullet sprite
  late Sprite bulletSprite;

  // Stores a reference to an enemy manager component.
  late EnemyManager _enemyManager;

  // Stores a reference to the meteor manager
  late MeteorManager _meteorManager;

  // Stores a reference to an power-up manager component.
  late PowerUpManager _powerUpManager;

  // Displays player score on top left.
  late TextComponent _playerScore;

  // Height of the controls at the bottom
  final Vector2 controlHeight = Vector2(0, 150);

  // Displays player health on top right.
  late TextComponent _playerHealth;

  late AudioPlayerComponent _audioPlayerComponent;

  // List of commands to be processed in current update.
  final _commandList = List<Command>.empty(growable: true);

  // List of commands to be processed in next update.
  final _addLaterCommandList = List<Command>.empty(growable: true);

  // Indicates whether the game world has been already initialized.
  bool _isAlreadyLoaded = false;

  // This method gets called by Flame before the game-loop begins.
  // Assets loading and adding component should be done here.
  @override
  Future<void> onLoad() async {
    // Makes the game use a fixed resolution irrespective of the windows size.
    camera.viewport = FixedResolutionViewport(Vector2(size.x, size.y));

    // Initialize the game world only one time.
    if (!_isAlreadyLoaded) {
      // Loads and caches all the images for later use.
      await images.loadAll([
        'playerShip1_blue.png',
        'playerShip1_green.png',
        'playerShip1_orange.png',
        'playerShip2_blue.png',
        'playerShip2_green.png',
        'playerShip2_orange.png',
        'playerShip3_blue.png',
        'playerShip3_green.png',
        'freeze.png',
        'icon_plusSmall.png',
        'multi_fire.png',
        'nuke.png',
        'simpleSpace_tilesheet@2.png',
        'explosion3.png',
        'laserRed16.png',
        'enemyBlack1.png',
        'enemyBlack2.png',
        'enemyBlack3.png',
        'enemyBlack4.png',
        'enemyBlack5.png',
        'enemyBlue1.png',
        'enemyBlue2.png',
        'enemyBlue3.png',
        'enemyBlue4.png',
        'enemyBlue5.png',
        'enemyGreen1.png',
        'enemyGreen2.png',
        'enemyGreen3.png',
        'enemyGreen4.png',
        'enemyGreen5.png',
        'enemyRed1.png',
        'meteorBrown_big1.png',
        'meteorBrown_big2.png',
        'meteorBrown_big3.png',
        'meteorBrown_big4.png',
      ]);

      _audioPlayerComponent = AudioPlayerComponent();
      add(_audioPlayerComponent);

      final stars = await ParallaxComponent.load(
        [
          ParallaxImageData('T_PurpleBackground_Version2_Layer1.png'),
          ParallaxImageData('T_PurpleBackground_Version2_Layer2.png'),
          ParallaxImageData('T_PurpleBackground_Version2_Layer3.png'),
          ParallaxImageData('T_PurpleBackground_Version2_Layer4.png'),
        ],
        repeat: ImageRepeat.repeatY,
        baseVelocity: Vector2(0, -50),
        velocityMultiplierDelta: Vector2(0, 1.3),
        fill: LayerFill.width,
      );
      add(stars);

      // Create sprite for bullet
      bulletSprite = Sprite(images.fromCache('laserRed16.png'));

      // Create list of meteor sprites
      meteorSprites = [
        Sprite(images.fromCache('meteorBrown_big1.png')),
        Sprite(images.fromCache('meteorBrown_big2.png')),
        Sprite(images.fromCache('meteorBrown_big3.png')),
        Sprite(images.fromCache('meteorBrown_big4.png')),
      ];

      // Create a basic joystick component on left.
      final joystick = JoystickComponent(
        anchor: Anchor.bottomLeft,
        position: Vector2(30, size.y - 30),
        // size: 100,
        background: CircleComponent(
          radius: 60,
          paint: Paint()..color = Colors.white.withOpacity(0.5),
        ),
        knob: CircleComponent(radius: 30),
      );
      add(joystick);

      /// As build context is not valid in onLoad() method, we
      /// cannot get current [PlayerData] here. So initialize player
      /// with the default SpaceshipType.Canary.
      const spaceshipType = SpaceshipType.canary;
      final spaceship = Spaceship.getSpaceshipByType(spaceshipType);

      _player = Player(
        joystick: joystick,
        spaceshipType: spaceshipType,
        sprite: Sprite(images.fromCache(spaceship.getAssetName())),
        size: Vector2(50, 50),
        position: size / 2,
      );

      // Makes sure that the sprite is centered.
      _player.anchor = Anchor.center;
      add(_player);

      _enemyManager = EnemyManager();
      add(_enemyManager);

      _meteorManager = MeteorManager();
      add(_meteorManager);

      _powerUpManager = PowerUpManager();
      add(_powerUpManager);

      // Create a fire button component on right
      final button = ButtonComponent(
        button: CircleComponent(
          radius: 60,
          paint: Paint()..color = Colors.white.withOpacity(0.5),
        ),
        anchor: Anchor.bottomRight,
        position: Vector2(size.x - 30, size.y - 30),
        onPressed: _player.joystickAction,
      );
      add(button);

      // Create text component for player score.
      _playerScore = TextComponent(
        text: 'Score: 0',
        position: Vector2(10, 10),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'Goldman',
          ),
        ),
      );

      // Setting positionType to viewport makes sure that this component
      // does not get affected by camera's transformations.
      _playerScore.positionType = PositionType.viewport;

      add(_playerScore);

      // Create text component for player health.
      _playerHealth = TextComponent(
        text: 'Health: 100%',
        position: Vector2(size.x - 10, 10),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'Goldman',
          ),
        ),
      );

      // Anchor to top right as we want the top right
      // corner of this component to be at a specific position.
      _playerHealth.anchor = Anchor.topRight;

      // Setting positionType to viewport makes sure that this component
      // does not get affected by camera's transformations.
      _playerHealth.positionType = PositionType.viewport;

      add(_playerHealth);

      // Add the blue bar indicating health.
      add(
        HealthBar(
          player: _player,
          position: _playerHealth.positionOfAnchor(Anchor.topLeft),
          priority: -1,
        ),
      );

      // Set this to true so that we do not initialize
      // everything again in the same session.
      _isAlreadyLoaded = true;
    }
  }

  // This method gets called when game instance gets attached
  // to Flutter's widget tree.
  @override
  void onAttach() {
    if (buildContext != null) {
      // Get the PlayerData from current build context without registering a listener.
      final playerData = Provider.of<PlayerData>(buildContext!, listen: false);
      // Update the current spaceship type of player.
      _player.setSpaceshipType(playerData.spaceshipType);
    }
    _audioPlayerComponent.playBgm('cinematic-time-lapse-115672.mp3');
    super.onAttach();
  }

  @override
  void onDetach() {
    _audioPlayerComponent.stopBgm();
    super.onDetach();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Run each command from _commandList on each
    // component from components list. The run()
    // method of Command is no-op if the command is
    // not valid for given component.
    for (var command in _commandList) {
      for (var component in children) {
        command.run(component);
      }
    }

    // Remove all the commands that are processed and
    // add all new commands to be processed in next update.
    _commandList.clear();
    _commandList.addAll(_addLaterCommandList);
    _addLaterCommandList.clear();

    if (_player.isMounted) {
      // Update score and health components with latest values.
      _playerScore.text = 'Score: ${_player.score}';
      _playerHealth.text = 'Health: ${_player.health}%';

      /// Display [GameOverMenu] when [Player.health] becomes
      /// zero and camera stops shaking.
      if (_player.health <= 0 && (!camera.shaking)) {
        pauseEngine();
        overlays.remove(PauseButton.id);
        overlays.add(GameOverMenu.id);
      }
    }
  }

  // This method handles state of app and pauses
  // the game when necessary.
  @override
  void lifecycleStateChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (_player.health > 0) {
          pauseEngine();
          overlays.remove(PauseButton.id);
          overlays.add(PauseMenu.id);
        }
        break;
    }

    super.lifecycleStateChange(state);
  }

  // Adds given command to command list.
  void addCommand(Command command) {
    _addLaterCommandList.add(command);
  }

  // Resets the game to initial state. Should be called
  // while restarting and exiting the game.
  void reset() {
    // First reset player, enemy manager and power-up manager .
    _player.reset();
    _enemyManager.reset();
    _meteorManager.reset();
    _powerUpManager.reset();

    // Now remove all the enemies, bullets and power ups
    // from the game world. Note that, we are not calling
    // Enemy.destroy() because it will unnecessarily
    // run explosion effect and increase players score.
    children.whereType<Enemy>().forEach((enemy) {
      enemy.removeFromParent();
    });

    children.whereType<Bullet>().forEach((bullet) {
      bullet.removeFromParent();
    });

    children.whereType<PowerUp>().forEach((powerUp) {
      powerUp.removeFromParent();
    });
  }
}
