.pragma library

function create() {
    return { phase: "idle", height: 0, velocity: 0, distance: 0, score: 0,
        speed: 86, obstacles: [], nextSpawn: 15 };
}

function start(world) { world.phase = "running"; }
function jump(world) {
    if (world.phase !== "running" || world.height > 0) return false;
    world.velocity = 215;
    return true;
}
function pause(world) { if (world.phase === "running") world.phase = "paused"; }
function resume(world) { if (world.phase === "paused") world.phase = "running"; }

function collide(world, obstacle) {
    // Inset hitboxes forgive the sprite's empty corners and small tail.
    return 27 < obstacle.x + obstacle.width - 2 && 43 > obstacle.x + 2
        && world.height + 3 < obstacle.height && world.height + 26 > 0;
}

function advance(world, seconds, random) {
    if (world.phase !== "running") return;
    random = random || Math.random;
    // Fixed substeps prevent tunneling through narrow cacti after a delayed frame.
    let remaining = Math.max(0, Math.min(seconds, 0.1));
    while (remaining > 0 && world.phase === "running") {
        const dt = Math.min(remaining, 1 / 120);
        remaining -= dt;
        world.speed = Math.min(155, 86 + world.distance / 180);
        const travel = world.speed * dt;
        world.distance += travel;
        world.score = Math.floor(world.distance / 7);
        world.height += world.velocity * dt;
        world.velocity -= 540 * dt;
        if (world.height <= 0) { world.height = 0; world.velocity = 0; }
        world.nextSpawn -= travel;
        if (world.nextSpawn <= 0) {
            world.obstacles.push({x: 248, width: random() < 0.5 ? 10 : 17,
                height: 17 + Math.floor(random() * 10)});
            // Every gap allows a full jump and landing, including at maximum speed.
            world.nextSpawn = world.speed * 1.2 + 35 + random() * 55;
        }
        for (let i = 0; i < world.obstacles.length; i++) {
            world.obstacles[i].x -= travel;
            if (collide(world, world.obstacles[i])) world.phase = "over";
        }
        world.obstacles = world.obstacles.filter(function(o) { return o.x + o.width > -2; });
    }
}
