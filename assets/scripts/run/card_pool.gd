extends Resource
class_name CardPool

## Набор карточек, из которого формируются предложения после кометы.
## Учитывает max_stacks и вес. Параметр context намеренно не типизирован,
## чтобы не создавать циклическую зависимость с RunContext.

@export var cards: Array[CardDef] = []
@export_range(1, 4) var min_offers: int = 2
@export_range(1, 4) var max_offers: int = 4


func pick_offers(count: int, context: Node) -> Array[CardDef]:
	var eligible: Array[CardDef] = []
	for card in cards:
		if card == null:
			continue
		if context != null and card.max_stacks > 0:
			if int(context.get_card_count(card.id)) >= card.max_stacks:
				continue
		if card.weight <= 0.0:
			continue
		eligible.append(card)

	var result: Array[CardDef] = []
	var target := clampi(count, 0, eligible.size())
	for i in target:
		var total_weight := 0.0
		for card in eligible:
			total_weight += card.weight
		if total_weight <= 0.0:
			break

		var roll := randf() * total_weight
		var picked: CardDef = null
		for card in eligible:
			roll -= card.weight
			if roll <= 0.0:
				picked = card
				break
		if picked == null:
			picked = eligible.back()
		result.append(picked)
		eligible.erase(picked)

	return result
