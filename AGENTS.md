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
- Validación headless sugerida: `godot --headless --path . --import` y luego un script temporal con `--script "res://<tmp>.gd"` (que termina en `quit(n_fallos)`), o `--quit-after <frames>`. Borra los `.gd`/`.uid` temporales al terminar.
- En arranques con `--script` el autoload `GameManager` NO existe como identificador global: los scripts que se cargan dinámicamente deben resolverlo con `get_node_or_null("/root/GameManager")` (ver `customer_spawner.gd`). Además `_ready` se difiere: usa `await process_frame` (y `await physics_frame` para solapamiento de `Area2D`) tras `add_child` antes de interactuar.

## Estructura relevante

- `src/core/autoloads/game_manager.gd`: autoload `GameManager` configurado en `project.godot`.
- `src/core/resources_scripts/customer_data.gd`: recurso configurable `CustomerData`.
- `src/entities/customer/customer.gd`: comportamiento base `CustomerBase`, selección, paciencia, entrega y señales.
- `src/entities/customer/customer.tscn`: escena del cliente; contiene `SelectionArea`, `PatienceBar` y `OrderIconFrame`.
- `src/entities/customer/customer_spawner.gd` y `CustomerSpawner.tscn`: generador de clientes en fila; límite previsto de tres.
- `src/entities/item/item_data.gd`: recurso `ItemData` con nombre, icono, estado siguiente, precio (`price`) y flags de contenedor/producto final.
- `src/entities/item/base_item.gd` y `base_item.tscn`: nodo arrastrable `BaseItem`.
- `src/entities/item/food_spawner.gd`: `FoodSpawner`, repone alimentos en la zona de suministro.
- `src/entities/item/bandeja_item.tscn`: bandeja contenedora reutilizable de la sección.
- `src/entities/item/plato_item.tscn`: plato contenedor con `recipe` de la sección de preparación.
- `src/entities/station/trash_bin.gd` y `trash_bin.tscn`: tacho `TrashBin` para descartar pedidos mal preparados.
- `src/entities/station/soup_pot.gd` y `soup_pot.tscn`: olla `SoupPot`; repone el líquido de sopa arrastrable.
- `src/entities/station/dispatch_zone.gd` y `dispatch_zone.tscn`: zona `DispatchZone` que envía el plato listo a otra estación.
- `src/entities/station/work_surface.gd` y `work_surface.tscn`: mesa `WorkSurface`; al soltar un ítem encima se queda donde el jugador lo dejó (destino de reserva del drop).
- `src/entities/station/preparation_station.gd` y `PreparationStation.tscn`: sección 3 (estación derecha).
- `src/entities/station/corte_desmenuce/corte_desmenuce.gd` y `CorteDesmenuce.tscn`: sección 2 (estación izquierda) de corte/desmenuce; DropArea + dos `ZonaProcesamiento` + fuente de materia prima.
- `src/entities/station/corte_desmenuce/components/zona_procesamiento.gd` y `.tscn`: `ZonaProcesamiento`; cuenta los clics de un ingrediente y emite `ingrediente_terminado`.
- `src/core/resources_scripts/encebollado_ingrediente.gd`: recurso `EncebolladoIngrediente` con las reglas de corte/desmenuce (item de entrada, `preparacion`, `clics_necesarios`).
- `src/core/inventory/inventario.gd`: `Inventario`, contador genérico de `ItemData` con identidad `item_id` (fallback `resource_path`), cupos opcionales por ítem, `max_por_item` (0 = sin límite) con `hay_espacio()`, señal `inventario_actualizado(item, cantidad)` y `reset_dia()`/`reset()`.
- `src/core/warehouse/almacen_preparados.gd`: `AlmacenPreparados extends Inventario`, almacén persistente (creado por `GameManager.warehouse`) que conecta la Sección 2 con la Sección 3; cupo `MAX_POR_ITEM = 3` por ingrediente (alineado con los 3 slots de la fuente `Ingredientes`).
- `src/core/resources_scripts/run_balance.gd` y `src/core/resources_scripts/stock_item.gd`: `RunBalance` (tunables de la partida: dinero inicial, renta, duración del día, cupos `stock_limits: Array[StockItem]`, config de clientes/paciencia) y `StockItem` (ítem + cupo diario).
- `resources/config/balance_default.tres`: valores de equilibrio cargados por `GameManager`.
- `src/ui/end_of_day.gd` y `src/ui/EndOfDay.tscn`: panel de fin de día (ganado/renta/saldo o deuda) con botón que vuelve al menú.
- `src/core/main/main.gd` y `main.tscn`: main scene; menú + capa de escenas + navegación entre estaciones.
- `src/ui/mouse_interaction.gd` y `mouse_interaction.tscn`: controles de borde para girar estación. Los tres botones (zonas izquierda/derecha/abajo) muestran flechas visibles dibujadas por `nav_arrow.gd` (`Polygon2D`-style vía `_draw`, sin fuentes ni texturas) y una etiqueta central `SeccionActual` indica la sección visible; se actualiza con la señal `station_changed` de `GameManager`.
- `src/ui/hud.gd` y `hud.tscn`: HUD permanente (dinero, tiempo y panel de información con stock y precios).
- `src/entities/item/ingredients/spawner_ingredients.gd` y `.tscn`: `SpawnerIngredients` (WIP de otra célula; repone un ítem por `max_quantity`).
- `src/entities/order/order_data.gd` y `order_generator.gd`: pedido `OrderData` y generador `OrderGenerator`.
- `resources/recipes/encebollado.tres`: receta `RecipeData` del encebollado (líquido + cebolla + albacora + yuca).
- Las rutas de escenas actuales tienen mayúsculas en nombres como `Station.tscn` y `CustomerSpawner.tscn`; respeta la capitalización exacta de cada ruta.

## Contrato de integración ítem-cliente

- `BaseItem` es un `Node2D`; su identidad de juego es `BaseItem.data: ItemData`.
- El flujo de drop debe pasar `BaseItem.data` a `CustomerBase.receive_item()`, no el nodo `BaseItem`.
- Pedido estructurado: `CustomerBase.order: OrderData` (plato base + extras) tiene prioridad. La comparación es por clave canónica: `ItemData.recipe_key` contra `OrderData.key()` (ver más abajo). Si `order == null`, se usa el modo clásico: `CustomerData.requested_item` por igualdad de referencia del mismo `.tres`.
- Un `BaseItem` cuyo `data.is_container` es true **duplica su `ItemData` en `_ready`** para poder mutar `recipe_key` sin tocar el `.tres` compartido. Por eso las claves usan `ItemData.item_id` (estable en runtime) y no `resource_path`.
- El cliente solo acepta una entrega si sigue esperando y la clave/ítem coincide; NO requiere estar seleccionado, cualquier cliente de la fila recibe su pedido. Si `receive_item()` devuelve `true`: un alimento no contenedor se consume (`queue_free()`) y una bandeja se vacía y vuelve a su posición (`reset_container()`); si se rechaza, debe conservarse el comportamiento de retorno al punto inicial.
- Al soltar un ítem sobre un contenedor, el ingrediente se consume (`queue_free()`) tras registrarse en `collect_ingredients()`.
- Destinos de drop resueltos en `BaseItem._verify_target_and_drop()`: contenedor (`collect_ingredients`), `TrashBin` (`discard`), `DispatchZone` (`dispatch`), `CustomerBase` (`receive_item`) y `CorteDesmenuce` (`recibir_item`). Cada uno se detecta por el `Area2D` hijo. Al entrar a la estación de corte, el nodo `BaseItem` se consume (`queue_free()`) y el `ItemData` queda en la estación hasta completar los clics.
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
- Ítems de la sección de preparación en `resources/items/`: `plato` (`is_container`), `liquido_sopa`, `cebolla_cortada`, `pescado_desmenuzado` (nombre visible "Albacora desmenuzada", `item_id = "albacora_desmenuzada"`) y `yuca_desmenuzada`; todos con `item_id` e icono en `assets/sprites/items/`.
- Materia prima de la Sección 2 en `resources/items/`: `item_cebolla_colorada`, `item_albacora`, `item_yuca` (crudos, con `next_data_state` apuntando a los ítems preparados del equipo y con icono SVG del proyecto). Cada regla vive en `encebollado_cebolla_colorada.tres`, `encebollado_albacora.tres` y `encebollado_yuca.tres` (`clics_necesarios = 3`). El cilantro queda fuera del flujo.
- `FoodSpawner` (`src/entities/item/food_spawner.gd`): repone alimentos arrastrables en una zona fija y respawn tras `respawn_delay` cuando el alimento se consume. Layout configurable: `slots_per_item` (1–6, por defecto 1) slots por cada `ItemData` de `foods`; con `horizontal_groups = true` los slots de un mismo alimento se alinean en horizontal (una fila por alimento, separados por `slot_spacing`) y las filas se apilan con `row_spacing`; con `slots_per_item = 1` y `horizontal_groups = false` se conserva la columna vertical clásica (un slot por alimento). `stock_source` (`enum { INFINITE, PREPARADOS, MATERIA_PRIMA }`) elige de qué inventario se abastece (`GameManager.warehouse` o `GameManager.materia_prima`): en modo con inventario muestra hasta `min(stock, slots_per_item)` unidades por alimento y descuenta una al consumirse; consumir no repone al instante (respeta `respawn_delay`, el hueco lo llena el timer del slot), mientras que un aumento de stock sí refresca de inmediato. La fuente `Ingredientes` de la Sección 3 usa `PREPARADOS` con `slots_per_item = 3` y `horizontal_groups = true` (límite de 3 slots por ingrediente alineados en horizontal); la fuente `MateriaPrima` de la Sección 2 usa `MATERIA_PRIMA` (un slot por crudo); `Platos` sigue en `INFINITE`. `item_scale` escala los alimentos spawneados (fuentes compactas); lo usan `Agregados` de la estación principal e `Ingredientes`.
- Navegación: `main.tscn` (main scene) arranca en `MainMenu.tscn`; "Jugar" llama `GameManager.go_to_game()` → `main.start_game()`, que instancia las 4 estaciones en `SceneLayer` y las registra en `GameManager.setup_stations()`. Girar usa `GameManager.turn_left/turn_right/turn_back` desde `mouse_interaction`. `GameManager.get_station(side)` expone una estación registrada; `GameManager.current_side()` y la señal `station_changed(side)` informan la sección visible (las usa el HUD).
- El `Control` raíz `Main` usa `mouse_filter = 2` (IGNORE): si captura el mouse (STOP), se come el clic a pantalla completa y el drag and drop de los `Area2D` deja de funcionar. No lo cambies a STOP.

## Sección de preparación (sección 3, estación derecha)

- Flujo jugable: el jugador toma un **plato** (`resources/items/plato.tres`, contenedor) en el centro, le sirve el **líquido de sopa** (`liquido_sopa.tres`) desde la olla y luego agrega **cebolla cortada, albacora desmenuzada y yuca desmenuzada** en cualquier orden (provistas por la fuente `Ingredientes` con `stock_source = PREPARADOS`, abastecida por la Sección 2 vía `GameManager.warehouse`). Al completar el conjunto, el plato se transforma en el plato de **encebollado** y se despacha a la estación principal para agregarle los extras.
- Transformación por receta: `BaseItem` tiene `@export var recipe: RecipeData`. `collect_ingredients()` llama a `_try_complete_recipe()`, que compara el conjunto `collected_ingredients` con `recipe.require_ingredients` usando `OrderData.key_of_contents` (orden irrelevante; un ingrediente ajeno impide la transformación). Si coincide, `_transform_into(recipe.final_product)` cambia `data` por el producto final (sin mutar el `.tres`).
- `plato_item.tscn` es el plato contenedor con `recipe = resources/recipes/encebollado.tres`; su `ItemData` se duplica en `_ready` como cualquier contenedor.
- `DispatchZone.dispatch(item)` acepta solo `ItemData.is_final_product`, localiza la bandeja receptora (por nombre, o el primer contenedor reutilizable) en `GameManager.get_station(target_side)` y llama `collect_ingredients()`; luego libera el plato. No requiere que la estación destino esté visible.
- `SoupPot` mantiene un único líquido arrastrable y lo repone tras `respawn_delay` cuando se consume (`tree_exited`).
- La fuente `Ingredientes` (`FoodSpawner` con `stock_source = PREPARADOS`, `slots_per_item = 3`, `horizontal_groups = true`) muestra hasta 3 unidades por ingrediente mientras el `AlmacenPreparados` tenga stock; al soltar uno en el plato se descuenta del almacén (la reposición respeta `respawn_delay`). La fuente `Platos` sigue en modo `INFINITE` (infinita).
- Ojo con las coordenadas: todas las estaciones comparten el espacio de la escena. `GameManager.show_side()` ahora deshabilita `monitoring`/`monitorable` de los `Area2D` de las estaciones ocultas (`_set_interaction_enabled`) para que no interfieran con drops; aun así, evita que nodos interactivos de estaciones distintas coincidan en la misma posición.

## Sección de corte/desmenuce (sección 2, estación izquierda)

- Arranca en `main.tscn` como `LEFT_STATION_SCENE` (`CorteDesmenuce.tscn`, `extends Station`). El lado atrás sigue siendo placeholder.
- Flujo jugable: el jugador arrastra materia prima desde la fuente `MateriaPrima` (`FoodSpawner` con `stock_source = MATERIA_PRIMA` y `item_cebolla_colorada`, `item_albacora`, `item_yuca`) y la suelta sobre el `DropArea`. El `BaseItem` se consume y el `ItemData` queda en la estación; el jugador da **3 clics** (`ZonaProcesamiento`) para completarlo. Cebolla y yuca se procesan en `ZonaCorte`; la albacora se desmenuza en `ZonaDesmenuce`.
- `CorteDesmenuce.recibir_item(item: ItemData) -> bool` valida contra su `RECETAS` (`EncebolladoIngrediente`): acepta sólo si el ítem es un `item_entrada` con `next_data_state` no nulo, su zona no está ocupada **y el almacén de la Sección 3 tiene espacio** para el preparado resultante (`_hay_espacio`/`Inventario.hay_espacio`); si está lleno rechaza el crudo (vuelve a su posición) y avisa en `Mensaje`. Al completar los clics emite `item_preparado(item: ItemData)` (el recurso preparado) y resetea la zona.
- `ZonaProcesamiento` sólo arranca con el `tipo_aceptado` correcto (`0` = corte, `1` = desmenuce) y la `preparacion` de la regla; `clics_necesarios = 3` en los tres `.tres`.
- El resultado se guarda vía `GameManager.warehouse.agregar(item)`: `main.gd` conecta `corte.item_preparado` a `AlmacenPreparados.agregar`. La identidad del inventario es `ItemData.item_id` (fallback `resource_path`), con `consumir()` que descuenta una unidad y emite `inventario_actualizado(item, cantidad)`.

## Economía y datos de partida

- `GameManager` carga `RunBalance` desde `resources/config/balance_default.tres` (cuando no hay recurso, usa constantes de respaldo) y expone `balance`, `warehouse` (cupo 3 por preparado) y `materia_prima` (con cupos de `balance.stock_limits`). `start_day()` reinicia `materia_prima` (cupo diario gratuito) y `end_day()` cobra la renta, publica `last_settlement` (earnings/rent/balance/debt) y emite `day_settled`.
- Precios: `ItemData.price` por ítem; el valor de un pedido es `OrderData.price()` = precio base + extras. Al atender un pedido, `CustomerSpawner` paga `precio × multiplicador de paciencia` vía `GameManager.add_money()` y acumula en `day_earnings`.
- Paciencia y clientes se configuran en `RunBalance` (`max_customers`, `spawn_interval`, `default_patience`); `CustomerData.patience_seconds` en 0 usa el valor del balance (`CustomerBase._patience_for()`).
- Fin de día: `main.gd` conecta `day_settled` para pausar y mostrar `EndOfDay.tscn`; su botón llama `GameManager.go_to_menu()` y des-pausa. La renta puede dejar saldo negativo (deuda) y el panel la avisa.
- Cupos iniciales: cebolla/albacora/yuca = 8/8/8 (⇒ hasta 8 encebollados por día); precios encebollado 12, pan 2, chifle 3, limón 1, canguil 2, maíz 2. Crudos y preparados no tienen precio.
- UI: `RunBalance` expone catálogos de solo-lectura para el HUD (`preparados_catalogo`, `platos_catalogo`). El panel del HUD (`hud.gd`/`hud.tscn`) cambia según la estación visible (`GameManager.current_side` + señal `station_changed`): precios de platos en la principal, stock de crudos (`actual/cupo`) en la Sección 2 y stock de preparados en la Sección 3; el lado trasero lo oculta. Se refresca con la señal `inventario_actualizado` de `materia_prima` y `warehouse`.
- Estación principal: fuente `Agregados` (`FoodSpawner` `INFINITE` con pan, chifle, limón, canguil y maíz tostado, en escala compacta) para agregarlos a la bandeja. El precio del pedido se muestra en el mundo sobre el icono del cliente (`CustomerBase.order_price_label`).
## Cliente y generador

- `CustomerBase` expone señales de selección, paciencia, rechazo/aceptación del ítem, servicio y finalización. Conserva estas señales como contrato para HUD y sistemas externos.
- Los controles visuales requeridos por `customer.gd` están enlazados por rutas: `$SelectionArea`, `$PatienceBar`, `$OrderIconFrame`, `$OrderIconFrame/OrderIcon` y `$OrderIconFrame/OrderPlaceholder`.
- `CustomerSpawner` añade clientes como hijos, los coloca hacia la derecha usando `customer_spacing` en coordenadas locales, y compacta la fila al salir un cliente. Su escena debe asignar un `PackedScene` cuya raíz herede de `CustomerBase`.
- Además de la fila de badges (`OrderExtrasRow`), el cliente crea en runtime `OrderPriceLabel` (Label sobre el icono del pedido) con `OrderData.price()`; solo aparece cuando hay pedido estructurado.

## Pendientes conocidos al redactar este archivo

Estos puntos describen el estado observado y no implican permiso para ampliar una tarea que no los solicite:

- `Station.tscn` y `BackStation.tscn` son marcadores de posición: el lado atrás sigue apuntando a `BackStation.tscn` (con un `BaseItem` sin `data`). Los lados izquierda (corte/desmenuce) y derecha (preparación) ya tienen contenido real.
- El ejemplo de cliente tiene `CustomerData` sin `requested_item`; eso es correcto cuando se usa `order` (lo asigna el `OrderGenerator` del spawner). El modo `requested_item` queda como respaldo.
- El drop sobre estaciones se resuelve con `WorkSurface` (mesa de trabajo) y con `CorteDesmenuce` (`recibir_item`); la transformación de ítems por `ItemData.next_data_state` no se aplica de forma genérica: la Sección 2 lo usa para elegir el resultado del corte/desmenuce y la Sección 3 transforma por `RecipeData`.
- `SpawnerIngredients` (`spawner_ingredients.gd`) está en WIP: `replenish_stock()` tiene un no-op (`current_stock - item_data.max_quantity` sin asignar) y su recurso de ejemplo no define `item_id`.
- En el entorno donde se redactó este archivo no se encontró `godot`/`godot4` en el PATH. Vuelve a comprobarlo antes de concluir que no se puede ejecutar una validación headless.
