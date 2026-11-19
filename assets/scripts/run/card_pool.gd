extends Resource
class_name CardPool

## Набор карточек, из которого формируются предложения.
## Учитывает max_stacks, разблокировку и контекстный вес:
## чем больше стаков уже взято, тем реже карточка предлагается снова.

@export var cards: Array[CardDef] = []
## Отдельный пул для комет. Если пуст — комета использует обычный пул.
@export var comet_cards: Array[CardDef] = []
@export_range(1, 4) var min_offers: int = 2
@export_range(1, 4) var max_offers: int = 4


func pick_offers(count: int, context: Node, source: StringName = &"normal") -> Array[CardDef]:
	var source_cards := _cards_for_source(source)
	var eligible: Array[CardDef] = []
	for card in source_cards:
		if card == null:
			continue
		if context != null and card.max_stacks > 0:
			if int(context.get_card_count(card.id)) >= card.max_stacks:
				continue
		if not card.unlocked_by_default and not GameState.is_card_unlocked(card.id):
			continue
		if _effective_weight(card, context) <= 0.0:
			continue
		eligible.append(card)

	var result: Array[CardDef] = []
	var target := clampi(count, 0, eligible.size())
	for i in target:
		var picked := _pick_weighted(eligible, context)
		if picked == null:
			break
		result.append(picked)
		eligible.erase(picked)

	_guarantee_new_card(result, eligible, context)
	return result


func _cards_for_source(source: StringName) -> Array[CardDef]:
	if source == &"comet" and not comet_cards.is_empty():
		return comet_cards
	return cards


func _effective_weight(card: CardDef, context: Node) -> float:
	if card.weight <= 0.0:
		return 0.0
	if context == null:
		return card.weight
	var count := int(context.get_card_count(card.id))
	if count <= 0:
		return card.weight
	return card.weight * pow(card.repeat_falloff, float(count))


func _pick_weighted(eligible: Array[CardDef], context: Node) -> CardDef:
	var total_weight := 0.0
	for card in eligible:
		total_weight += _effective_weight(card, context)
	if total_weight <= 0.0:
		return null

	var roll := randf() * total_weight
	for card in eligible:
		roll -= _effective_weight(card, context)
		if roll <= 0.0:
			return card
	return eligible.back()


## Если в наборе нет ни одной новой карточки, но новые ещё есть в пуле,
## заменяем последнюю карточку на новую. Так игрок не застревает на повторах.
func _guarantee_new_card(result: Array[CardDef], remaining: Array[CardDef], context: Node) -> void:
	if result.is_empty() or context == null:
		return
	for card in result:
		if int(context.get_card_count(card.id)) == 0:
			return

	for card in remaining:
		if int(context.get_card_count(card.id)) == 0:
			result[result.size() - 1] = card
			return
