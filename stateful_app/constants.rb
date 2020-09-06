PLAYER_SPRITE_SHEET_PATH = 'sprites/player/sheet.png'
PLAYER_SPRITE_W = 64
PLAYER_SPRITE_H = 128
PLAYER_SPEED_LIMIT = 5.0
PLAYER_ACCEL = 0.5
PLAYER_FRICTION = 0.85
BULLET_SPRITE_PATH = 'sprites/bullets/standard.png'
BULLET_SPRITE_SIZE = 32
BULLET_SPEED = 8.0
BULLET_COOLDOWN = 12
BULLET_MOMENTUM = 0.66   # shooter_vel * BULLET_MOMENTUM + base_bullet_vel = bullet_vel (kinda)
BULLET_DESPAWN_RANGE = 50
BULLET_VISUAL_ANGLE_SNAP = 10
TRACING_ENABLED = false

PLAYER_SPRITES = {
    body: {
        down: 'sprites/player/body_y.png',
        up: 'sprites/player/body_y.png',
        left: 'sprites/player/body_left.png',
        right: 'sprites/player/body_right.png',
    },
    face: {
        down: 'sprites/player/face_down.png',
        up: 'sprites/player/face_up.png',
        left: 'sprites/player/face_left.png',
        right: 'sprites/player/face_right.png'
    },
    head: {
        down: 'sprites/player/head_down.png',
        up: 'sprites/player/head_up.png',
        left: 'sprites/player/head_left.png',
        right: 'sprites/player/head_right.png'
    }
}

ROOM_SPRITES = {
    E: {
        E: 'sprites/rooms/e.png',
        N: {
            N: 'sprites/rooms/en.png',
            S: {
                S: 'sprites/rooms/ens.png',
                W: {
                    W: 'sprites/rooms/ensw.png',
                }
            },
            W: {
                W: 'sprites/rooms/enw.png',
            },
        },
        S: {
            S: 'sprites/rooms/es.png',
            W: {
                W: 'sprites/rooms/esw.png',
            }
        },
        W: {
            W: 'sprites/rooms/ew.png',
        }
    },
    N: {
        N: 'sprites/rooms/n.png',
        S: {
            S: 'sprites/rooms/ns.png',
            W: {
                W: 'sprites/rooms/nsw.png',
            }
        },
        W: {
            W: 'sprites/rooms/nw.png',
        },
    },
    S: {
        S: 'sprites/rooms/s.png',
        W: {
            W: 'sprites/rooms/sw.png',
        }
    },
    W: {
        W: 'sprites/rooms/w.png',
    }

}