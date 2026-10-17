# Contexto del proyecto Salados

## Proyecto

- Juego de cocina hecho con Godot; `project.godot` declara Godot 4.7 y GDScript tipado.
- El proyecto usa recursos `.tres`, escenas `.tscn` y clases globales declaradas con `class_name`.
- Mantener los identificadores y nombres de nodos existentes: hay código que accede a ellos por ruta o por nombre.

## Reglas para colaborar

- El proyecto se trabaja en paralelo. Antes de modificar un archivo, lee su estado actual y conserva cambios ajenos; no reemplaces archivos completos para hacer ajustes pequeños.
- Documenta el código nuevo o modificado: explica contratos de señales, propiedades exportadas, métodos públicos y decisiones que no sean obvias. Mantén los comentarios breves y útiles para el siguiente integrante.
- Conserva las APIs existentes salvo que la integración lo requiera; cuando cambies una firma, busca y actualiza todos sus usos.
- No edites manualmente archivos `.uid` generados por Godot.
- No des por probada una escena solo porque pase diagnósticos estáticos. Ejecuta una validación en Godot si el motor está disponible; en caso contrario, indícalo.

## Estructura relevante

- `src/core/autoloads/game_manager.gd`: autoload `GameManager` configurado en `project.godot`.
- `src/core/resources_scripts/customer_data.gd`: recurso configurable `CustomerData`.
- `src/entities/customer/customer.gd`: comportamiento base `CustomerBase`, selección, paciencia, entrega y señales.
- `src/entities/customer/customer.tscn`: escena del cliente; contiene `SelectionArea`, `PatienceBar` y `OrderIconFrame`.
- `src/entities/customer/customer_spawner.gd` y `CustomerSpawner.tscn`: generador de clientes en fila; límite previsto de tres.
- `src/entities/item/item_data.gd`: recurso `ItemData` con nombre, icono, estado siguiente y flags de contenedor/producto final.
- `src/entities/item/base_item.gd` y `base_item.tscn`: nodo arrastrable `BaseItem`.
- `src/entities/item/food_spawner.gd`: `FoodSpawner`, repone alimentos en la zona de suministro.
- `src/entities/item/bandeja_item.tscn`: bandeja contenedora reutilizable de la sección.
- `src/entities/station/trash_bin.gd` y `trash_bin.tscn`: tacho `TrashBin` para descartar pedidos mal preparados.
- `src/entities/order/order_data.gd` y `order_generator.gd`: pedido `OrderData` y generador `OrderGenerator`.
- `src/entities/recipe/recipe_data.gd`: datos de recetas (aún sin consumidores).
- Las rutas de escenas actuales tienen mayúsculas en nombres como `Station.tscn` y `CustomerSpawner.tscn`; respeta la capitalización exacta de cada ruta.

## Contrato de integración ítem-cliente

- `BaseItem` es un `Node2D`; su identidad de juego es `BaseItem.data: ItemData`.
- El flujo de drop debe pasar `BaseItem.data` a `CustomerBase.receive_item()`, no el nodo `BaseItem`.
- Pedido estructurado: `CustomerBase.order: OrderData` (plato base + extras) tiene prioridad. La comparación es por clave canónica: `ItemData.recipe_key` contra `OrderData.key()` (ver más abajo). Si `order == null`, se usa el modo clásico: `CustomerData.requested_item` por igualdad de referencia del mismo `.tres`.
- Un `BaseItem` cuyo `data.is_container` es true **duplica su `ItemData` en `_ready`** para poder mutar `recipe_key` sin tocar el `.tres` compartido. Por eso las claves usan `ItemData.item_id` (estable en runtime) y no `resource_path`.
- El cliente solo acepta una entrega si sigue esperando y la clave/ítem coincide; NO requiere estar seleccionado, cualquier cliente de la fila recibe su pedido. Si `receive_item()` devuelve `true`: un alimento no contenedor se consume (`queue_free()`) y una bandeja se vacía y vuelve a su posición (`reset_container()`); si se rechaza, debe conservarse el comportamiento de retorno al punto inicial.
- Al soltar un ítem sobre un contenedor, el ingrediente se consume (`queue_free()`) tras registrarse en `collect_ingredients()`.
- Destinos de drop resueltos en `BaseItem._verify_target_and_drop()`: contenedor (`collect_ingredients`), `TrashBin` (`discard`: vacía la bandeja o consume el alimento) y `CustomerBase` (`receive_item`). Cada uno se detecta por el `Area2D` hijo.
- El `Area2D` del cliente debe seguir siendo detectable por el `Area2D` del ítem y su forma debe cubrir el área visible de interacción.

## Sistema de pedidos y preparación

- `OrderData` (`src/entities/order/order_data.gd`): `base: ItemData` + `extras: Array[ItemData]`. Su identidad es `key()`: ids únicos de base + extras, ordenados y unidos por coma (p. ej. `encebollado,limon,pan`); el orden de agregado no cambia el plato.
- Modelo de contenidos: la clave identifica el CONJUNTO de alimentos dentro de la bandeja. `OrderData.key_of_contents()` calcula la clave tanto del pedido como del contenido de `BaseItem.collected_ingredients`, así que base y extras se comparan como un solo conjunto.
- `ItemData.recipe_key` es SOLO runtime (nunca se exporta al editor); la calcula `BaseItem` en `_ready` y en `collect_ingredients()`. Solo la bandeja (contenedor) la tiene; entregar un alimento suelto a un cliente con `order` siempre se rechaza. Cada `ItemData` necesita un `item_id` único en su `.tres`.
- `OrderGenerator` (nodo) genera pedidos aleatorios; `CustomerSpawner.order_generator` (export de tipo Nodo, requiere `node_paths` en el `.tscn`) lo asigna a cada cliente antes de `add_child` para que el HUD pinte el pedido en `_ready`.
- Visual "icono base + badges": el icono del marco del pedido es el plato base y los extras se muestran como fila de badges (`OrderExtrasRow`, creada en runtime); la bandeja en el mundo muestra badges en fila horizontal bajo su sprite.
- Los 3 ingredientes básicos del encebollado son fijos y NO se modelan en `OrderData` ni en la bandeja: al preparar solo se agregan el plato de encebollado (`resources/items/encebollado.tres`, alimento final) y los extras.
- `.tres` de alimentos finales en `resources/items/`: `encebollado`, `pan`, `chifle`, `limon`, `canguil`, `maiz_tostado` (todos `is_final_product = true`) y `bandeja` (`is_container = true`). Iconos en `assets/sprites/items/*.svg`.
- `FoodSpawner` (`src/entities/item/food_spawner.gd`): repone alimentos arrastrables en una columna; un slot por `ItemData` y respawn tras `respawn_delay` cuando el alimento se consume.
- Escena de prueba de la sección: `src/levels/section_test.tscn` (main scene): izquierda alimentos, centro-arriba clientes, centro-abajo bandeja. La bandeja es reutilizable: al servir se vacía y vuelve a su posición (`BaseItem.reset_container()`) en lugar de consumirse.

## Cliente y generador

- `CustomerBase` expone señales de selección, paciencia, rechazo/aceptación del ítem, servicio y finalización. Conserva estas señales como contrato para HUD y sistemas externos.
- Los controles visuales requeridos por `customer.gd` están enlazados por rutas: `$SelectionArea`, `$PatienceBar`, `$OrderIconFrame`, `$OrderIconFrame/OrderIcon` y `$OrderIconFrame/OrderPlaceholder`.
- `CustomerSpawner` añade clientes como hijos, los coloca hacia la derecha usando `customer_spacing` en coordenadas locales, y compacta la fila al salir un cliente. Su escena debe asignar un `PackedScene` cuya raíz herede de `CustomerBase`.

## Pendientes conocidos al redactar este archivo

Estos puntos describen el estado observado y no implican permiso para ampliar una tarea que no los solicite:

- `GameManager.load_scene()` está vacío. `mouse_interaction.gd` consulta `GameManager.current_station`, pero el estado actual de `game_manager.gd` no declara esa propiedad; comprobar este contrato antes de trabajar en navegación.
- `Station.tscn` solo contiene un `Node2D`; no define las áreas/conexiones que llamarían los callbacks de `station.gd`.
- El ejemplo de cliente tiene `CustomerData` sin `requested_item`; eso es correcto cuando se usa `order` (lo asigna el `OrderGenerator` del spawner). El modo `requested_item` queda como respaldo.
- El drop sobre estaciones (`#TODO` en `base_item.gd`) y la transformación por `ItemData.next_data_state` siguen sin implementar.
- `RecipeData` sigue sin consumidores: hoy la validación de combinaciones es por clave de contenidos, no por `.tres` de recetas.
- En el entorno donde se redactó este archivo no se encontró `godot`/`godot4` en el PATH. Vuelve a comprobarlo antes de concluir que no se puede ejecutar una validación headless.
