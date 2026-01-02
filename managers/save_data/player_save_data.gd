class_name  PlayerSaveData extends Resource

# Weapon component
@export var bullet_left: BulletItemData
@export var bullet_right: BulletItemData
@export var throwable_left: ThrowableItemData
@export var throwable_right: ThrowableItemData
@export var assistant: AssistantItemData

# Movement Component
@export var propulsor: PropulsorItemData

# Health Component
@export var core: CoreItemData

# Leveling System
@export var player_level: int
@export var current_xp: int

@export var prev_level_up_xp: int
@export var next_level_up_xp: int

# Game Stats
@export var total_dies: int
@export var total_kills: int
