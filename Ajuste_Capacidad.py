# -*- coding: utf-8 -*-
"""
Created on Wed May 27 17:13:12 2026

@author: juanm
"""

import pandas as pd
import numpy as np
from scipy.optimize import curve_fit
import matplotlib.pyplot as plt
import os

# --- CONFIGURACIÓN ESTÉTICA ---
colors = ["#668F80", "#A0AF84", "#F4A259", "#BC4B51", "#5B8E7D", "#8E7DBE"]
label_size = 19
tick_size = 19
legend_size = 14

# Configuración de archivos y parámetros de la red
file_name = './resultados.txt'  
output_dir = './graficas'
os.makedirs(output_dir, exist_ok=True)


N_neuronas = 1225  

# Función de ajuste: Sigmoide (Distribución de Fermi-Dirac)
def func(x, alpha_c, delta):
    return 1.0 / (1.0 + np.exp((x - alpha_c) / delta))

# Estimación inicial lógica para el algoritmo no lineal
guess = [0.14, 0.01]
param_names = ['alpha_c', 'delta']

# --- PROCESAMIENTO DE DATOS ---

try:
    # 1. Leer las 6 columnas del archivo (P + 5 réplicas)
    raw_data = pd.read_csv(file_name, sep='\s+', header=None)
    
    # Extraer variables
    patrones = raw_data.iloc[:, 0].values  # Primera columna: Número de patrones (P)
    replicas = raw_data.iloc[:, 1:6].values  # Columnas 2 a 6: Las 5 réplicas del solapamiento
    
    # Transformación física al eje X universal: Carga de la red (alpha = P/N)
    alpha_data = patrones / N_neuronas
    
    # 2. Cálculos estadísticos por fila (coordenada Y)
    y_mean = np.mean(replicas, axis=1)        # Media del solapamiento final
    y_std = np.std(replicas, axis=1, ddof=1)  # Desviación estándar muestral
    
    # Incertidumbre de Tipo A (u_A = s / sqrt(n))
    n_replicas = 5
    u_A = y_std / np.sqrt(n_replicas)
    
    # Suelo de incertidumbre para evitar divisiones por cero en zonas de convergencia perfecta (m=1)
    u_A[u_A == 0.0] = 1e-4

except Exception as e:
    print(f"Error al leer o procesar el archivo: {e}")
    exit()

# 3. Ajuste no lineal ponderado con las incertidumbres experimentales
try:
    popt, pcov = curve_fit(func, alpha_data, y_mean, p0=guess, sigma=u_A, absolute_sigma=True)
    error = np.sqrt(np.diag(pcov))
except Exception as e:
    print(f"El ajuste no lineal no pudo converger: {e}")
    exit()

# 4. Cálculo del coeficiente de determinación R² para el modelo no lineal
y_pred = func(alpha_data, *popt)
residuals = y_mean - y_pred
ss_res = np.sum((residuals / u_A) ** 2)
ss_tot = np.sum(((y_mean - np.mean(y_mean)) / u_A) ** 2)
r_squared = 1 - (ss_res / ss_tot)

# 5. Imprimir resultados en la consola
print(f'Procesando: {file_name} (N = {int(N_neuronas)} neuronas)')
print(f'Parámetros óptimos del ajuste sigmoide:')
print(f'  {param_names[0]} (Capacidad crítica) = {popt[0]:.5f} ± {error[0]:.5f}')
print(f'  {param_names[1]} (Ancho de transición) = {popt[1]:.5f} ± {error[1]:.5f}')
print(f'R² del ajuste no lineal: {r_squared:.6f}\n')

# --- SECCIÓN DE GRÁFICA ---
fig = plt.figure(figsize=(9, 7))

# Márgenes lógicos del espacio de fases
x_min, x_max = alpha_data.min(), alpha_data.max()
x_range = x_max - x_min

plt.xlim(0.0, x_max + 0.05 * x_range)
plt.ylim(-0.05, 1.05) 

# Crear curva suave continua del ajuste
x_fit = np.linspace(0.0, x_max + 0.05 * x_range, 300)
y_fit_line = func(x_fit, *popt)

# --- LEYENDA CON EL PARÁMETRO CRÍTICO ---
label_fit = (f"Ajuste Sigmoide\n"
             f"$\\alpha_c = {popt[0]:.4f} \\pm {error[0]:.4f}$\n"
             f"$\\Delta = {popt[1]:.4f} \\pm {error[1]:.4f}$\n"
             f"$R^2 = {r_squared:.4f}$")

# =============================================================================
# NUEVA MODIFICACIÓN: Dibujar las 5 réplicas individuales de fondo
# =============================================================================
# Pintamos la primera columna con etiqueta para la leyenda
plt.scatter(alpha_data, replicas[:, 0], color=colors[2], alpha=0.3, s=15, 
            label='Réplicas individuales', zorder=2)

# Las 4 columnas de réplicas restantes se pintan sin etiqueta para no duplicar la leyenda
for r in range(1, 5):
    plt.scatter(alpha_data, replicas[:, r], color=colors[2], alpha=0.3, s=15, zorder=2)
# =============================================================================

# 1. Dibujar los puntos promediados con sus barras de error de tipo A
plt.errorbar(
    alpha_data, y_mean, yerr=u_A,
    fmt='o',
    color=colors[0],
    ecolor=colors[3],     # Color contrastado (rojo/coral) para las barras de error
    capsize=4,
    markersize=6,
    label='Datos simulación (Media $\\pm u_A$)',
    zorder=4              # Forzado un zorder mayor para que quede por encima de las réplicas
)

# 2. Dibujar la curva sigmoide ajustada
plt.plot(
    x_fit, y_fit_line, 
    linestyle='--', 
    color=colors[4], 
    linewidth=2.5,
    label=label_fit,
    zorder=3
)

# --- ESTÉTICA FINAL ---
plt.xlabel("Carga de la red ($\\alpha = P/N$)", fontsize=label_size) 
plt.ylabel("Solapamiento final medio ($\\overline{m}$)", fontsize=label_size)
plt.xticks(fontsize=tick_size)
plt.yticks(fontsize=tick_size)

plt.grid(True, which='both', linestyle='--', alpha=0.3)
plt.legend(loc='lower left', fontsize=legend_size, frameon=True)

plt.tight_layout()

# Guardar automáticamente el resultado
plt.savefig(os.path.join(output_dir, f'ajuste_sigmoide_{int(N_neuronas)}.png'), dpi=300)

plt.show()