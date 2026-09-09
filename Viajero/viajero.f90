program viajero

    implicit none

    integer :: K = 10 
    real :: PI = 3.14159265
    real :: R_TIERRA = 6371.0 ! Radio medio de la Tierra en km
    real :: lat_rad, lon_rad
    integer :: i, j, aux

    real, allocatable :: latitud_grad(:), longitud_grad(:), coord_x(:), coord_y(:)
    real, allocatable :: D(:,:)  ! Matriz de distancias (normalizada)
    character(len=20), allocatable :: nombre_ciudad(:)

    ! Parámatres de la red neuronal 
    real :: A_param = 150.0    
    real :: B_param = 150.0     
    real :: C_param = 75.0     
    real :: D_param = 40.0     

    real :: d_max

    integer :: N_total
    integer :: x, y      ! Índices para ciudades (x,y) y paradas (i,j)
    integer :: idx_I, idx_J    ! Índices lineales mapeados
    integer :: i_mas_1, i_menos_1

   
    integer, parameter :: PASOS_MC = 5000  
    real :: T_actual
    real :: T_inicial = 2.0                
    real :: T_min = 0.0001
    real :: factor_enfriamiento = 0.998   
    
    integer, allocatable :: s(:)      
    real :: r, delta_E, h_local
    integer :: paso, neu

    real :: distancia_total
    integer, allocatable :: visitas_ciudad(:)
    integer :: ciudad_actual, ciudad_siguiente, paradas_validas
    logical :: ruta_perfecta

    real, allocatable :: W(:,:)
    real, allocatable :: umbral(:)

    integer, parameter :: N_experimentos = 1000 
    integer :: exp_id
    integer :: exitos
    real :: tasa_exito

    real :: mejor_distancia = 999999.0  ! Inicializamos con un valor enorme
    integer, allocatable :: mejor_configuracion(:)
   

    N_total = K * K  ! 10 * 10 = 100 neuronas total

    allocate(W(N_total, N_total), umbral(N_total))
    allocate(latitud_grad(K), longitud_grad(K), coord_x(K), coord_y(K), nombre_ciudad(K))
    allocate(D(K, K))
    allocate(s(N_total))
    allocate(visitas_ciudad(K))
    allocate(mejor_configuracion(N_total))

    exitos = 0
    
    ! 1. Lectura del archivo
    open(unit=1, file='capitales_ue.txt', status='old', action='read')
    do i = 1, K
        read(1, *) aux, nombre_ciudad(i), longitud_grad(i), latitud_grad(i)
        
        lon_rad = longitud_grad(i) * PI / 180.0
        lat_rad = latitud_grad(i) * PI / 180.0
        
        coord_x(i) = R_TIERRA * lon_rad * cos(lat_rad)
        coord_y(i) = R_TIERRA * lat_rad
    end do
    close(1)

    ! Cálculo de la matriz simétrica de distancias reales
    do i = 1, K
        do j = 1, K
            if (i == j) then
                D(i, j) = 0.0
            else
                D(i, j) = sqrt((coord_x(i) - coord_x(j))**2 + (coord_y(i) - coord_y(j))**2)
            end if
        end do
    end do

    ! Normalización de las distancias estilo Hopfield
    d_max = 0.0
    do i = 1, K
        do j = 1, K
            if (D(i, j) > d_max) d_max = D(i, j)
        end do
    end do
    if (d_max > 0.0) then
        D(:,:) = D(:,:) / d_max
    end if

    ! 2. Construcción matemática de la matriz W y Umbrales
    W(:,:) = 0.0
    umbral(:) = 0.0

    do x = 1, K
        do i = 1, K
            idx_I = (x - 1) * K + i
            umbral(idx_I) = C_param * real(K)

            i_mas_1 = i + 1
            if (i_mas_1 > K) i_mas_1 = 1
            i_menos_1 = i - 1
            if (i_menos_1 < 1) i_menos_1 = K

            do y = 1, K
                do j = 1, K
                    idx_J = (y - 1) * K + j

                    if (idx_I /= idx_J) then

                        if (x == y .and. i /= j) then
                            W(idx_I, idx_J) = W(idx_I, idx_J) - A_param
                        end if

                        if (i == j .and. x /= y) then
                            W(idx_I, idx_J) = W(idx_I, idx_J) - B_param
                        end if

                        W(idx_I, idx_J) = W(idx_I, idx_J) - C_param

                        if (x /= y .and. (j == i_mas_1 .or. j == i_menos_1)) then
                            W(idx_I, idx_J) = W(idx_I, idx_J) - D_param * D(x, y)
                        end if

                    end if
                end do
            end do
        end do
    end do

    ! Apertura del fichero estadístico de salida
    open(unit=3, file='estadistica_hopfield.dat', status='replace', action='write')
    

    ! Bucle para hacer varios experimentos
    do exp_id = 1, N_experimentos
        
        ! Reseteo de variables internas 
        visitas_ciudad(:) = 0
        distancia_total = 0.0
        ruta_perfecta = .true.
        paradas_validas = 0
        T_actual = T_inicial
        
        ! Inicialización aleatoria de espines
        do i = 1, N_total
            call random_number(r)
            if (r < 0.5) then
                s(i) = 0
            else
                s(i) = 1
            end if
        end do

        ! Metropolis 
        do paso = 1, PASOS_MC*N_total
                
            call random_number(r)
            neu = int(r * N_total) + 1
            if (neu > N_total) neu = N_total

            h_local = umbral(neu)
            do j = 1, N_total
                h_local = h_local + W(neu, j) * real(s(j))
            end do

            if (s(neu) == 1) then
                delta_E = h_local  
            else
                delta_E = -h_local 
            end if

            if (delta_E <= 0.0) then
                s(neu) = 1 - s(neu)
            else
                call random_number(r)
                if (r < exp(-delta_E / T_actual)) then
                    s(neu) = 1 - s(neu)
                end if
            end if
            
            if (mod(paso, N_total) == 0) then 
                if (T_actual > T_min) then
                    T_actual = T_actual * factor_enfriamiento
                end if
            end if
        end do

        ! Conteo de paradas
        do i = 1, K      
            do x = 1, K   
                idx_I = (x - 1) * K + i
                if (s(idx_I) == 1) then
                    visitas_ciudad(x) = visitas_ciudad(x) + 1
                    paradas_validas = paradas_validas + 1
                end if
            end do
        end do

        ! Comprobaciones
        do x = 1, K
            if (visitas_ciudad(x) /= 1) ruta_perfecta = .false.
        end do
        if (paradas_validas /= K) ruta_perfecta = .false.

        ! Registro en el archivo según convergencia
        if (ruta_perfecta) then
            exitos = exitos + 1
            
            ! Cálculo de la distancia total recorrida
            do i = 1, K
                do x = 1, K
                    if (s((x-1)*K + i) == 1) ciudad_actual = x
                end do
                i_mas_1 = i + 1
                if (i_mas_1 > K) i_mas_1 = 1
                do y = 1, K
                    if (s((y-1)*K + i_mas_1) == 1) ciudad_siguiente = y
                end do
                distancia_total = distancia_total + D(ciudad_actual, ciudad_siguiente)
            end do
            distancia_total = distancia_total * d_max 

            ! Filtro mejor ruta
            if (distancia_total < mejor_distancia) then
                mejor_distancia = distancia_total
                mejor_configuracion(:) = s(:)
            end if
            
            write(3,*) exp_id, paradas_validas, 1, distancia_total
        else
            ! Mínimo espurio 
            write(3, *) exp_id, paradas_validas, 0, -1.0
        end if

    end do
    close(3)


    tasa_exito = (real(exitos) / real(N_experimentos)) * 100.0

    print *, " Convergencias validas ", exitos
    print *, " Tasa de Éxito  : ", tasa_exito, " %"

    ! Guardado de la mejor ruta
    if (mejor_distancia < 999998.0) then
        open(unit=4, file='mejor_ruta.dat', status='replace')
        do i = 1, K  
            do x = 1, K 
                if (mejor_configuracion((x-1)*K + i) == 1) then
                    write(4, *) coord_x(x), coord_y(x)
                    print *, "  Parada ", i, ": ", trim(nombre_ciudad(x))
                end if
            end do
        end do
        close(4)
        print *, "Mejor distancia encontrada: ", mejor_distancia, " km"
    else
        print *, "No se encontró una ruta válida."
    end if


end program viajero