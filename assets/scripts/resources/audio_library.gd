extends Resource
class_name AudioLibrary

## Ключ -> AudioStream. Значением может быть как одиночный поток, так и
## AudioStreamRandomizer с вариантами и рандомным питчем/громкостью.
@export var sounds: Dictionary[String, AudioStream] = {}


func get_stream(key: StringName) -> AudioStream:
    return sounds.get(String(key))
