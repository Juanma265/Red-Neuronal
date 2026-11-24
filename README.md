# Hopfield Neural Network & Combinatorial Optimization (TSP)

This project implements and analyzes the **Hopfield** associative memory model for discrete variables $s_i \in \{0, 1\}$, evaluating its stochastic dynamics (Metropolis algorithm), critical storage capacity ($\alpha_c$), and application to combinatorial optimization in the **Traveling Salesman Problem (TSP)** using a modified Hopfield-Tank network.

> 📄 **Full Documentation:** The formal theoretical analysis, phase diagrams, and detailed derivations are available in [`docs/Red_Neuronal.pdf`](docs/Red_Neuronal.pdf) *(in Spanish)*.

---

## 1. Repository Structure

- **`docs/Red_Neuronal.pdf`**: Complete technical report of the project.
- **`red_neuronal.f90` / `red_neuronal_2.f90`**: Core simulation engine in Fortran 90. Implements the Hebbian learning rule, thermal overlap calculation $m^\mu$, and Metropolis sampling.
- **`simulacion.py` / `solapamiento.py`**: Python simulation control and interface scripts.
- **`Ajuste_Capacidad.py` / `Ajuste_Capacidad_3.py`**: Nonlinear sigmoid curve fitting (Fermi-Dirac statistics) to determine the maximum storage fraction $\alpha_c$.
- **`Viajero/`**: Dedicated module for solving the TSP:
  - `viajero.f90`: Implementation of the TSP Hamiltonian energy minimization using Simulated Annealing.
  - `viajero_data.py`: 2D route visualization and statistical convergence analysis over 1,000 iterations.
  - `capitales_ue.txt`: Coordinates of the 10 European capitals analyzed.

---

## 2. Physical & Methodological Aspects

- **Pattern Retrieval:** Hebbian learning and energy relaxation toward stable attractors via stochastic Glauber/Metropolis dynamics ($N=400$, $20\times20$ binary images).
- **Storage Limit ($\alpha_c$):** Systematic study of attractor basin collapse for $N \in \{900, 1225, 1600\}$. Sigmoid fit:
  $$\overline{m}(\alpha) = \frac{1}{1 + \exp\left(\frac{\alpha - \alpha_c}{\Delta}\right)}$$
  Validated against the theoretical Amit-Gutfreund-Sompolinsky limit ($\alpha_c \approx 0.138$).
- **Traveling Salesman Problem (TSP):** Hamiltonian formulation incorporating 4 geometric/physical constraints ($E_A, E_B, E_C, E_D$). Hyperparameter calibration for discrete systems ($A=B=150$, $C=75$, $D=40$) paired with a simulated annealing schedule ($\gamma = 0.998$), achieving $>94\%$ success rates with zero topological crossings.
