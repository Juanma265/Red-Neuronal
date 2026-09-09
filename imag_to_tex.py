import numpy as np
from PIL import Image
import os
import glob

# --- CONFIGURACIÓN ---
CARPETA_ENTRADA = "imagenes_entrada"  # Mete aquí todas tus imágenes
ARCHIVO_SALIDA = "patron.txt"         # Un solo archivo con todos los patrones
TAMANO = (30, 30)
UMBRAL = 128

def procesar_multiples_imagenes():
    # 1. Crear la carpeta si no existe
    if not os.path.exists(CARPETA_ENTRADA):
        os.makedirs(CARPETA_ENTRADA)
        print(f"He creado la carpeta '{CARPETA_ENTRADA}'. Mete allí tus imágenes y vuelve a ejecutar.")
        return

    # 2. Buscar extensiones comunes
    extensiones = ('*.png', '*.jpg', '*.jpeg', '*.bmp')
    archivos = []
    for ext in extensiones:
        archivos.extend(glob.glob(os.path.join(CARPETA_ENTRADA, ext)))

    if not archivos:
        print(f"No hay imágenes en '{CARPETA_ENTRADA}'.")
        return

    # 3. Limpiar el archivo de salida antes de empezar (sobrescribir)
    if os.path.exists(ARCHIVO_SALIDA):
        os.remove(ARCHIVO_SALIDA)

    print(f"Procesando {len(archivos)} imágenes...")

    # 4. Procesar cada imagen y añadirla (append) al archivo
    with open(ARCHIVO_SALIDA, "ab") as f_salida:
        for ruta in sorted(archivos):
            try:
                with Image.open(ruta) as img:
                    # Convertir, redimensionar y binarizar
                    img_gris = img.convert('L')
                    img_res = img_gris.resize(TAMANO, Image.Resampling.LANCZOS)
                    data = np.array(img_res)
                    matriz_binaria = (data < UMBRAL).astype(int)

                    # Guardar en el mismo archivo (añadiendo al final)
                    np.savetxt(f_salida, matriz_binaria, fmt='%d', delimiter=' ')
                    
                    print(f"  [OK] {os.path.basename(ruta)}")
            except Exception as e:
                print(f"  [ERROR] No se pudo procesar {ruta}: {e}")

    print(f"\n¡Éxito! Todos los patrones están en '{ARCHIVO_SALIDA}'.")

if __name__ == "__main__":
    procesar_multiples_imagenes()