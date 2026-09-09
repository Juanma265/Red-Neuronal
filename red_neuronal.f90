program red_neuronal

    implicit none
    
    integer :: i,j,k,l,y,len, N, sum_patron, n1, n2, neu, patrones, opcion1, opcion2, max_patrones, rep
    real :: promedio, correcion, T, dE, p ,r, campo_local, aux, ruido
    real :: solapamientos_fila(5)
    real, allocatable :: umbral(:), w(:,:), sum2(:), m(:)
    integer, allocatable :: patron(:,:,:), s(:,:), s_1d(:), p_2d(:,:)

    print *, "Size of the pattern (len x len):"
    
    read (*,*) len

    N=len*len! Número total de neuronas en la red
    max_patrones = 200! Número máximo de patrones a almacenar, ajustado a la cantidad de patrones disponibles

    !print *, "Ingrese temperatura (T):"

    !read (*,*) T

    T=0.0375 ! Temperatura fija a cero para la dinámica determinista

    !print *, "Numero de patrones:"
    !read (*,*) patrones

    !print *, "Patrones aleatorios (0) patrones definidos (1):"
    !read (*,*) opcion1

    opcion1 = 0 ! Fijar la opción a 0 para generar patrones aleatorios

    !print *, "Comienzo aleatorio (0) o con ruido (1):"
    !read (*,*) opcion2

    opcion2 = 1 ! Fijar la opción a 1 para comenzar con el primer patrón y agregar ruido

   

    !if (opcion2 == 1) then
        !print *, "Ingrese el porcentaje de ruido (entre 0 y 100):"
        !read (*,*) ruido
        !ruido = ruido / 100.0 ! Convertir el porcentaje a un valor entre 0 y 1
    !end if

    ruido = 0.12 ! Fijar el porcentaje de ruido al 16% para la dinámica con ruido

    allocate (patron(len, len, max_patrones), w(N, N), umbral(N), s(len, len), s_1d(N), p_2d(N,max_patrones), sum2(max_patrones), m(max_patrones))
    open (2, file='solapamiento.txt', status='replace')
    open (3, file='configuraciones.txt', status='replace')
    open (4, file='resultados.txt', status='replace')

    do patrones = 1, max_patrones, 5
        
        solapamientos_fila = 0.0 ! Inicializar el array de solapamientos
        do rep = 1, 5 ! Realizar 5 repeticiones para cada cantidad de patrones

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
                        sum_patron = sum_patron + patron(i, j, k) ! Suma de los elementos del patrón para calcular el promedio
                    end do
                end do
            end do

            promedio = (real(sum_patron)) / (N*patrones) ! Promedio de los elementos del patrón

            ! Calcular la matriz de pesos utilizando la regla de Hebb

            correcion = 1.0/(N*promedio*(1.0-promedio)) ! Factor de corrección para normalizar los pesos

            w = 0.0 ! Inicializar la matriz de pesos a cero
            
            do y=1, patrones
                do i = 1, len
                    do j = 1, len
                        ! Índice lineal de la neurona 1
                        n1 = (i-1)*len + j
                        do k = 1, len
                            do l = 1, len
                                ! Índice lineal de la neurona 2
                                n2 = (k-1)*len + l
                                w(n1, n2) = w(n1, n2) + correcion * (patron(i,j,y) - promedio) * (patron(k,l,y) - promedio)
                            end do      
                        end do
                    end do
                end do
            end do

            do i = 1,N
                w(i, i) = 0.0 ! Eliminar las autoconexiones
            end do

            aux = 0.0

            do i=1,N
                do j=1, N
                    aux = aux + w(i, j) ! Suma de los pesos para calcular el umbral
                end do
                umbral(i) = aux * 0.5
                aux = 0.0 ! Reiniciar la suma para el siguiente umbral
            end do

            

            s = 0 ! Inicializar la matriz de estado de las neuronas a cero
            CALL RANDOM_SEED()
            
            if (opcion2 == 1) then
                do i=1,len
                    do j=1, len
                        s(i,j)= patron(i,j,1) ! Comenzar con el primer patrón
                    end do
                end do
                do i=1, len
                    do j=1, len
                        CALL RANDOM_NUMBER(p)
                        if (p < ruido) then
                            s(i,j) = 1 - s(i,j)
                        else
                            s(i,j) = s(i,j)
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
            

            !Pasar matriz s a 1 dimension
            do i=1, len
                do j=1, len
                    s_1d((i-1)*len + j) = s(i, j)
                end do
            end do 

            !Pasar el patrón a 2 dimensiones para facilitar los cálculos posteriores
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
                    sum2(i) = sum2(i) + (p_2d(j,i)-promedio)*(s_1d(j)-0.5)  ! Suma de las neuronas activas 
                end do
            end do

            ! Algoritmo de actualizacion de la red 

            do i=1,500*N ! Número total de iteraciones para la dinámica de la red
                CALL RANDOM_NUMBER(p)
                neu = INT(p*N) + 1

                campo_local = dot_product(w(neu, :), real(s_1d)) ! Calcular el campo local que recibe la neurona seleccionada

                if (s_1d(neu) == 1) then
                    dE = campo_local - umbral(neu) ! Calcular el cambio de energía si la neurona se activa
                else
                    dE = umbral(neu) - campo_local ! Calcular el cambio de energía si la neurona se desactiva
                end if


                if (T==0.0) then
                    if (dE <= 0.0) then
                        if (s_1d(neu) == 0) then
                            ! Pasamos de 0 a 1: la suma aumenta en 1.0 * (p - promedio)
                            do k=1, patrones
                                sum2(k) = sum2(k) + (p_2d(neu, k) - promedio) ! Actualizar la suma para cada patrón
                            end do
                        else
                            ! Pasamos de 1 a 0: la suma disminuye en 1.0 * (p - promedio)
                            do k=1, patrones
                                sum2(k) = sum2(k) - (p_2d(neu, k) - promedio) ! Actualizar la suma para cada patrón
                            end do
                        end if
                        s_1d(neu) = 1 - s_1d(neu) ! Aceptar el cambio a temperatura cero
                    end if
                else

                    CALL RANDOM_NUMBER(r)
                    if (dE <= 0.0 .or. r < EXP(-dE/T)) then
                        
                        if (s_1d(neu) == 0) then
                            ! Pasamos de 0 a 1: la suma aumenta en 1.0 * (p - promedio)
                            do k=1, patrones
                                sum2(k) = sum2(k) + (p_2d(neu, k) - promedio) ! Actualizar la suma para cada patrón
                            end do
                        else
                            ! Pasamos de 1 a 0: la suma disminuye en 1.0 * (p - promedio)
                            do k=1, patrones
                                sum2(k) = sum2(k) - (p_2d(neu, k) - promedio) ! Actualizar la suma para cada patrón
                            end do
                        end if
                        ! Realizamos el cambio físico
                        s_1d(neu) = 1 - s_1d(neu)
                    end if
                end if

                !if (mod(i, N) == 0) then
                    !write(3,*) s_1d ! Guardar la configuración actual de la red en el archivo
                !end if

                !Descomentar para guardar el solapamiento cada 2*N iteraciones
                !if (mod(i, 2*N) == 0) then
                    !do k=1, patrones
                        !write(2,*) i, correcion*sum2(k) ! Guardar el solapamiento actual en el archivo
                    !end do
                !end if

                campo_local = 0.0 ! Reiniciar el peso para la siguiente iteración
            end do

            solapamientos_fila(rep) = correcion * sum2(1) ! Guardar el solapamiento final para el primer patrón en el array de resultados


        end do

        
        write(4,*) patrones, solapamientos_fila(1), solapamientos_fila(2), solapamientos_fila(3), solapamientos_fila(4), solapamientos_fila(5)

        !Solo guardar el solapamiento final después de completar todas las iteraciones
        !do y = 1, patrones
            !write(2,*) patrones, y, correcion*sum2(y) 
        !end do


    end do

close(2)
close(3)
close(4)
    
end program red_neuronal