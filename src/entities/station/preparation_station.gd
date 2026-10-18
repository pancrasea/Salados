extends Station

## Sección de preparación (estación derecha). Mesa central para armar el
## encebollado en orden libre (plato -> líquido de la olla -> cebolla
## cortada, pescado desmenuzado y yuca desmenuzada) y zona de despacho que
## envía el plato terminado a la bandeja de la estación principal.
##
## La lógica vive en los nodos hijos (SoupPot, FoodSpawner, DispatchZone y
## TrashBin); esta clase sólo marca la estación para GameManager. Las fuentes
## de platos e ingredientes son temporales mientras la sección previa no
## entrega los ingredientes reales.
