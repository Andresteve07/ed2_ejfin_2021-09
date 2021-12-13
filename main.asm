; TODO INSERT CONFIG CODE HERE USING CONFIG BITS GENERATOR
#include"" 
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    MAIN                   ; go to beginning of program
    ORG 0x04
	GOTO RUTINA_INTERR;

; TODO ADD INTERRUPTS HERE IF USED
CONT_VUELTAS_H EQU 0x1F1
CONT_VUELTAS_L EQU 0x1F0
REG_30 EQU 0x20
CORTAR_UART EQU 0x21
 
MAIN_PROG CODE                      ; let linker place main program

 
PASO_UNA_VUELTA:
   BCF OPTION_REG, INTD;
   INCF CONT_VUELTAS_L;
   BTFSC STATUS, Z;
   INCF CONT_VUELTAS_H;
   RETURN;

ENVIAR_PROX_8BITS:
    ;0x1F0 [1 1 1 1 0 0 0 0]
    ;0x01 [0 0 0 0 0 0 0 1] XOR
    ;0x1F1 [1 1 1 1 0 0 0 1]
    BCF PIR1, TXIF;
    BTFSC CORTAR_UART,1;si ya pase los dos valores corto
    RETURN
    MOVFW INDF;
    MOVWF TXREG;cuando se carga este reg inmediamente inicia la transmision
    MOVFW FSR; Hago el toggle del primer bit para cambiar el registro
    XORLW .1;
    MOVWF FSR;actualizo el puntero para la proxima
    INCF CORTAR_UART;
    RETURN
    
PASARON_2SEG:
    BCF PIR1, TMR1F;limpio la bandera del tmr1
    ;vuelvo a cargar la precarga del tmr1
    MOVLW 0x0B;
    MOVWF TMR1H;
    MOVLW 0xDC;
    MOVWF TMR1L;
    
    DECFSZ REG_30;
    RETURN;
    ;PASO UN MIUTOOOOO!!!!!!!
    CLRF CORTAR_UART;
    CALL ENVIAR_PROX_8BITS;
    MOVLW .30;
    MOVWF REG_30;
    RETURN;
   
RUTINA_INTERR:
    MOVWF TEMP_W
    SWAPF STATUS, W
    MOVWF TEMP_STATUS;SALVAMOS EL CONTEX
    
    BTFSC OPTION_REG, INTD;salto la int por rb0?
    CALL PASO_UNA_VUELTA;
       
    BTFSC PIR1, TMR1F;salta cuando pasan 2 segundos
    CALL PASARON_2SEG;
    
    BTFSC PIR1, TXIF;salta cuando finalizo el envio de los 8bits
    CALL ENVIAR_PROX_8BITS;
    
    ;Recuperamos el contexto
    SWAPF TEMP_STATUS, W
    MOVWF STATUS
    SWAPF TEMP_W, F
    SWAPF TEMP_W, W
    RETFIE;
    
CONFIG:
    CLRF CONT_VUELTAS_H;
    MOVLW .30;
    MOVWF REG_30;
    CLRF CORTAR_UART;
    
    CALL CONFIG_RB0;
    CALL CONFIG_UART;
    CALL CONFIG_TMR1;
    ;habilitar global
    RETURN;
MAIN
    CALL CONFIG;
BUCLE
    GOTO BUCLE;
    END