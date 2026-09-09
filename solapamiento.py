import numpy as np
import matplotlib.pyplot as plt

# --- CONFIGURACIÓN ---
NUM_PATRONES = 1  # <--- Numero de patrones de la red
# ---------------------

data = np.loadtxt('solapamiento.txt')

# Explicación: data[inicio::paso]
# Empezamos en 0 (primer patrón) y saltamos de P en P
tiempo = data[0::NUM_PATRONES, 0] 
solapamiento_1 = data[0::NUM_PATRONES, 1]

plt.figure(figsize=(10, 6))
plt.plot(tiempo, solapamiento_1, color='blue', linewidth=1.5, label='Solapamiento Patrón 1')

plt.title('Evolución del solapamiento (Solo Patrón 1)', fontsize=14)
plt.xlabel('Pasos de tiempo', fontsize=12)
plt.ylabel('Solapamiento $m$', fontsize=12)
plt.grid(True, linestyle='--', alpha=0.6)
plt.legend()
plt.show()