@abstract class_name EquippableItemData
extends ItemData

## Which type of equippable
## I used location name
enum Type {
	ASSISTANT, ## Bots that can be summoned to assist you
	CORE, ## For Healthy (Integrity)
	BULLET, ## Like, A Gun; Action
	THROWABLE, ## Landmine, or grenade
	PROPULSOR, ## A Wheel or a hover; Movement
}

var type: Type
