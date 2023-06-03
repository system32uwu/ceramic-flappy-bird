package;

import ceramic.InputMap;
import ceramic.Quad;
import ceramic.Scene;
import ceramic.SeedRandom;

/**
 * The input keys that will make player interaction
 */
enum abstract PlayerInput(Int) {
	var JUMP;
}

class Level extends Scene {
	var player:Quad;
	var jumpSpeed:Float = 50;
	var inputMap:InputMap<PlayerInput>;

	var pipes:Map<Int, Array<Quad>>;
	var pipesReady:Bool = false;

	var rand = new SeedRandom(Date.now().getTime());

	var wOffset:Float = 20;

	override function preload() {
		assets.add(Images.YELLOW_BIRD);
		assets.add(Images.PIPE_GREEN);
	}

	override function create() {
		initPlayer();
		bindKeys();
		initPipes();
	}

	function initPlayer() {
		player = new Quad();

		player.anchor(0.5, 0.5);

		player.texture = assets.texture(Images.YELLOW_BIRD);

		player.pos(width / 2 - player.width / 2, height / 2 - player.height / 2);

		player.initArcadePhysics();
		player.gravity(0, 16);

		add(player);
	}

	function bindKeys() {
		inputMap = new InputMap<PlayerInput>();
		// Bind the space bar to the jump action
		inputMap.bindKeyCode(PlayerInput.JUMP, SPACE);
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

			pipes.set(i, [pipeTop, pipeBottom]);

			add(pipeTop);
			add(pipeBottom);
		}

		pipesReady = true;
	}

	override function update(dt:Float) {
		if (pipesReady) {
			updatePlayer(dt);
			updatePipes(dt);
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
			p[0].x -= 120 * dt;
			p[1].x -= 120 * dt;

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
