# Red Neuronal de Hopfield y Optimización Combinatoria (TSP)

Este proyecto implementa y analiza el modelo de memoria asociativa de **Hopfield** para variables discretas $s_i \in \{0, 1\}$, evaluando su dinámica estocástica (algoritmo de Metrópolis), la capacidad crítica de almacenamiento ($\alpha_c$) y su aplicación a la optimización combinatoria en el **Problema del Viajero (TSP)** mediante la red de Hopfield-Tank modificada.

> 📄 **Documentación completa:** El análisis teórico formal, diagramas de fases y deducciones detalladas están disponibles en [`docs/Red_Neuronal.pdf`](docs/Red_Neuronal.pdf).

---

## 1. Estructura del Repositorio

* **`docs/Red_Neuronal.pdf`**: Memoria técnica completa del proyecto.
* **`red_neuronal.f90` / `red_neuronal_2.f90`**: Núcleo de simulación en Fortran 90. Implementa la regla de Hebb, el cálculo de solapamiento térmico $m^\mu$ y el muestreo de Metrópolis.
* **`simulacion.py` / `solapamiento.py`**: Scripts de interfaz y control de simulación en Python.
* **`Ajuste_Capacidad.py` / `Ajuste_Capacidad_3.py`**: Ajuste no lineal de curvas sigmoides (estadística de Fermi-Dirac) para la obtención de la fracción máxima de almacenamiento $\alpha_c$.
* **`Viajero/`**: Módulo dedicado a la resolución del TSP:
  * `viajero.f90`: Implementación de la minimización energética del Hamiltoniano del TSP con Simulated Annealing.
  * `viajero_data.py`: Visualización 2D de las rutas y análisis estadístico de convergencia tras 1000 iteraciones.
  * `capitales_ue.txt`: Coordenadas de las 10 capitales europeas analizadas.

---

## 2. Aspectos Físicos y Metodológicos

* **Recuperación de Patrones:** Aprendizaje hebbiano y relajación energética hacia atractores estables mediante dinámica estocástica de Glauber/Metrópolis ($N=400$, imágenes de $20\times20$).
* **Límite de Almacenamiento ($\alpha_c$):** Estudio sistemático del colapso de las cuencas de atracción para $N \in \{900, 1225, 1600\}$. Ajuste sigmoide:
  $$\overline{m}(\alpha) = \frac{1}{1 + \exp\left(\frac{\alpha - \alpha_c}{\Delta}\right)}$$
  Validación con el límite teórico de Amit-Gutfreund-Sompolinsky ($\alpha_c \approx 0.138$).
* **Problema del Viajero (TSP):** Formulación del Hamiltoniano con 4 restricciones geométricas/físicas ($E_A, E_B, E_C, E_D$). Calibración de hiperparámetros para sistemas discretos ($A=B=150$, $C=75$, $D=40$) junto a un esquema de enfriamiento simulado ($\gamma = 0.998$), alcanzando tasas de éxito $>94\%$ sin cruces topológicos.

