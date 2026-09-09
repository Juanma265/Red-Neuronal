import numpy as np
import matplotlib.pyplot as plt

# 1. GRÁFICA ESTADÍSTICA
datos = np.loadtxt('estadistica_hopfield.dat')
distancias = datos[:, 3]
ruta_valida = datos[:, 2]
validos = distancias[ruta_valida == 1]
    
plt.figure(figsize=(6, 4))
plt.hist(validos, bins=12, color='skyblue', edgecolor='black', alpha=0.7)
plt.axvline(np.mean(validos), color='crimson', linestyle='--', label=f'Media: {np.mean(validos):.1f} km')
plt.title('Distribución de Distancias Obtenidas')
plt.xlabel('Distancia (km)')
plt.ylabel('Frecuencia')
plt.legend()
plt.grid(True, linestyle=':', alpha=0.6)
plt.tight_layout()
plt.show()


# 2. LEER COORDENADAS Y PLOTEAR RUTA DIRECTAMENTE
try:
    # Carga la matriz numérica (10 filas x 2 columnas: X e Y)
    coordenadas = np.loadtxt('mejor_ruta.dat')
    
    X = coordenadas[:, 0]
    Y = coordenadas[:, 1]
    
    # Cerramos el anillo uniendo el último punto con el primero
    X_cerrado = np.append(X, X[0])
    Y_cerrado = np.append(Y, Y[0])
    
    plt.figure(figsize=(8, 6))
    
    # Pintamos la trayectoria continua y los puntos de las paradas
    plt.plot(X_cerrado, Y_cerrado, color='teal', linestyle='-', linewidth=2, marker='o', 
             markersize=8, markerfacecolor='crimson', markeredgecolor='black')
        
    plt.title('Mejor Ruta Encontrada (Coordenadas 2D)')
    plt.xlabel('X (km)')
    plt.ylabel('Y (km)')
    plt.axis('equal')
    plt.grid(True, linestyle=':', alpha=0.5)
    plt.tight_layout()
    plt.show()

except FileNotFoundError:
    print("Error: No se encontró 'mejor_ruta.dat'.")