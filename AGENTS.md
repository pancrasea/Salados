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
- `src/entities/item/plato_item.tscn`: plato contenedor con `recipe` de la sección de preparación.
- `src/entities/station/trash_bin.gd` y `trash_bin.tscn`: tacho `TrashBin` para descartar pedidos mal preparados.
- `src/entities/station/soup_pot.gd` y `soup_pot.tscn`: olla `SoupPot`; repone el líquido de sopa arrastrable.
- `src/entities/station/dispatch_zone.gd` y `dispatch_zone.tscn`: zona `DispatchZone` que envía el plato listo a otra estación.
- `src/entities/station/work_surface.gd` y `work_surface.tscn`: mesa `WorkSurface`; al soltar un ítem encima se queda donde el jugador lo dejó (destino de reserva del drop).
- `src/entities/station/preparation_station.gd` y `PreparationStation.tscn`: sección 3 (estación derecha).
- `src/core/main/main.gd` y `main.tscn`: main scene; menú + capa de escenas + navegación entre estaciones.
- `src/ui/mouse_interaction.gd` y `mouse_interaction.tscn`: controles de borde para girar estación.
- `src/entities/item/ingredients/spawner_ingredients.gd` y `.tscn`: `SpawnerIngredients` (WIP de otra célula; repone un ítem por `max_quantity`).
- `src/entities/order/order_data.gd` y `order_generator.gd`: pedido `OrderData` y generador `OrderGenerator`.
- `resources/recipes/encebollado.tres`: receta `RecipeData` del encebollado (líquido + cebolla + pescado + yuca).
- Las rutas de escenas actuales tienen mayúsculas en nombres como `Station.tscn` y `CustomerSpawner.tscn`; respeta la capitalización exacta de cada ruta.

## Contrato de integración ítem-cliente

- `BaseItem` es un `Node2D`; su identidad de juego es `BaseItem.data: ItemData`.
- El flujo de drop debe pasar `BaseItem.data` a `CustomerBase.receive_item()`, no el nodo `BaseItem`.
- Pedido estructurado: `CustomerBase.order: OrderData` (plato base + extras) tiene prioridad. La comparación es por clave canónica: `ItemData.recipe_key` contra `OrderData.key()` (ver más abajo). Si `order == null`, se usa el modo clásico: `CustomerData.requested_item` por igualdad de referencia del mismo `.tres`.
- Un `BaseItem` cuyo `data.is_container` es true **duplica su `ItemData` en `_ready`** para poder mutar `recipe_key` sin tocar el `.tres` compartido. Por eso las claves usan `ItemData.item_id` (estable en runtime) y no `resource_path`.
- El cliente solo acepta una entrega si sigue esperando y la clave/ítem coincide; NO requiere estar seleccionado, cualquier cliente de la fila recibe su pedido. Si `receive_item()` devuelve `true`: un alimento no contenedor se consume (`queue_free()`) y una bandeja se vacía y vuelve a su posición (`reset_container()`); si se rechaza, debe conservarse el comportamiento de retorno al punto inicial.
- Al soltar un ítem sobre un contenedor, el ingrediente se consume (`queue_free()`) tras registrarse en `collect_ingredients()`.
- Destinos de drop resueltos en `BaseItem._verify_target_and_drop()`: contenedor (`collect_ingredients`), `TrashBin` (`discard`), `DispatchZone` (`dispatch`) y `CustomerBase` (`receive_item`). Cada uno se detecta por el `Area2D` hijo.
- `WorkSurface` (`src/entities/station/work_surface.gd`/`.tscn`) es la mesa de trabajo: al soltar un ítem encima, se queda donde el jugador lo dejó (no vuelve a `initial_position`). Es un destino **de reserva**: `base_item.gd` lo registra con la bandera `on_work_surface` y sólo lo aplica si ningún otro destino del drop lo atendió, así que la mesa nunca roba un drop a un contenedor/tacho/cliente/despacho. La `PreparationStation` tiene una instancia `MesaTrabajo` (480x420, centrada en 900,550) que coincide con la `ZonaPreparacion`; si se mueve/agranda la zona hay que ajustar también el `CollisionShape2D` de la mesa.
- El `Area2D` del cliente debe seguir siendo detectable por el `Area2D` del ítem y su forma debe cubrir el área visible de interacción.

## Sistema de pedidos y preparación

- `OrderData` (`src/entities/order/order_data.gd`): `base: ItemData` + `extras: Array[ItemData]`. Su identidad es `key()`: ids únicos de base + extras, ordenados y unidos por coma (p. ej. `encebollado,limon,pan`); el orden de agregado no cambia el plato.
- Modelo de contenidos: la clave identifica el CONJUNTO de alimentos dentro de la bandeja. `OrderData.key_of_contents()` calcula la clave tanto del pedido como del contenido de `BaseItem.collected_ingredients`, así que base y extras se comparan como un solo conjunto.
- `ItemData.recipe_key` es SOLO runtime (nunca se exporta al editor); la calcula `BaseItem` en `_ready` y en `collect_ingredients()`. Solo la bandeja (contenedor) la tiene; entregar un alimento suelto a un cliente con `order` siempre se rechaza. Cada `ItemData` necesita un `item_id` único en su `.tres`.
- `OrderGenerator` (nodo) genera pedidos aleatorios; `CustomerSpawner.order_generator` (export de tipo Nodo, requiere `node_paths` en el `.tscn`) lo asigna a cada cliente antes de `add_child` para que el HUD pinte el pedido en `_ready`.
- Visual "icono base + badges": el icono del marco del pedido es el plato base y los extras se muestran como fila de badges (`OrderExtrasRow`, creada en runtime); la bandeja en el mundo muestra badges en fila horizontal bajo su sprite.
- Los 3 ingredientes básicos del encebollado son fijos y NO se modelan en `OrderData` ni en la bandeja: al preparar solo se agregan el plato de encebollado (`resources/items/encebollado.tres`, alimento final) y los extras.
- `.tres` de alimentos finales en `resources/items/`: `encebollado`, `pan`, `chifle`, `limon`, `canguil`, `maiz_tostado` (todos `is_final_product = true`) y `bandeja` (`is_container = true`). Iconos en `assets/sprites/items/*.svg`.
- Ítems de la sección de preparación en `resources/items/`: `plato` (`is_container`), `liquido_sopa`, `cebolla_cortada`, `pescado_desmenuzado` y `yuca_desmenuzada`; todos con `item_id` e icono en `assets/sprites/items/`.
- `FoodSpawner` (`src/entities/item/food_spawner.gd`): repone alimentos arrastrables en una columna; un slot por `ItemData` y respawn tras `respawn_delay` cuando el alimento se consume. En la sección de preparación también aprovisiona platos e ingredientes de prueba.
- Navegación: `main.tscn` (main scene) arranca en `MainMenu.tscn`; "Jugar" llama `GameManager.go_to_game()` → `main.start_game()`, que instancia las 4 estaciones en `SceneLayer` y las registra en `GameManager.setup_stations()`. Girar usa `GameManager.turn_left/turn_right/turn_back` desde `mouse_interaction`. `GameManager.get_station(side)` expone una estación registrada.
- El `Control` raíz `Main` usa `mouse_filter = 2` (IGNORE): si captura el mouse (STOP), se come el clic a pantalla completa y el drag and drop de los `Area2D` deja de funcionar. No lo cambies a STOP.

## Sección de preparación (sección 3, estación derecha)

- Flujo jugable: el jugador toma un **plato** (`resources/items/plato.tres`, contenedor) en el centro, le sirve el **líquido de sopa** (`liquido_sopa.tres`) desde la olla y luego agrega **cebolla cortada, pescado desmenuzado y yuca desmenuzada** en cualquier orden. Al completar el conjunto, el plato se transforma en el plato de **encebollado** y se despacha a la estación principal para agregarle los extras.
- Transformación por receta: `BaseItem` tiene `@export var recipe: RecipeData`. `collect_ingredients()` llama a `_try_complete_recipe()`, que compara el conjunto `collected_ingredients` con `recipe.require_ingredients` usando `OrderData.key_of_contents` (orden irrelevante; un ingrediente ajeno impide la transformación). Si coincide, `_transform_into(recipe.final_product)` cambia `data` por el producto final (sin mutar el `.tres`).
- `plato_item.tscn` es el plato contenedor con `recipe = resources/recipes/encebollado.tres`; su `ItemData` se duplica en `_ready` como cualquier contenedor.
- `DispatchZone.dispatch(item)` acepta solo `ItemData.is_final_product`, localiza la bandeja receptora (por nombre, o el primer contenedor reutilizable) en `GameManager.get_station(target_side)` y llama `collect_ingredients()`; luego libera el plato. No requiere que la estación destino esté visible.
- `SoupPot` mantiene un único líquido arrastrable y lo repone tras `respawn_delay` cuando se consume (`tree_exited`).
- Fuentes locales temporales: `Platos` e `IngredientesTemp` (ambos `FoodSpawner`) permiten probar la estación sin la sección previa; deberán sustituirse cuando esa sección entregue los ingredientes reales.
- Ojo con las coordenadas: todas las estaciones comparten el espacio de la escena. `GameManager.show_side()` ahora deshabilita `monitoring`/`monitorable` de los `Area2D` de las estaciones ocultas (`_set_interaction_enabled`) para que no interfieran con drops; aun así, evita que nodos interactivos de estaciones distintas coincidan en la misma posición.

## Cliente y generador

- `CustomerBase` expone señales de selección, paciencia, rechazo/aceptación del ítem, servicio y finalización. Conserva estas señales como contrato para HUD y sistemas externos.
- Los controles visuales requeridos por `customer.gd` están enlazados por rutas: `$SelectionArea`, `$PatienceBar`, `$OrderIconFrame`, `$OrderIconFrame/OrderIcon` y `$OrderIconFrame/OrderPlaceholder`.
- `CustomerSpawner` añade clientes como hijos, los coloca hacia la derecha usando `customer_spacing` en coordenadas locales, y compacta la fila al salir un cliente. Su escena debe asignar un `PackedScene` cuya raíz herede de `CustomerBase`.

## Pendientes conocidos al redactar este archivo

Estos puntos describen el estado observado y no implican permiso para ampliar una tarea que no los solicite:

- `Station.tscn` y `BackStation.tscn` son marcadores de posición: los lados izquierda/derecha/atrás apuntan a la misma `BackStation.tscn` (con un `BaseItem` sin `data`), así que girar aún no muestra contenido distinto. La sección de preparación ya ocupa el lado derecho.
- El ejemplo de cliente tiene `CustomerData` sin `requested_item`; eso es correcto cuando se usa `order` (lo asigna el `OrderGenerator` del spawner). El modo `requested_item` queda como respaldo.
- El drop sobre estaciones ya se resuelve con `WorkSurface` (mesa de trabajo; ver contrato arriba); la transformación por `ItemData.next_data_state` sigue sin implementar, hoy la transformación es por `RecipeData`.
- `SpawnerIngredients` (`spawner_ingredients.gd`) está en WIP: `replenish_stock()` tiene un no-op (`current_stock - item_data.max_quantity` sin asignar) y su recurso de ejemplo no define `item_id`.
- `project.godot` declara `viewport_width = 1980` (probable errata por 1920); no afecta la lógica pero conviene corregirlo.
- En el entorno donde se redactó este archivo no se encontró `godot`/`godot4` en el PATH. Vuelve a comprobarlo antes de concluir que no se puede ejecutar una validación headless.
