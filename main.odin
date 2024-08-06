package fluid_sim

import rl "vendor:raylib"
import "core:math"

WIDTH :: 800
HEIGHT :: 600

PARTICLE_FORCE_RADIUS :: 12
PARTICLE_PRESSURE :: 100
PARTICLE_VISCOSITY :: 20
PARTICLE_COLLISION_FORCE :: 150

PARTICLE_DRAW_RADIUS :: 3
PARTICLE_COLOR :: rl.BLUE

GRAVITY :: rl.Vector2{ 0, 300 }

Particle :: struct {
    position : rl.Vector2,
    velocity : rl.Vector2,
    acceleration : rl.Vector2,
}

particle_add_force :: proc(using p : ^Particle, force : rl.Vector2) {
    acceleration += force
}

particle_collide_boundary :: proc(using p : ^Particle, boundary : rl.Rectangle) {
    if position.x < boundary.x {
        position.x = boundary.x
        velocity.x = 0
    } else if position.x > boundary.x + boundary.width {
        position.x = boundary.x + boundary.width
        velocity.x = 0
    }
    if position.y < boundary.y {
        position.y = boundary.y
        velocity.y = 0
    } else if position.y > boundary.y + boundary.height {
        position.y = boundary.y + boundary.height
        velocity.y = 0
    }
}

particle_boundary_force :: proc(using p : ^Particle, boundary : rl.Rectangle) {
    force := rl.Vector2(0)
    if position.x - PARTICLE_FORCE_RADIUS < boundary.x {
        force.x = (boundary.x - (position.x - PARTICLE_FORCE_RADIUS))
    } else if position.x + PARTICLE_FORCE_RADIUS > boundary.x + boundary.width {
        force.x = (boundary.x + boundary.width) - (position.x + PARTICLE_FORCE_RADIUS)
    } 
    if position.y - PARTICLE_FORCE_RADIUS < boundary.y {
        force.y = boundary.y - (position.y - PARTICLE_FORCE_RADIUS)
    } else if position.y + PARTICLE_FORCE_RADIUS > boundary.y + boundary.height {
        force.y = (boundary.y + boundary.height) - (position.y + PARTICLE_FORCE_RADIUS)
    }
    particle_add_force(p, force * PARTICLE_COLLISION_FORCE)
}

particle_force_particle :: proc(using p : ^Particle, other: ^Particle) {
    PARTICLE_ENERGY_LOSS :: 1 //0.99
    dist := rl.Vector2Distance(position, other.position)
    if dist < PARTICLE_FORCE_RADIUS {
        velocity *= PARTICLE_ENERGY_LOSS
        other.velocity *= PARTICLE_ENERGY_LOSS
    }
    h : f32 = PARTICLE_FORCE_RADIUS*2
    if dist < h {
        w := (h - dist)
        // w = math.pow(w/h, 2)*h
        // w = math.sqrt(w/h)*h
        particle_add_force(p, rl.Vector2Normalize(position - other.position) * w * PARTICLE_PRESSURE)
        particle_add_force(other, rl.Vector2Normalize(other.position - position) * w * PARTICLE_PRESSURE)
        particle_add_force(p, rl.Vector2Normalize(other.velocity - velocity) * w * PARTICLE_VISCOSITY)
        particle_add_force(other, rl.Vector2Normalize(velocity - other.velocity) * w * PARTICLE_VISCOSITY)
    }
}

particle_update :: proc(using p : ^Particle, dt : f32) {
    velocity += acceleration * dt
    position += velocity * dt
    acceleration = GRAVITY
}

particle_apply_forces :: proc(using p : ^Particle, others : ^[$N]Particle) {
    for _, i in others {
        other := &others[i]
        if p^ == other^ { continue }
        particle_force_particle(p, other)
    }
}

main :: proc() {
    PARTICLE_COUNT :: 500
    particles : [PARTICLE_COUNT]Particle
    
    for _, i in particles {
        GRID_WIDTH :: PARTICLE_COUNT*0.01
        x := i % (GRID_WIDTH) + 1
        y := i/(GRID_WIDTH) + 1
        PAD :: 5
        particles[i] = Particle{
            position = { f32(x * (PARTICLE_FORCE_RADIUS*2 + PAD) + (y%2)*PARTICLE_FORCE_RADIUS), HEIGHT - f32(y) * (PARTICLE_FORCE_RADIUS*2 + PAD)},
            velocity = { 0, 0 }
        }
    }

    rl.InitWindow(WIDTH, HEIGHT, "Particle Fluid Sim")
    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()

        for _, i in particles {
            p := &particles[i]
            mouse := rl.GetMousePosition()
            if rl.Vector2Distance(mouse, p.position) < 100 {
                force : rl.Vector2
                switch {
                    case rl.IsMouseButtonDown(.LEFT):  force = mouse - p.position
                    case rl.IsMouseButtonDown(.RIGHT): force = p.position - mouse
                }
                particle_add_force(p, force * 20)
            }
            BOUNDARY_HEIGHT :: 5
            particle_apply_forces(p, &particles)
            particle_update(p, dt)
            particle_collide_boundary(p, { 0, -HEIGHT * BOUNDARY_HEIGHT, WIDTH, HEIGHT * (BOUNDARY_HEIGHT+1) })
            particle_boundary_force(p, { 0, -HEIGHT * BOUNDARY_HEIGHT, WIDTH, HEIGHT * (BOUNDARY_HEIGHT+1) })
        }
        // for _, i in particles {
        //     particle := &particles[i]
        // }

        rl.BeginDrawing()
        rl.ClearBackground(rl.Color{ 0x18, 0x18, 0x18, 0xFF })

        for particle in particles {
            rl.DrawCircleV(particle.position, PARTICLE_FORCE_RADIUS, rl.ColorAlpha(PARTICLE_COLOR, 0.1))
            rl.DrawCircleV(particle.position, PARTICLE_DRAW_RADIUS, PARTICLE_COLOR)
        }

        rl.DrawFPS(10, 10)

        rl.EndDrawing()
    }
}
