# -*- coding: utf-8 -*-
"""
Created on Mon Jun 29 16:24:17 2026

@author: juanm
"""

# -*- coding: utf-8 -*-
"""
Created on Mon Jun 29 16:23:12 2026

@author: juanm
"""

import pandas as pd
import numpy as np
from scipy.optimize import curve_fit
import matplotlib.pyplot as plt
import os

# --- CONFIGURACIÓN ESTÉTICA ---
# Colores asignados estratégicamente a cada red para mantener coherencia cromática
colors_redes = {
    900:  {"puntos": "#668F80", "linea": "#466359", "label": "N = 900 (30x30)"},
    1225: {"puntos": "#F4A259", "linea": "#D38137", "label": "N = 1225 (35x35)"},
    1600: {"puntos": "#8E7DBE", "linea": "#6E5CA0", "label": "N = 1600 (40x40)"}
}
color_teorica = "#BC4B51"  # Rojo coral para el límite analítico clásico
color_replicas = "#A0AF84" # Verde oliva atenuado para la nube estocástica

label_size = 19
tick_size = 19
legend_size = 11

output_dir = './graficas'
os.makedirs(output_dir, exist_ok=True)

# --- CONTROL VISUAL DE DETALLES ---
# True: Muestra barras de error y réplicas estocásticas de fondo.
# False: Gráfica limpia (solo medias y curvas de ajuste). Ideal para comparar tendencias.
PROBAR_DETALLE = False

# Configura aquí el sufijo del bloque que quieras graficar a la vez:
# '_cte' para la Opción A | '_calib' para la Opción B
SUFIJO_MODO = '_calib'  

# Diccionario con la ruta de los archivos generados por tu Fortran
archivos_config = {
    900:  f'./resultados_900{SUFIJO_MODO}.txt',
    1225: f'./resultados_1225{SUFIJO_MODO}.txt',
    1600: f'./resultados_1600{SUFIJO_MODO}.txt'
}

# Función de ajuste: Sigmoide (Distribución de Fermi-Dirac)
def func(x, alpha_c, delta):
    return 1.0 / (1.0 + np.exp((x - alpha_c) / delta))

# --- INICIALIZACIÓN DE LA GRÁFICA ---
fig, ax = plt.subplots(figsize=(11, 8))
plt.xlim(0.0, 0.22)  # Límites lógicos del eje X para centrar la atención en la transición
plt.ylim(-0.05, 1.05) 

# Variable auxiliar para calcular el rango continuo del plot teórico
max_alpha_observado = 0.20

# --- PROCESAMIENTO E ITERACIÓN POR RED ---
print(f"Generando gráfica unificada para el modo: {SUFIJO_MODO}\n" + "-"*50)

for N, ruta_archivo in archivos_config.items():
    if not os.path.exists(ruta_archivo):
        print(f"Aviso: No se encuentra el archivo {ruta_archivo}. Saltando red N = {N}.")
        continue
        
    try:
        # 1. Lectura de datos
        raw_data = pd.read_csv(ruta_archivo, sep='\s+', header=None)
        patrones = raw_data.iloc[:, 0].values
        replicas = raw_data.iloc[:, 1:6].values
        
        # Cambio de variable físico: Carga de la red (alpha = P/N)
        alpha_data = patrones / float(N)
        max_alpha_observado = max(max_alpha_observado, alpha_data.max())
        
        # 2. Estadística de las réplicas
        y_mean = np.mean(replicas, axis=1)
        y_std = np.std(replicas, axis=1, ddof=1)
        u_A = y_std / np.sqrt(5)
        u_A[u_A == 0.0] = 1e-4  # Suelo para evitar singularidades
        
        # 3. Ajuste no lineal ponderado
        guess = [0.14, 0.01]
        popt, pcov = curve_fit(func, alpha_data, y_mean, p0=guess, sigma=u_A, absolute_sigma=True)
        error = np.sqrt(np.diag(pcov))
        
        # Coeficiente R²
        y_pred = func(alpha_data, *popt)
        ss_res = np.sum(((y_mean - y_pred) / u_A) ** 2)
        ss_tot = np.sum(((y_mean - np.mean(y_mean)) / u_A) ** 2)
        r_squared = 1 - (ss_res / ss_tot)
        
        print(f'Red N = {N}:')
        print(f'  alpha_c = {popt[0]:.5f} ± {error[0]:.5f} | Delta = {popt[1]:.5f} ± {error[1]:.5f} | R² = {r_squared:.5f}')
        
        # 4. Inserción de elementos gráficos de la red actual
        x_fit = np.linspace(0.0, 0.25, 300)
        y_fit_line = func(x_fit, *popt)
        
        cfg = colors_redes[N]
        label_leyenda = (f"{cfg['label']}\n"
                         f"$\\alpha_c = {popt[0]:.4f} \\pm {error[0]:.4f}$\n"
                         f"$\\Delta = {popt[1]:.4f}$\n"
                         f"$R^2 = {r_squared:.4f}$")
        
        # Representación opcional de la dispersión estocástica cruda
        if PROBAR_DETALLE:
            for r in range(5):
                ax.scatter(alpha_data, replicas[:, r], color=color_replicas, alpha=0.12, s=8, zorder=2)
            ax.errorbar(alpha_data, y_mean, yerr=u_A, fmt='o', color=cfg['puntos'], 
                        ecolor=color_teorica, capsize=3, markersize=5, zorder=4)
        else:
            ax.scatter(alpha_data, y_mean, color=cfg['puntos'], s=35, zorder=4)
            
        ax.plot(x_fit, y_fit_line, linestyle='--', color=cfg['linea'], linewidth=2.2, 
                label=label_leyenda, zorder=5)
                
    except Exception as e:
        print(f"Error procesando los datos de la red N = {N}: {e}")

# --- CURVA TEÓRICA ANALÍTICA DE REFERENCIA (LÍMITE AGS) ---
x_teorico = np.linspace(0.0, max_alpha_observado * 1.05, 400)
y_teorico = np.where(x_teorico < 0.138, 1.0, 0.0)
ax.plot(x_teorico, y_teorico, linestyle=':', color=color_teorica, linewidth=2.8, 
        label='Límite Teórico Absoluto\n(AGS, $\\alpha_c \\approx 0.138$)', zorder=3)

# --- ESTÉTICA GENERAL ---
ax.set_xlabel("Carga de la red ($\\alpha = P/N$)", fontsize=label_size)
ax.set_ylabel("Solapamiento final medio ($\\overline{m}$)", fontsize=label_size)
ax.tick_params(axis='both', which='major', labelsize=tick_size)

ax.grid(True, which='both', linestyle='--', alpha=0.25)
ax.legend(loc='lower left', fontsize=legend_size, frameon=True, ncol=2) # ncol=2 distribuye las leyendas en dos columnas

plt.tight_layout()

# Guardado automático con identificador de modo
nombre_salida = f'comparativa_redes{SUFIJO_MODO}.png'
plt.savefig(os.path.join(output_dir, nombre_salida), dpi=300)
print(f"-"*50 + f"\nGráfica guardada con éxito en: {output_dir}/{nombre_salida}")

plt.show()