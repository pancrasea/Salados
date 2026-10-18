extends Station

## Sección de preparación (estación derecha). Mesa central para armar el
## encebollado en orden libre (plato -> líquido de la olla -> cebolla cortada,
## albacora desmenuzada y yuca desmenuzada) y zona de despacho que envía el
## plato terminado a la bandeja de la estación principal.
##
## La lógica vive en los nodos hijos (SoupPot, FoodSpawner, DispatchZone y
## TrashBin); esta clase sólo marca la estación para GameManager. La fuente
## `Ingredientes` (FoodSpawner con `stock_source = PREPARADOS`) se abastece del
## AlmacenPreparados que llena la Sección 2 (corte/desmenuce): sólo muestra un
## ingrediente mientras haya unidades y descuenta una al usarlo.
