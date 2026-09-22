class_name Observable extends RefCounted

## Se dispara cada vez que cambia el valor del observable, y tambien en la inicializacion del mismo. El valor que obtiene por parametro es el nuevo valor que adquiere el observable
signal changed(value)

var value: Variant:
	set(_value):
		# Si el juego se rompe en las pruebas a partir de ahora, ya se que es esto
		if value != _value:
			var continuar = true
			if _extra_setter_before.is_valid():
				continuar = _extra_setter_before.call(_value, value)
			if continuar:
				value = _value
				changed.emit(_value)
				if _extra_setter_after.is_valid():
					_extra_setter_after.call(_value, value)

## Estos setters estan pensados para que el objeto que es dueño de la propiedad pueda personalizar lo que ocurre cuando esta es cambiada (como las funciones set y get de las propiedades normales, no observables). Se definen al inicializar el Observable, y se ejecutan antes y despues de que la variable sea seteada y la señal de cambio emitida, respectivamente. _extra_setter_before tambien puede devolver un valor true o false, impidiendo que la variable se setee si devuelve false
var _extra_setter_after: Callable = Callable()
var _extra_setter_before: Callable = Callable()

## Crea e inicializa el observable con un valor por defecto, y opcionalmente una funcion que se llamara cada vez que el valor cambie. Establecer esta funcion hace en la práctica lo mismo que conectar la señal changed, pero más rápido
func _init(initial_value, after_setter := Callable(), before_setter := Callable()):
	value = initial_value
	_extra_setter_after = after_setter
	_extra_setter_before = before_setter # esto es una mausquerramienta sorpresa que nos ayudara mas tarde
	changed.emit(value)


## Atajo para changed.connect
func conectar(callable: Callable):
	changed.connect(callable)


## Conectar la señal de cambio a una función y luego llamar a la función por primera vez. Útil para inicializar valores
func connect_init(callable: Callable):
	changed.connect(callable)
	callable.call(value)
