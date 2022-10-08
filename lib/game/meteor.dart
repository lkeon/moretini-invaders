// This class represents a meteor component
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'game.dart';
import 'knows_game_size.dart';
import 'player.dart';

import 'audio_player_component.dart';
import 'bullet.dart';
import 'command.dart';

class Meteor extends SpriteComponent
    with KnowsGameSize, CollisionCallbacks, HasGameRef<MoretiniInvaders> {
  // Speed of meteor
  double speed = 250;

  // Speed that is resetted to after timer
  late double _speedReset;

  // Rotation of meteor (rad/s)
  late double _rotation;

  // Move direction
  late Vector2 _direction;

  // Controls for how long enemy should be freezed.
  late Timer _freezeTimer;

  // Hold random class to generate random numbers
  final _random = Random();

  // Returns a random direction vector with slight angle to +ve y axis.
  Vector2 getRandomDirection() {
    return Vector2(_random.nextDouble() - 0.5, 2 * _random.nextDouble())
        .normalized();
  }

  // Object constructor
  Meteor({
    required Sprite? sprite,
    required Vector2? size,
    required Vector2? position,
    required double speed,
  }) : super(sprite: sprite, position: position, size: size) {
    // Set speed that doesn't change after pause
    _speedReset = speed;

    // Sets freeze time to 2 seconds. After 2 seconds speed will be reset.
    _freezeTimer = Timer(2, onTick: () {
      speed = _speedReset;
    });

    // Set direction of moving
    _direction = getRandomDirection();

    // Set rotation speed
    _rotation = 1 * (_random.nextDouble() - 0.5);
  }

  @override
  void onMount() {
    super.onMount();

    final defaultPaint = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.stroke;

    // Adding a rectangular hitbox
    final hitbox = CircleHitbox.relative(
      0.95,
      parentSize: size,
      position: size / 2,
      anchor: Anchor.center,
    )
      ..renderShape = true
      ..paint = defaultPaint;
    add(hitbox);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Bullet || other is Player) {
      destroy();
    }
  }

  void destroy() {
    // Ask audio player to play enemy destroy effect.
    gameRef.addCommand(Command<AudioPlayerComponent>(action: (audioPlayer) {
      audioPlayer.playSfx('laser1.ogg');
    }));

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

    gameRef.add(explosionAnimation);
    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _freezeTimer.update(dt);

    // Update position of meteor
    position += _direction * speed * dt;

    // Update rotation of the meteor
    angle = (angle + _rotation * dt) % (2 * pi);

    // Remove meteor if off screen
    if ((position.y - size.y > gameRef.size.y) ||
        (position.x + size.x < 0) ||
        (position.x - size.x > gameRef.size.x)) {
      removeFromParent();
    }
  }

  // Pauses enemy for 2 seconds when called.
  void freeze() {
    speed = 0;
    _freezeTimer.stop();
    _freezeTimer.start();
  }
}
