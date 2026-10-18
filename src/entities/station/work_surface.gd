class_name WorkSurface extends Node2D

## Superficie de trabajo (mesa) de una estación: al soltar un ítem aquí, se
## queda donde el jugador lo dejó en vez de volver a su posición inicial.
##
## Es un destino "de reserva": en BaseItem._verify_target_and_drop() sólo se
## usa si ningún otro destino (contenedor, TrashBin, CustomerBase,
## DispatchZone) atendió el drop, para que la mesa no compita con ellos.
## Se detecta por el Area2D hijo, igual que el resto de destinos.
