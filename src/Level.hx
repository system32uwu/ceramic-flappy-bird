package;

import ceramic.Group;
import ceramic.InputMap;
import ceramic.Quad;
import ceramic.Repeat;
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
	var jumpSpeed:Float = 40;
	var inputMap:InputMap<PlayerInput>;

	var pipes:Map<Int, Array<Quad>>;
	var pipesReady:Bool = false;

	var loseOnCollideWith:Group<Quad> = new Group<Quad>();

	var rand = new SeedRandom(Date.now().getTime());

	var wOffset:Float = 20;

	@observe var alive:Bool = true;

	var bg:Repeat;
	var message:Quad;
	var base:Quad;

	@observe public var firstTap:Bool = false;

	override function preload() {
		assets.add(Images.YELLOW_BIRD);
		assets.add(Images.PIPE_GREEN);
		assets.add(Images.BACKGROUND_DAY);
		assets.add(Images.GAME_OVER);
		assets.add(Images.MESSAGE);
		assets.add(Images.BASE);
	}

	override function create() {
		initArcadePhysics();
		initPipes();
		initMessage();
		initPlayer();
		bindKeys();
		initBackground();
		initBase();
	}

	function initBase() {
		base = new Quad();
		base.texture = assets.texture(Images.BASE);
		base.anchor(0.5, 0.5);
		base.pos(width / 2, height - base.height / 8);
		base.width = width;

		base.depth = -1;

		base.initArcadePhysics(arcade.world);

		loseOnCollideWith.add(base);

		add(base);
	}

	function initMessage() {
		message = new Quad();
		message.texture = assets.texture(Images.MESSAGE);
		message.anchor(0.5, 0.5);
		message.pos(width / 2, height / 2);

		message.depth = 0;

		add(message);
	}

	function initBackground() {
		bg = new Repeat();
		bg.texture = assets.texture(Images.BACKGROUND_DAY);
		bg.pos(0, 0);

		bg.width = width;
		bg.height = height;

		bg.depth = -3;

		add(bg);
	}

	function initPlayer() {
		player = new Quad();
		player.id = "player";

		player.anchor(0.5, 0.5);

		player.texture = assets.texture(Images.YELLOW_BIRD);

		player.pos((width / 2) - message.width + 10, height / 2 - player.height / 2);

		player.initArcadePhysics(arcade.world);

		player.gravity(0, 0);

		onFirstTapChange(this, (c, p) -> {
			if (c) {
				message.destroy();
				player.gravity(0, 22);
			}
		});

		onAliveChange(this, (c, p) -> {
			if (!c) {
				player.body.gravityY = 0;
				player.body.velocityY = 0;

				var gameOver = new Quad();
				gameOver.anchor(0.5, 0.5);
				gameOver.texture = assets.texture(Images.GAME_OVER);
				gameOver.pos(width / 2, height / 2);
				gameOver.depth = 10;

				add(gameOver);
			}
		});

		player.onCollideBody(this, (v1, v2) -> {
			alive = false;
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

			pipeTop.anchor(0.5, 0.5);
			pipeTop.pos((width + wOffset + pipeTop.width) - pipeTop.width / 2 + (pipeTop.width * i * 2.5), ofs.top - pipeTop.height / 2);
			pipeTop.rotation = 180;

			pipeBottom.anchor(0.5, 0.5);
			pipeBottom.rotation = 0;
			pipeBottom.pos((width + wOffset + pipeBottom.width)
				- pipeBottom.width / 2
				+ (pipeBottom.width * i * 2.5),
				height
				- ofs.bottom
				+ pipeBottom.height / 2);

			pipeBottom.id = Std.string(i);
			pipeTop.id = Std.string(i);

			pipeTop.initArcadePhysics(arcade.world);
			pipeBottom.initArcadePhysics(arcade.world);
			pipeTop.depth = -2;
			pipeBottom.depth = -2;

			pipes.set(i, [pipeTop, pipeBottom]);
			loseOnCollideWith.add(pipeTop);
			loseOnCollideWith.add(pipeBottom);

			add(pipeTop);
			add(pipeBottom);
		}
		pipesReady = true;
	}

	override function update(dt:Float) {
		if (inputMap.justPressed(PlayerInput.RESTART)) {
			// Restart the scene
			app.scenes.main = new Level();
		}

		if (pipesReady && alive) {
			updatePlayer(dt);
			if (firstTap) {
				updatePipes(dt);
			}
			arcade.world.collide(player, loseOnCollideWith);
		}

		super.update(dt);
	}

	function updatePlayer(dt:Float) {
		if (inputMap.justPressed(PlayerInput.JUMP)) {
			firstTap = true;
			player.velocityY = -player.gravityY * dt * this.jumpSpeed;
		}
		if (firstTap) {
			player.velocityY += player.gravityY * dt;
			player.y += player.velocityY * dt * ((this.jumpSpeed / 2) - 10);

			player.tween(BOUNCE_EASE_IN, 2, 1, 360, (value, time) -> {
				player.rotation = value * player.velocityY;
			});
		}

		if (player.y < -player.height) {
			alive = false;
		}
	}

	function updatePipes(dt:Float) {
		for (p in pipes) {
			p[0].x -= 110 * dt;
			p[1].x -= 110 * dt;

			if (p[0].x < (-p[0].width - wOffset)) {
				var ofs = generateRandomOffsets(p[0].height);
				p[0].pos(width + wOffset + p[0].width, ofs.top - p[0].height / 2);
				p[1].pos(width + wOffset + p[1].width, height - ofs.bottom + p[1].height / 2);
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
