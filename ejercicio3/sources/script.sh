#!/bin/sh
#ls $1 | grep "\.$2$"

mostrar_ayuda(){
    echo "Ayuda"
}

validar_parametros(){
    echo "Validando parametros"
    echo $1 $2
    return 0
}

contar_lineas(){
    
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
        contar_lineas $1 $2
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
