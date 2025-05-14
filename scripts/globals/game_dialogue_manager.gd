extends Node

signal give_crop_seeds
signal feed_the_animals
signal exchange_items(give_item: String, give_amount: int, reward_item: String, reward_amount: int)

func action_exchange_items(give_item: String, give_amount: int, reward_item: String, reward_amount: int) -> void:
	emit_signal("exchange_items", give_item, give_amount, reward_item, reward_amount)

func action_give_crop_seeds() -> void:
	give_crop_seeds.emit()

func action_feed_animals() -> void:
	feed_the_animals.emit()
