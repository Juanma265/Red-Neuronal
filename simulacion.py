import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation

L = 30
ARCHIVO = 'configuraciones.txt'

def animar_evolucion():
    try:
        print(f"Leyendo {ARCHIVO}...")
        # Usamos engine='python' por si el archivo es muy grande
        datos = np.loadtxt(ARCHIVO)
        
        # Si solo hay una línea, loadtxt devuelve un vector 1D. 
        # Forzamos a 2D para que datos[frame, :] siempre funcione.
        if datos.ndim == 1:
            datos = datos.reshape((1, -1))
            
        num_frames = datos.shape[0]
        print(f"Frames cargados: {num_frames}")

        fig, ax = plt.subplots(figsize=(6, 6))
        
        # Preparamos la imagen inicial
        img_data = datos[0, :].reshape((L, L))
        im = ax.imshow(img_data, cmap='binary', interpolation='nearest')
        ax.axis('off')
        
        # Texto para el contador de pasos
        txt_paso = ax.text(0.05, 0.95, '', transform=ax.transAxes, color='red', fontsize=12)

        def update(frame):
            nueva_config = datos[frame, :].reshape((L, L))
            im.set_array(nueva_config)
            txt_paso.set_text(f"Paso: {frame + 1}/{num_frames}")
            # Devolvemos una lista de lo que cambia
            return [im, txt_paso]

        # REGLA DE ORO: blit=False suele dar menos problemas al principio
        ani = animation.FuncAnimation(
            fig, update, frames=num_frames, 
            interval=200, blit=False, repeat=True
        )

        return ani # Mantenemos el objeto vivo

    except Exception as e:
        print(f"Vaya, algo ha fallado: {e}")
        return None

if __name__ == "__main__":
    mi_animacion = animar_evolucion()
    if mi_animacion:
        plt.show()