package;

import ceramic.Color;
import ceramic.Group;
import ceramic.InputMap;
import ceramic.Quad;
import ceramic.Scene;
import ceramic.SeedRandom;

/**
 * The input keys that will make player interaction
 */
enum abstract PlayerInput(Int) {
	var JUMP;
	var RESTART;
}

class Level extends Scene {
	var player:Quad;
	var jumpSpeed:Float = 50;
	var inputMap:InputMap<PlayerInput>;

	var pipes:Map<Int, Array<Quad>>;
	var pipesReady:Bool = false;

	var pipesGroup:Group<Quad> = new Group<Quad>();

	var rand = new SeedRandom(Date.now().getTime());

	var wOffset:Float = 20;

	var alive:Bool = true;

	override function preload() {
		assets.add(Images.YELLOW_BIRD);
		assets.add(Images.PIPE_GREEN);
	}

	override function create() {
		initArcadePhysics();
		initPlayer();
		bindKeys();
		initPipes();
	}

	function initPlayer() {
		player = new Quad();
		player.id = "player";

		player.anchor(0.5, 0.5);

		player.texture = assets.texture(Images.YELLOW_BIRD);

		player.pos(width / 2 - player.width / 2, height / 2 - player.height / 2);

		player.initArcadePhysics(arcade.world);
		player.gravity(0, 16);
		player.body.setCircle(player.width / 2);

		player.onCollide(this, (v1, v2) -> {
			alive = false;

			player.body.gravityY = 0;
			player.body.velocityY = 0;

			// draw a quad for the colliding body
			var quad2 = new Quad();
			quad2.color = Color.RED;
			quad2.anchor(v2.anchorX, v2.anchorY);
			quad2.rotation = v2.body.rotation;
			quad2.size(v2.body.width, v2.body.height);
			quad2.pos(v2.body.x, v2.body.y);

			// draw a quad for the player
			var quad1 = new Quad();
			quad1.color = Color.RED;
			quad1.anchor(v1.anchorX, v1.anchorY);
			quad1.rotation = v1.rotation;
			quad1.size(v1.width, v1.height);
			quad1.pos(v1.x, v1.y);

			add(quad1);
			add(quad2);
		});

		add(player);
	}

	function bindKeys() {
		inputMap = new InputMap<PlayerInput>();
		// Bind the space bar to the jump action
		inputMap.bindKeyCode(PlayerInput.JUMP, SPACE);
		// Bind the R key to the restart action
		inputMap.bindKeyCode(PlayerInput.RESTART, KEY_R);
	}

	function initPipes() {
		pipes = new Map<Int, Array<Quad>>();

		for (i in 0...6) {
			var pipeTop:Quad = new Quad();
			pipeTop.texture = assets.texture(Images.PIPE_GREEN);

			var pipeBottom:Quad = new Quad();
			pipeBottom.texture = assets.texture(Images.PIPE_GREEN);

			var ofs = generateRandomOffsets(pipeTop.height);

			pipeTop.anchor(0, 0);
			pipeTop.rotation = 180;
			pipeTop.pos(width + wOffset + pipeTop.width + (pipeTop.width * i * 2.5), ofs.top);

			pipeBottom.anchor(1, 0);
			pipeBottom.rotation = 0;
			pipeBottom.pos(width + wOffset + pipeBottom.width + (pipeBottom.width * i * 2.5), height - ofs.bottom);

			pipeBottom.id = Std.string(i);
			pipeTop.id = Std.string(i);

			pipeTop.initArcadePhysics(arcade.world);
			pipeBottom.initArcadePhysics(arcade.world);

			pipes.set(i, [pipeTop, pipeBottom]);
			pipesGroup.add(pipeTop);
			pipesGroup.add(pipeBottom);

			add(pipeTop);
			add(pipeBottom);
		}
		pipesReady = true;
	}

	override function update(dt:Float) {
		if (inputMap.justPressed(PlayerInput.RESTART)) {
			// Restart the scene
			app.scenes.main = new Level();

			player.destroy();
			pipesGroup.destroy();
			destroy();
		}

		if (pipesReady && alive) {
			updatePlayer(dt);
			updatePipes(dt);
			arcade.world.collide(player, pipesGroup);
		}

		super.update(dt);
	}

	function updatePlayer(dt:Float) {
		if (inputMap.justPressed(PlayerInput.JUMP)) {
			player.velocityY = -player.gravityY * dt * this.jumpSpeed;
		}
		player.velocityY += player.gravityY * dt;
		player.y += player.velocityY * dt * ((this.jumpSpeed / 2) - 10);

		player.tween(BOUNCE_EASE_IN, 2, 1, 360, (value, time) -> {
			player.rotation = value * player.velocityY;
		});
	}

	function updatePipes(dt:Float) {
		for (p in pipes) {
			p[0].x -= 110 * dt;
			p[1].x -= 110 * dt;

			if (p[0].x < (-p[0].width - wOffset)) {
				var ofs = generateRandomOffsets(p[0].height);
				p[0].pos(width + wOffset + p[0].width, ofs.top);
				p[1].pos(width + wOffset + p[1].width, height - ofs.bottom);
			}
		}
	}

	function generateRandomOffsets(_height:Float) {
		var randomOffset = rand.between(Math.floor(_height / 4), Math.floor(_height / 2));

		var randomOffsetBottom = randomOffset;
		var randomOffsetTop = randomOffset;

		if (randomOffset > 50) {
			var which = rand.between(0, 2);
			if (which == 0) {
				randomOffsetBottom = 100;
				randomOffsetTop = randomOffset + 100;
			} else {
				randomOffsetBottom = randomOffset + 100;
				randomOffsetTop = 100;
			}
		}

		return {
			top: randomOffsetTop,
			bottom: randomOffsetBottom
		}
	}
}
