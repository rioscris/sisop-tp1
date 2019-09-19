#!/bin/bash

#############################################################################
#                   mostrar_ayuda()                                         #
#############################################################################
# Funcion a ser ejecutada tras recibir los parametros de ayuda              #
# nombre_script     -h | -H | -? | --help | --HELP                          #                            
#############################################################################
mostrar_ayuda(){
local ayuda='
    Algo
';
}

##############################################################################
#                   validacion_parametros()                                  #
##############################################################################
# Funcion para validar los comandos enviados al script.                      #                            
# - La extension no debe comenzar por punto. #                            
# - El directorio recibido debe ser valido y existente.                      #                            
##############################################################################
validar_parametros(){
    valido=0;
    if [[ ! -d $1 ]];
    then
        valido=1;       
    fi                                                         # En caso de que no exista el directorio, retorna 1
    # if [[ $2 =~ @"^[\w\-. ]+$" ]] && [[ $2 == \.* ]]         
    if [[ $2 == \.* ]]           # En caso de no ser una extension valida, retorna 2
    then
        valido=2;                                                
    fi
    echo $valido
    return $valido;
}

##################################################################################
#                   (variable global) AWKscript                                  #
##################################################################################
# Se realiza la busqueda de los caracteres especiales que puedan                 #
# que puedan delimitar un comentario: doble Slash(//), apertura de bloque(/*)    #
# y cierre de boque (*/).                                                        #
# En las lineas en las que se encuentre el patron, se empieza a recorrer         #
# cada caracter para verificar si se entra en un bloque, se esta en codigo, etc. #
# Adicionalmente, se puede setear la variable sin_lineas_vacias a 1(uno) para    #
# contarlas tambien en la cuenta total.                                          #
##################################################################################

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

#############################################################################
#                   analizar_archivos()                                     #
#############################################################################
# Funcion a ser ejecutada una vez se hayan validado los parametros.         #
# La misma recorre el directorio recursivamente y analiza con AWK cada uno  #
# de los archivos coincidentes con la extension.                            #
#############################################################################
analizar_archivos() {
    lineasTotal=0;
    codigoTotal=0;
    comentarioTotal=0;
    analizados=0;
local directorio=$1;                                                            # Tanto el directorio como la extension son recibidos 
local extension=$2;                                                             # por parametro y almacenados en variables locales.
    find $directorio -type f -name "*.$extension" -print0 |                     # Se realiza la busqueda recursiva desde el directorio recibido
    {
        while IFS= read -r -d '' archivo; do                                    # Se reescribe la variable IFS para evitar validar los casos en que el directorio
            analizados=$((analizados+1));                                       # figure con nueva linea o caracteres especiales.
                                                                                ###############################################################################
            read lineas comentario codigo <<< $(awk "$AWKscript" "$archivo");   # Adicionalmente, se puede cargar el script de AWK desde un archivo adicional #
            #read lineas comentario codigo <<< $(awk -f AWKscript "$archivo");  # "AWKscript" alternando la llamada comentada entre las dos lineas            #
                                                                                ###############################################################################
                                                                                # El script de AWK realiza el conteo y retorna los valores como stdout        
            lineasTotal=$((lineasTotal+lineas));                                # Esta salida se redirige mediante Here-Strings como entrada al stdin del read
            codigoTotal=$((codigoTotal+codigo));                                # posterior, el cual almacena los valores en variables para el calculo total.
            comentarioTotal=$((comentarioTotal+comentario));
            
        done
        echo "Total de archivos analizados: "$analizados;
        echo "Total de lineas analizadas: "$lineasTotal
        echo "Total de comentarios: "$comentarioTotal
        echo "Total de codigo encontrado: "$codigoTotal
        echo "---------------------------------"
        
        printf "Porcentaje de lineas de codigo: "
        porcentaje codigoTotal lineasTotal
        printf "Porcentaje de lineas de comentario: "
        porcentaje comentarioTotal lineasTotal
    }
}

#############################################################################
#                   porcentaje()                                            #
#############################################################################
# Calculo y visualizacion de porcentaje.                                    #
#                                                                           #
# porcentaje    valor_parcial   valor_total                                 #
#############################################################################
porcentaje(){
    parcial=$1;
    total=$2;
    if [[ $2 -eq 0 ]]
    then
        porcentaje=0;
    else
        porcentaje=$(( (parcial*100)/total ))
    fi
    echo $porcentaje
}

if [[ $# -gt 2 ]];
then
    echo "Demasiados argumentos para la operación.";
    echo "Puede revisar la informacion con -h, -? o --help.";
elif [[ $# -eq 2 ]];
then
    validar_parametros $1 $2
    if [[ $? -eq 1 ]]
    then
        echo "No se pudo validar el directorio. ¿Existe la ruta?";
        echo "Puede revisar la informacion con -h, -? o --help.";
    elif [[ $? -eq 2 ]]
    then
        echo "No se pudo validar la extension del archivo - verifique que sea correcta.";
        echo "Puede revisar la informacion con -h, -? o --help.";
    elif [[ $? -eq 0 ]]
    then
        echo "VALIDO"
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
