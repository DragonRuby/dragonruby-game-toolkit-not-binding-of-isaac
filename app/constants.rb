PLAYER_SPRITE_SHEET_PATH = 'sprites/player_sheet.png'
PLAYER_SPRITE_W = 64
PLAYER_SPRITE_H = 128
PLAYER_SPEED_LIMIT = 5.0
PLAYER_ACCEL = 0.5
PLAYER_FRICTION = 0.85
BULLET_SPRITE_PATH = 'sprites/bullet.png'
BULLET_SPRITE_SIZE = 32
BULLET_SPEED = 8.0
BULLET_COOLDOWN = 12
BULLET_MOMENTUM = 0.66   # shooter_vel * BULLET_MOMENTUM + base_bullet_vel = bullet_vel (kinda)
BULLET_DESPAWN_RANGE = 50
BULLET_VISUAL_ANGLE_SNAP = 10
TRACING_ENABLED = false

PLAYER_SPRITES = {
    body: {
        down: 'sprites/player_body_y.png',
        up: 'sprites/player_body_y.png',
        left: 'sprites/player_body_left.png',
        right: 'sprites/player_body_right.png',
    },
    face: {
        down: 'sprites/player_face_down.png',
        up: 'sprites/player_face_up.png',
        left: 'sprites/player_face_left.png',
        right: 'sprites/player_face_right.png'
    },
    head: {
        down: 'sprites/player_head_down.png',
        up: 'sprites/player_head_up.png',
        left: 'sprites/player_head_left.png',
        right: 'sprites/player_head_right.png'
    }
}
