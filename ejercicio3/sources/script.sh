#!/bin/bash

mostrar_ayuda(){
    echo "Ayuda"
}

validar_parametros(){
    #echo "Validando parametros"
    #echo $1 $2
    return 0
}

contar_lineas(){
    #echo "contando lineas"
    #echo $1;
    echo "Conteo del archivo: " $1
}
AWKscript='
BEGIN{
	codigo = 0
	comentario = 0
	FS = ""
	dentro_de_bloque_comentario = 0
	total = 0;
	sin_lineas_vacias = 0;
}/(\/\*)|(\*\/)|(\/\/)/{
	contiene_codigo = 0
	contiene_comentario = 0
	dentro_de_string = 0
	total++;
	# Si apenas comienza la linea, ya se encontraba en un bloque de comentario
	# por una linea anterior, entonces ya se sabe que esta linea debe contar
	# como comentario. Se debe seguir leyendo en caso de encontrar codigo mas adelante
	if(dentro_de_bloque_comentario){
		contiene_comentario = 1;
	}

	for(i=1;i<=NF;i++){
		if(!dentro_de_bloque_comentario){
			############################################
			# Me encuentro en una linea comun		   #
			# Validacion de comentario por doble Slash #
			############################################

			# Si encontro una doble Slash y no estoy en un string
			if($i == "/" && $(i+1) == "/" && !dentro_de_string){
				contiene_comentario = 1;
				break;
			}
			else if($i == "/" && $(i+1) == "*" && !dentro_de_string){
				dentro_de_bloque_comentario = 1;
				contiene_comentario = 1;
				i =  i + 2; # Como ya se sabe que el proximo caracter es un asterisco, se pueden avanzar dos posiciones
			}
			# Si lo que encontro son caracteres comunes y no espacios o tabulaciones
			else if($i != "\t" && $i != " "){
				# Me encuentro dentro de codigo
				contiene_codigo = 1;
				# Si no estoy dentro de un string, y encuentro un inicio de string,
				# levanto flag de string para ignorar apertura de comentarios
				if(!dentro_de_string && $i == "\""){
					dentro_de_string = 1;
				}
				# Si me encuentro dentro de un string, y encuentro caracter de cierre de string
				else if(dentro_de_string && $i == "\""){
					dentro_de_string = 0;
				}
			}
			# Los espacios y tabulaciones en el codigo no aportan informacion relevante
			# en las lineas en las que ya se sabe que aparece doble Slash(\\), 
			# apertura de comentario(\*) y/o cierre de comentario(*\)
		}
		else{
			#################################################
			# Me encuentro dentro de un bloque comentario   #
			# Validacion de comentario por cierre de bloque #
			#################################################
			if($i == "*" && $(i+1) == "/"){
				dentro_de_bloque_comentario = 0;
				i =  i + 2; # Como ya se sabe que el proximo caracter es un Slash, se pueden avanzar dos posiciones
			}
		}
	}
	if(contiene_codigo){
		codigo++;
	}
	if(contiene_comentario){
		comentario++;
	}
}!/(\/\*)|(\*\/)|(\/\/)/{
	linea = 1; # Por defecto, la linea se cuenta
	
	# Si la linea solo se debe contar cuando tenga caracteres
	# distintos a los espacios en blanco y tabulaciones, se busca la
	# primera aparicion en la cadena para que la misma cuente como valida.
	# De lo contrario, el valor de la linea es 0 (invalida para contar)
	if(sin_lineas_vacias){
		linea = 0;
		for(i=1;i<=NF;i++){
			if($i != "/t" && $i != " "){
				linea = 1;
				break;
			}
		}
	}

	if(dentro_de_bloque_comentario){
		comentario = comentario + linea;
	}
	else{
		codigo = codigo + linea;
	}
	total = total + linea;

}END{
	print total, comentario, codigo;
	#print total
	#print comentario
	#print codigo
}'

analizar_archivos() {
    lineasTotal=0;
    codigoTotal=0;
    comentarioTotal=0;
    analizados=0;
    local directorio=$1;
    local extension=$2;
    find $directorio -type f -name "*.$extension" -print0 | 
    {
        while IFS= read -r -d '' archivo; do
            analizados=$((analizados+1));
            ##############################################################################
            # Adicionalmente, se puede cargar el script de AWK desde un archivo adicional#
            # "AWKscript" comentando la siguiente linea y descomentando la posterior     #
            ##############################################################################
            read lineas comentario codigo <<< $(awk "$AWKscript" "$archivo");
            #read lineas comentario codigo <<< $(awk -f AWKscript "$archivo");
            lineasTotal=$((lineasTotal+lineas));
            codigoTotal=$((codigoTotal+codigo));
            comentarioTotal=$((comentarioTotal+comentario));
            
        done
        echo "Total de archivos analizados: "$analizados;
        echo "Total de lineas analizadas: "$lineasTotal
        echo "Total de comentarios: "$comentarioTotal
        echo "Total de codigo encontrado: "$codigoTotal
    }
}

if [[ $# -gt 2 ]];
then
    echo "Demasiados argumentos para la operación.";
    echo "Puede revisar la informacion con -h, -? o --help.";
elif [[ $# -eq 2 ]];
then
    validar_parametros $1 $2
    if [[ $? -eq 0 ]]
    then
        #contar_lineas $1 $2
        # find $1 -type f -name "*$2" -exec awk -f cmtBlock {} \;
        #find $1 -type f -name "*$2" -exec contar_lineas {} \;
        analizar_archivos $1 $2
    else
        echo "Los parametros enviados no son validos, ¿ha ingresado una sintaxis correcta?";
        echo "Puede revisar la informacion con -h, -? o --help.";
    fi
elif [[ $# -eq 1 ]];
then
    if [[ "$1" == "-h" ]] || [[ "$1" == "-H" ]] || [[ "$1" == "-?" ]] || [[ "$1" == "--help" ]] || [[ "$1" == "--HELP" ]]
    then
        mostrar_ayuda
    else
        echo "La opcion $1 no existe.";
        echo "Puede revisar la informacion con -h, -? o --help.";
    fi    
else [[ $# -eq 0 ]];
    echo "Faltan argumentos para ejecutar la operación, ¿ha ingresado una sintaxis correcta?";
    echo "Puede revisar la informacion con -h, -? o --help.";
fi
