import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'game.dart';
import 'bullet.dart';
import 'player.dart';
import 'command.dart';
import 'knows_game_size.dart';
import 'audio_player_component.dart';

import '../models/enemy_data.dart';

// This class represent an enemy component.
class Enemy extends SpriteComponent
    with KnowsGameSize, CollisionCallbacks, HasGameRef<MoretiniInvaders> {
  // The speed of this enemy.
  double _speed = 250;

  // This direction in which this Enemy will move.
  // Defaults to vertically downwards.
  Vector2 moveDirection = Vector2(0, 1);

  // Controls for how long enemy should be freezed.
  late Timer _freezeTimer;

  // Holds an object of Random class to generate random numbers.
  final _random = Random();

  // The data required to create this enemy.
  final EnemyData enemyData;

  // Represents health of this enemy.
  int _hitPoints = 10;

  // To display health in game world.
  final _hpText = TextComponent(
    text: '10 HP',
    textRenderer: TextPaint(
      style: const TextStyle(
        color: Colors.white24,
        fontSize: 12,
        fontFamily: 'Goldman',
      ),
    ),
  );

  // This method generates a random vector with its angle
  // between from 0 and 360 degrees.
  Vector2 getRandomVector() {
    return (Vector2.random(_random) - Vector2.random(_random)) * 500;
  }

  // Returns a random direction vector with slight angle to +ve y axis.
  Vector2 getRandomDirection() {
    return (Vector2.random(_random) - Vector2(0.5, -1)).normalized();
  }

  Enemy({
    required Sprite? sprite,
    required this.enemyData,
    required Vector2? position,
    required Vector2? size,
  }) : super(sprite: sprite, position: position, size: size) {
    // Rotates the enemy component by 180 degrees. This is needed because
    // all the sprites initially face the same direct, but we want enemies to be
    // moving in opposite direction.
    angle = pi;

    // Set the current speed from enemyData.
    _speed = enemyData.speed;

    // Set hitpoint to correct value from enemyData.
    _hitPoints = enemyData.level * 10;
    _hpText.text = '$_hitPoints HP';

    // Sets freeze time to 2 seconds. After 2 seconds speed will be reset.
    _freezeTimer = Timer(2, onTick: () {
      _speed = enemyData.speed;
    });

    // If this enemy can move horizontally, randomize the move direction.
    if (enemyData.hMove) {
      moveDirection = getRandomDirection();
    }
  }

  @override
  void onMount() {
    super.onMount();

    final defaultPaint = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.stroke;

    // Adding a rectangular hitbox
    final hitbox = RectangleHitbox.relative(
      Vector2(0.9, 0.7),
      parentSize: size,
      position: size / 2,
      anchor: Anchor.center,
    )
      ..renderShape = true
      ..paint = defaultPaint;
    add(hitbox);

    // As current component is already rotated by pi radians,
    // the text component needs to be again rotated by pi radians
    // so that it is displayed correctly.
    _hpText.angle = pi;

    // To place the text just behind the enemy.
    _hpText.position = Vector2(40, 70);

    // Add as child of current component.
    add(_hpText);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Bullet) {
      // If the other Collidable is a Bullet,
      // reduce health by level of bullet times 10.
      _hitPoints -= other.level * 10;
      // Play sound and explosion video
      if (_hitPoints <= 0) {
        destroy();
      } else {
        hitNoDestroy();
      }
    } else if (other is Player) {
      // If the other Collidable is Player, destroy.
      destroy();
    }
  }

  // This method is triggered when enemy is hit but not destroyed
  void hitNoDestroy() {
    // Create explosion animaiton
    SpriteAnimationData explosionData = SpriteAnimationData.sequenced(
        amount: 20, stepTime: 0.01, textureSize: Vector2(64, 64));

    final explosionAnimationNo = SpriteAnimationComponent.fromFrameData(
      gameRef.images.fromCache('explosion3.png'),
      explosionData,
      removeOnFinish: true,
      anchor: Anchor.center,
      position: position,
      size: Vector2(50, 50),
    )..animation?.loop = false;

    gameRef.add(explosionAnimationNo);
  }

  // This method will destory this enemy.
  void destroy() {
    // Ask audio player to play enemy destroy effect.
    gameRef.addCommand(Command<AudioPlayerComponent>(action: (audioPlayer) {
      audioPlayer.playSfx('laser1.ogg');
    }));

    // Before dying, register a command to increase
    // player's score by 1.
    final command = Command<Player>(action: (player) {
      // Use the correct killPoint to increase player's score.
      player.addToScore(enemyData.killPoint);
    });

    gameRef.addCommand(command);

    // Create explosion animaiton 1
    SpriteAnimationData explosionData = SpriteAnimationData.sequenced(
        amount: 20, stepTime: 0.03, textureSize: Vector2(64, 64));

    final explosionAnimation = SpriteAnimationComponent.fromFrameData(
      gameRef.images.fromCache('explosion3.png'),
      explosionData,
      removeOnFinish: true,
      anchor: Anchor.center,
      position: position.clone(),
      size: Vector2(80, 80),
    )..animation?.loop = false;

    // Create explosion animaiton 2
    SpriteAnimationData explosionDataBig = SpriteAnimationData.sequenced(
        amount: 20, stepTime: 0.06, textureSize: Vector2(64, 64));

    final explosionAnimationBig = SpriteAnimationComponent.fromFrameData(
      gameRef.images.fromCache('explosion3.png'),
      explosionDataBig,
      removeOnFinish: true,
      anchor: Anchor.center,
      position:
          position.clone() + (Vector2.random(_random) - Vector2(0.5, 0.5)) * 50,
      size: Vector2(120, 120),
    )..animation?.loop = false;

    // Create explosion animaiton 3
    SpriteAnimationData explosionDataBigLate = SpriteAnimationData.sequenced(
        amount: 20, stepTime: 0.08, textureSize: Vector2(64, 64));

    final explosionAnimationBigLate = SpriteAnimationComponent.fromFrameData(
      gameRef.images.fromCache('explosion3.png'),
      explosionDataBigLate,
      removeOnFinish: true,
      anchor: Anchor.center,
      position:
          position.clone() + (Vector2.random(_random) - Vector2(0.5, 0.5)) * 60,
      size: Vector2(120, 120),
    )..animation?.loop = false;

    gameRef.add(explosionAnimation);
    gameRef.add(explosionAnimationBig);
    gameRef.add(explosionAnimationBigLate);
    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Sync-up text component and value of hitPoints.
    _hpText.text = '$_hitPoints HP';

    _freezeTimer.update(dt);

    // Update the position of this enemy using its speed and delta time.
    position += moveDirection * _speed * dt;

    // If the enemy leaves the screen, destroy it.
    if (position.y - size.y > gameRef.size.y) {
      removeFromParent();
    } else if ((position.x < size.x / 2) ||
        (position.x > (gameRef.size.x - size.x / 2))) {
      // Enemy is going outside vertical screen bounds, flip its x direction.
      moveDirection.x *= -1;
    }
  }

  // Pauses enemy for 2 seconds when called.
  void freeze() {
    _speed = 0;
    _freezeTimer.stop();
    _freezeTimer.start();
  }
}
