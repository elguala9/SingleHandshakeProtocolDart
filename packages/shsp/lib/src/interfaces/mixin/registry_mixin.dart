
abstract interface class IValueForRegistry {
  /// will be called normally
  void destroy();
}

/// Contenitore per un valore associato a una versione.
/// La versione viene preservata attraverso gli aggiornamenti del valore nel registry.
class ValueWithVersion<Value> {
  final Value value;
  final int version;

  ValueWithVersion(this.value, this.version);
}

mixin Registry<Key, Value extends IValueForRegistry>{
  final Map<Key, ValueWithVersion<Value>> _registry = {};

  /// Registra un elemento nel mapping, preservando la versione se già presente.
  /// Se l'elemento non esiste, viene inizializzato con versione 0.
  void register(Key key, Value value) {
    var item = getByKey(key);
    int version = 0;
    if(item != null){
      version = item.version;
    }
    
    _registry[key] = ValueWithVersion(value, version);
  }

  /// Rimuove un elemento tramite la sua chiave
  ValueWithVersion<Value>? unregister(Key key) {
    return _registry.remove(key);
  }

  /// Recupera un elemento (null-safe)
  ValueWithVersion<Value>? getByKey(Key key) {
    return _registry[key];
  }

  /// Recupera un elemento (null-safe)
  ValueWithVersion<Value> getInstace(Key key) {
    final item = getByKey(key);
    if (item != null) {
      return item;
    }
    throw Exception('Instance not found');
  }

  /// Verifica se una chiave esiste
  bool contains(Key key) => _registry.containsKey(key);

  /// Restituisce tutti gli oggetti come lista
  List<ValueWithVersion<Value>> get allItems => _registry.values.toList();

  /// Svuota il mapping
  void clearRegistry() => _registry.clear();

  /// Svuota il mapping
  void destroyAll() {
    List<ValueWithVersion<Value>> items = allItems;
    for(var item in items){
      item.value.destroy();
    }
  }
  
  /// Restituisce il numero di elementi
  int get registrySize => _registry.length;
}



class Singleton {
  final Map<Type, Object> _registry = {};

  /// Aggiunge un elemento usando il Tipo come chiave
  void register<T>(T value) {
    // Usiamo direttamente il tipo generico T come chiave
    _registry[T] = value as Object; 
  }

  /// Rimuove un elemento tramite il suo tipo
  void unregister<T>() {
    _registry.remove(T);
  }

  /// Recupera un elemento
  T getInstance<T>() {
    final value = _registry[T];
    if (value is T) {
      return value;
    }
    throw Exception('Instance of type $T not found');
  }

  void clearRegistry() => _registry.clear();

  int get registrySize => _registry.length;
}