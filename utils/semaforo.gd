class_name SignalSemaphore extends RefCounted

#var _valor = 0
var _signals : Array[Signal]

#func _adquirir():
	#_valor += 1

func _reducir(...args):
	var sig : Signal = args[-1]
	_signals.erase(sig)
	#_valor -= 1

func _conectar_signal(sig: Signal):
	if not sig.is_connected(_reducir):
		sig.connect(_reducir.bind(sig), CONNECT_ONE_SHOT)
		_signals.append(sig)


func disponible() -> bool:
	#_signals.size()
	return _signals.is_empty() # _valor == 0

func adquirir_signal(sig: Signal):
	#_adquirir()
	_conectar_signal(sig)

func adquirir_timer(timer: Timer):
	#_adquirir()
	_conectar_signal(timer.timeout)

func liberar():
	#_valor = 0
	for sig in _signals:
		sig.disconnect(_reducir)
	_signals.clear()
