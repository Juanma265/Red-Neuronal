program red_neuronal

    implicit none
    
    integer :: i,j,k,l,y,len, N, sum_patron, n1, n2, neu, patrones, opcion1, opcion2, max_patrones, rep
    integer :: modo_estudio
    real :: promedio, correcion, T, dE, p ,r, campo_local, aux, ruido
    real :: solapamientos_fila(5)
    real, allocatable :: umbral(:), w(:,:), sum2(:), m(:)
    integer, allocatable :: patron(:,:,:), s(:,:), s_1d(:), p_2d(:,:)
    character(len=40) :: archivo_salida


    print *, "  (1) Opcion A: Parametros constantes (T=0.02, Ruido=0.12)"
    print *, "  (2) Opcion B: Calibracion individual por tamano (AGS)"
    read (*,*) modo_estudio

    print *, "Size of the pattern (len x len) [30, 35 o 40]:"
    read (*,*) len

    N = len * len ! Número total de neuronas en la red

    ! Asignación dinámica de parámetros y nombres de archivo según las opciones elegidas
    if (modo_estudio == 1) then
        ! Opcion A: Parametros constantes
        T = 0.04
        ruido = 0.12
        if (len == 30) then
            max_patrones = 150
            archivo_salida = 'resultados_900_cte.txt'
        else if (len == 35) then
            max_patrones = 200
            archivo_salida = 'resultados_1225_cte.txt'
        else
            max_patrones = 260
            archivo_salida = 'resultados_1600_cte.txt'
        end if
    else
       ! Opcion B: Calibración individual por tamaño
        if (len == 30) then
            T = 0.04
            ruido = 0.18
            max_patrones = 150
            archivo_salida = 'resultados_900_calib.txt'
        else if (len == 35) then
            T = 0.02
            ruido = 0.12
            max_patrones = 200
            archivo_salida = 'resultados_1225_calib.txt'
        else
            T = 0.035
            ruido = 0.08  ! Aplicamos tu ajuste fino del 16% para clavar el 0.138
            max_patrones = 260
            archivo_salida = 'resultados_1600_calib.txt'
        end if
    end if

    print *, "--> Ejecutando red N =", N, "con T =", T, "y Ruido =", ruido
    print *, "--> Guardando en archivo:", trim(archivo_salida)

    ! Fijar opciones lógicas internas
    opcion1 = 0 ! Patrones aleatorios
    opcion2 = 1 ! Comenzar con patrón + ruido

    allocate (patron(len, len, max_patrones), w(N, N), umbral(N), s(len, len), s_1d(N), p_2d(N,max_patrones), sum2(max_patrones), m(max_patrones))
    open (2, file='solapamiento.txt', status='replace')
    open (3, file='configuraciones.txt', status='replace')
    open (4, file=trim(archivo_salida), status='replace')

    do patrones = 1, max_patrones, 5
        
        solapamientos_fila = 0.0 
        do rep = 1, 5 

            if (opcion1 == 0) then
                open (1, file='patron.txt', status='replace')
                do i = 1, patrones
                    do j = 1, len 
                        do k = 1, len
                            call RANDOM_NUMBER(r)
                            if (r < 0.5) then
                                patron(j, k, i) = 0
                            else
                                patron(j, k, i) = 1
                            end if
                        end do
                        write(1,*) patron(:, j , i) 
                    end do
                end do
            else
                open (1, file='patron.txt', status='old')
                do i = 1, patrones
                    do j = 1, len 
                        read (1,*) patron(j, : , i)
                    end do
                end do
            end if
            close(1)

            ! Calcular el promedio del patrón
            sum_patron = 0
            do k=1, patrones
                do i=1, len
                    do j=1, len
                        sum_patron = sum_patron + patron(i, j, k) 
                    end do
                end do
            end do

            promedio = (real(sum_patron)) / (N*patrones) 

            ! Calcular la matriz de pesos (Regla de Hebb)
            correcion = 1.0/(N*promedio*(1.0-promedio)) 
            w = 0.0 
            
            do y=1, patrones
                do i = 1, len
                    do j = 1, len
                        n1 = (i-1)*len + j
                        do k = 1, len
                            do l = 1, len
                                n2 = (k-1)*len + l
                                w(n1, n2) = w(n1, n2) + correcion * (patron(i,j,y) - promedio) * (patron(k,l,y) - promedio)
                            end do      
                        end do
                    end do
                end do
            end do

            do i = 1,N
                w(i, i) = 0.0 ! Eliminar autoconexiones
            end do

            aux = 0.0
            do i=1,N
                do j=1, N
                    aux = aux + w(i, j) 
                end do
                umbral(i) = aux * 0.5
                aux = 0.0 
            end do

            s = 0 
            CALL RANDOM_SEED()
            
            if (opcion2 == 1) then
                do i=1,len
                    do j=1, len
                        s(i,j)= patron(i,j,1) 
                    end do
                end do
                do i=1, len
                    do j=1, len
                        CALL RANDOM_NUMBER(p)
                        if (p < ruido) then
                            s(i,j) = 1 - s(i,j)
                        end if
                    end do
                end do   
            else
                do i=1, len
                    do j=1, len
                        CALL RANDOM_NUMBER(p)
                        if (p < 0.5) then
                            s(i,j) = 0
                        else
                            s(i,j) = 1
                        end if
                    end do
                end do
            end if
            
            ! Pasar matriz s a 1 dimension
            do i=1, len
                do j=1, len
                    s_1d((i-1)*len + j) = s(i, j)
                end do
            end do 

            ! Pasar el patrón a 2 dimensiones
            do i=1, patrones
                do j=1, len
                    do k=1, len
                        p_2d((j-1)*len + k, i) = patron(j, k, i)
                    end do
                end do
            end do

            dE=0.0
            campo_local = 0.0
            m=0.0
            sum2 = 0.0

            do i=1, patrones
                do j=1, N
                    sum2(i) = sum2(i) + (p_2d(j,i)-promedio)*(s_1d(j)-0.5) 
                end do
            end do

            ! Metropolis 
            do i=1,500*N 
                CALL RANDOM_NUMBER(p)
                neu = INT(p*N) + 1

                campo_local = dot_product(w(neu, :), real(s_1d)) 

                if (s_1d(neu) == 1) then
                    dE = campo_local - umbral(neu) 
                else
                    dE = umbral(neu) - campo_local 
                end if

                if (T==0.0) then
                    if (dE <= 0.0) then
                        if (s_1d(neu) == 0) then
                            do k=1, patrones
                                sum2(k) = sum2(k) + (p_2d(neu, k) - promedio) 
                            end do
                        else
                            do k=1, patrones
                                sum2(k) = sum2(k) - (p_2d(neu, k) - promedio) 
                            end do
                        end if
                        s_1d(neu) = 1 - s_1d(neu) 
                    end if
                else
                    CALL RANDOM_NUMBER(r)
                    if (dE <= 0.0 .or. r < EXP(-dE/T)) then
                        if (s_1d(neu) == 0) then
                            do k = 1, patrones
                                sum2(k) = sum2(k) + (p_2d(neu, k) - promedio)
                            end do
                        else
                            do k = 1, patrones
                                sum2(k) = sum2(k) - (p_2d(neu, k) - promedio)
                            end do
                        end if
                        s_1d(neu) = 1 - s_1d(neu)
                    end if
                end if
                campo_local = 0.0 
            end do

            solapamientos_fila(rep) = correcion * sum2(1) 

        end do

        write(4,*) patrones, solapamientos_fila(1), solapamientos_fila(2), solapamientos_fila(3), solapamientos_fila(4), solapamientos_fila(5)

    end do

    close(2)
    close(3)
    close(4)
        
end program red_neuronal