class_name Observable extends RefCounted

## Se dispara cada vez que cambia el valor del observable, y tambien en la inicializacion del mismo. El valor que obtiene por parametro es el nuevo valor que adquiere el observable
signal changed(value)

var value: Variant:
	set(_value):
		value = _value
		changed.emit(_value)
		if _extra_setter.is_valid():
			_extra_setter.call(_value)

var _extra_setter := Callable()

## Crea e inicializa el observable con un valor por defecto, y opcionalmente una funcion que se llamara cada vez que el valor cambie. Establecer esta funcion hace en la práctica lo mismo que conectar la señal changed, pero más rápido
func _init(_value, __extra_setter := Callable()):
	value = _value
	_extra_setter = __extra_setter
	changed.emit(value)


## Atajo para changed.connect
func conectar(callable: Callable):
	changed.connect(callable)


## Conectar la señal de cambio a una función y luego llamar a la función por primera vez. Útil para inicializar valores
func connect_init(callable: Callable):
	changed.connect(callable)
	callable.call(value)
