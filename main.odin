package fluid_sim

import rl "vendor:raylib"
import "core:math"

WIDTH :: 800
HEIGHT :: 600

PARTICLE_PRESSURE_RADIUS :: 20
PARTICLE_VISCOSITY_RADIUS :: 20
PARTICLE_PRESSURE :: 100
PARTICLE_VISCOSITY :: 50
PARTICLE_COLLISION_FORCE :: 100

PARTICLE_DRAW_RADIUS :: 3
PARTICLE_COLOR :: rl.BLUE

GRAVITY :: rl.Vector2{ 0, 300 }

PARTICLE_COUNT :: 1000

Particle :: struct {
    position : rl.Vector2,
    velocity : rl.Vector2,
    acceleration : rl.Vector2,
}

Particle_ptr :: #soa ^#soa[PARTICLE_COUNT]Particle

particle_add_force :: proc(p : ^Particle, force : rl.Vector2) {
    p.acceleration += force
}

particle_collide_boundary :: proc(p : ^Particle, boundary : rl.Rectangle) {
    if p.position.x < boundary.x {
        p.position.x = boundary.x
        p.velocity.x = 0
    } else if p.position.x > boundary.x + boundary.width {
        p.position.x = boundary.x + boundary.width
        p.velocity.x = 0
    }
    if p.position.y < boundary.y {
        p.position.y = boundary.y
        p.velocity.y = 0
    } else if p.position.y > boundary.y + boundary.height {
        p.position.y = boundary.y + boundary.height
        p.velocity.y = 0
    }
}

particle_boundary_force :: proc(p : ^Particle, boundary : rl.Rectangle) {
    PARTICLE_ENERGY_LOSS :: 1
    force := rl.Vector2(0)
    if p.position.x - PARTICLE_PRESSURE_RADIUS < boundary.x {
        force.x = (boundary.x - (p.position.x - PARTICLE_PRESSURE_RADIUS))
    } else if p.position.x + PARTICLE_PRESSURE_RADIUS > boundary.x + boundary.width {
        force.x = (boundary.x + boundary.width) - (p.position.x + PARTICLE_PRESSURE_RADIUS)
    } 
    if p.position.y - PARTICLE_PRESSURE_RADIUS < boundary.y {
        force.y = boundary.y - (p.position.y - PARTICLE_PRESSURE_RADIUS)
    } else if p.position.y + PARTICLE_PRESSURE_RADIUS > boundary.y + boundary.height {
        force.y = (boundary.y + boundary.height) - (p.position.y + PARTICLE_PRESSURE_RADIUS)
    }
    if force != 0 {
        p.velocity *= PARTICLE_ENERGY_LOSS
    }
    particle_add_force(p, force * PARTICLE_COLLISION_FORCE)
}

particle_force_particle :: proc(p : ^Particle, other: ^Particle) {
    kernal_poly6 :: proc(dist, h: f32) -> f32 {
        return 315 / (64 * math.PI * math.pow(h, 9)) * math.pow(h*h - dist*dist, 3)
    }
    kernal_sin :: proc(dist, h: f32) -> f32 {
        return math.sin(((h - dist)/h - 0.5)*(math.PI/2))/2 + 0.5
    }
    kernal_linear :: proc(dist, h: f32) -> f32 {
        return (h - dist)/h
    }
    kernal : proc(dist, h: f32) -> f32 : kernal_linear
    PARTICLE_ENERGY_LOSS :: 1
    dist := rl.Vector2Distance(p.position, other.position)
    if dist < PARTICLE_PRESSURE_RADIUS {
        p.velocity *= PARTICLE_ENERGY_LOSS
        other.velocity *= PARTICLE_ENERGY_LOSS
    }
    h : f32 = PARTICLE_PRESSURE_RADIUS*2
    if dist < h {
        w := kernal(dist, h)
        particle_add_force(p, rl.Vector2Normalize(p.position - other.position) * w * PARTICLE_PRESSURE)
        particle_add_force(other, rl.Vector2Normalize(other.position - p.position) * w * PARTICLE_PRESSURE)
    }
    h = PARTICLE_VISCOSITY_RADIUS*2
    if dist < h {
        w := kernal(dist, h)
        p_force := rl.Vector2Normalize((other.position + other.velocity) - (p.position + p.velocity))
        other_force := rl.Vector2Normalize((p.position + p.velocity) - (other.position + other.velocity))
        particle_add_force(p, p_force * w * PARTICLE_VISCOSITY)
        particle_add_force(other, other_force * w * PARTICLE_VISCOSITY)
    }
}

particle_update :: proc(p : ^Particle, dt : f32) {
    p.velocity += p.acceleration * dt
    p.position += p.velocity * dt
    p.acceleration = GRAVITY
}

particle_apply_forces :: proc(p : ^Particle, others : []Particle) {
    for &other in others {
        if p^ == other { continue }
        particle_force_particle(p, &other)
    }
}

main :: proc() {
    particles : [PARTICLE_COUNT]Particle
    
    for _, i in particles {
        GRID_WIDTH :: PARTICLE_COUNT*0.01
        x := i % (GRID_WIDTH) + 1
        y := i/(GRID_WIDTH) + 1
        PAD :: 5
        particles[i] = Particle{
            position = { f32(x * (PARTICLE_PRESSURE_RADIUS*2 + PAD) + (y%2)*PARTICLE_PRESSURE_RADIUS), HEIGHT - f32(y) * (PARTICLE_PRESSURE_RADIUS*2 + PAD)},
            // position = { f32(x * (PARTICLE_PRESSURE_RADIUS*2 + PAD)), HEIGHT - f32(y) * (PARTICLE_PRESSURE_RADIUS*2 + PAD)},
            velocity = { 0, 0 }
        }
    }

    rl.InitWindow(WIDTH, HEIGHT, "Particle Fluid Sim")
    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()

        for &p in particles {
            mouse := rl.GetMousePosition()
            if rl.Vector2Distance(mouse, p.position) < 100 {
                force : rl.Vector2
                switch {
                    case rl.IsMouseButtonDown(.LEFT):  force = mouse - p.position
                    case rl.IsMouseButtonDown(.RIGHT): force = p.position - mouse
                }
                particle_add_force(&p, force * 20)
            }
            particle_apply_forces(&p, particles[:])
        }
        BOUNDARY_HEIGHT :: 5
        for &p in particles {
            particle_update(&p, dt)
        }
        for &p in particles {
            particle_collide_boundary(&p, { 0, -HEIGHT * BOUNDARY_HEIGHT, WIDTH, HEIGHT * (BOUNDARY_HEIGHT+1) })
            particle_boundary_force(&p, { 0, -HEIGHT * BOUNDARY_HEIGHT, WIDTH, HEIGHT * (BOUNDARY_HEIGHT+1) })
        }
        rl.BeginDrawing()
        rl.ClearBackground(rl.Color{ 0x18, 0x18, 0x18, 0xFF })

        for particle in particles {
            rl.DrawCircleV(particle.position, PARTICLE_PRESSURE_RADIUS, rl.ColorAlpha(PARTICLE_COLOR, 0.05))
            rl.DrawCircleV(particle.position, PARTICLE_DRAW_RADIUS, PARTICLE_COLOR)
        }

        rl.DrawFPS(10, 10)

        rl.EndDrawing()
    }
}
