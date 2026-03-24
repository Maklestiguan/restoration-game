class_name Format
## Утилита форматирования чисел для инкрементальной игры.
##
## GDScript float = 64-bit IEEE 754 double:
##   - Диапазон: до ~1.8e308 (больше чем достаточно)
##   - Точность: 15-17 значащих цифр
##   - При $1 триллион теряются центы, но для idle-игры это не важно
##   - Никакой специальной математики не нужно — float64 покрывает всё

## Суффиксы для больших чисел (стандарт для инкрементальных игр)
const SUFFIXES := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc",
	"UDc", "DDc", "TDc", "QaDc", "QiDc", "SxDc", "SpDc", "OcDc", "NoDc", "Vg"]


## Короткий формат: полное число до 1M, потом сокращённое.
## "$999,999" -> "$1.00M" -> "$1.50B" -> "$2.34T"
static func money(value: float) -> String:
	if value < 1000000:
		return comma(int(value))
	return short(value)


## Полное число с разделителями тысяч: "1,234,567"
static func comma(value: int) -> String:
	var negative := value < 0
	if negative:
		value = -value
	var s := str(value)
	var result := ""
	var len := s.length()
	for i in len:
		if i > 0 and (len - i) % 3 == 0:
			result += ","
		result += s[i]
	if negative:
		return "-" + result
	return result


## Полное число с разделителями (для float)
static func comma_f(value: float) -> String:
	return comma(int(value))


## Сокращённый формат с суффиксом: "1.50M", "2.34T"
static func short(value: float) -> String:
	if value < 1000:
		return str(int(value))

	var tier := 0
	var reduced := value
	while reduced >= 1000 and tier < SUFFIXES.size() - 1:
		reduced /= 1000.0
		tier += 1

	if reduced >= 100:
		return "%d%s" % [int(reduced), SUFFIXES[tier]]
	elif reduced >= 10:
		return "%.1f%s" % [reduced, SUFFIXES[tier]]
	else:
		return "%.2f%s" % [reduced, SUFFIXES[tier]]


## Полная строка для тултипа: "$1,234,567,890"
static func full(value: float) -> String:
	return "$%s" % comma(int(value))
