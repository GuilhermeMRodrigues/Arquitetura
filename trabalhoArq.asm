.386
.model flat, stdcall
option casemap :none

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\user32.inc
include \masm32\include\masm32.inc
include \masm32\include\msvcrt.inc
include \masm32\macros\macros.asm
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\user32.lib
includelib \masm32\lib\masm32.lib
includelib \masm32\lib\msvcrt.lib

.data

;-----------------------Mensagens Definidas Para o Usuario---------------





mensagem1 db "Digite a quantidade de Notas:",0ah,0h ;mensagem para o usuario
mensagem2 db "digite a nota",0
mensagem3 db ":",0h
mensagem_4 db "Aluno reprovado"
mensagem_5 db "Aluno aprovado", 0ah, 0h
mensagem_6 db ", necessita tirar na final:",0h
mensagem_7 db " | Deseja adicionar outra nota?",0ah, 0h
mensagem_8 db "Digite (s) para sim ou (n) para nao", 0ah, 0h
mensagem_9 db "Media Final: ",0h
len1 equ $ - mensagem_8
;-------------------------Variaveis para o funcionamento do programa-------

var_qntNotas dd ?  ;quantidade de notas 
var_numNota dd ?  ;ordem das notas
stk real8 ? ;ponto flutuante de 8 bytes (double) SOMATORIO DAS NOTAS
var_respUsuario dd ?
len2 equ $ - var_respUsuario
var_valorSasc  dd 115

var_Notasfloat real8 ? ;variaveis para receber a entrada convertida

notaAprovado real8 7.0
notaReprovado real8 4.0

peso1 real8 5.0
peso2 real8 0.6
peso3 real8 0.4



;-------------------Variaveis para ler e Printar-----------------------
readCount dword ?
writeCount dword ?

consoleInHandle dword ?
consoleOutHandle dword ? 
;---------------------------------------------------------------------

;-----------------------variaveis para converter asc --------------------
stringEntrada db 5 dup(?),0ah,0h
num dword ? 
entradaConvertida db 5 dup(?)
;---------------------------------------------------------------------





.code
start:

;----------------- Funçoes para Ler e Printar ----------------

invoke GetStdHandle, STD_OUTPUT_HANDLE
mov consoleOutHandle, eax

invoke GetStdHandle, STD_INPUT_HANDLE
mov consoleInHandle, eax

;-------------------------Printf e Scanf (Para saber a quantidade de notas)-----------------------------------------------------


invoke WriteConsole, consoleOutHandle, addr mensagem1, sizeof mensagem1, addr writeCount, NULL

invoke ReadConsole, consoleInHandle, addr stringEntrada, sizeof stringEntrada, addr readCount, NULL

call convertAsc

invoke atodw, addr stringEntrada
mov var_qntNotas, eax

;printf("%i", var_Notas) ;printf para teste

;------------------------Print e Scanf (Para preencher as notas)------------------------------

xor ecx, ecx        ;zerando o registrador ecs para usar ele no laço
finit               ;incia um array float zerado
fld stk             ;empilhando a variavel stk (double) na pilha de execução da fpu   

laco:
 inc ecx
 mov var_numNota, ecx
 
 invoke dwtoa, var_numNota, addr entradaConvertida



    invoke WriteConsole, consoleOutHandle, addr mensagem2, sizeof mensagem2, addr writeCount, NULL
    invoke WriteConsole, consoleOutHandle, addr entradaConvertida, sizeof entradaConvertida, addr writeCount, NULL
    invoke WriteConsole, consoleOutHandle, addr mensagem3, sizeof mensagem3, addr writeCount, NULL
    invoke ReadConsole, consoleInHandle, addr stringEntrada, sizeof stringEntrada, addr readCount, NULL


invoke StrToFloat, addr stringEntrada, addr var_Notasfloat ;convertendo string para float

fld var_Notasfloat 
fadd st(0), st(1) 

mov ecx, var_numNota

cmp ecx, var_qntNotas
jl laco
fstp stk



;--------------------------------Calculando a media das notas---------------------------

invoke dwtoa, var_qntNotas, addr entradaConvertida  ;convertendo (double/float) para string
invoke StrToFloat, addr entradaConvertida, addr var_Notasfloat ;CONVERTENDO STRINGO PARA FLOAT

    
fld var_Notasfloat      ;empilha a quantidade das notas 
fld stk                 ;empilha a soma das notas


fdiv st(0), st(1)        ;divide a soma das notas pela quantidade de notas
    
fst stk                  ;pega o valor que ficou no topo da pilha que o resultado da divisao 

invoke WriteConsole, consoleOutHandle, addr mensagem_9, sizeof mensagem_9, addr writeCount, NULL 
invoke FloatToStr, stk, addr stringEntrada
invoke WriteConsole, consoleOutHandle, addr stringEntrada, sizeof stringEntrada, addr writeCount, NULL

;------------------Analisar se o aluno passou, foi pra final, ou reprovou direto ------------------------------
finit


fld notaAprovado                  ;equivale a 7
fld stk                           ;media final do somatorio das notas 
fcom

fstsw ax
sahf


jae aprovado
jb reprovado


            aprovado:
               invoke WriteConsole, consoleOutHandle, addr mensagem_5, sizeof mensagem_5, addr writeCount, NULL
               jmp cadastro
                
                

            reprovado:
                invoke WriteConsole, consoleOutHandle, addr mensagem_4, sizeof mensagem_4, addr writeCount, NULL

                finit
                fld notaReprovado
                fld stk
                fcom
                
                fstsw ax
                sahf
                
                jae final
                jmp cadastro

            final:
             ;calculo final = (5-0.6xMDF)/0,4

                finit
                 fld peso2 ;0.6 
                 fld stk   ;media final
                 fmul st(0), st(1)
                 fst stk
  

                finit
                fld stk
                fld peso1 ;5
                fsub st(0), st(1)
                fst stk
        

                finit
                fld peso3 ;0.4
                fld stk
                fdiv st(0), st(1)
                fst stk

                invoke WriteConsole, consoleOutHandle, addr mensagem_6, sizeof mensagem_6, addr writeCount, NULL 
                invoke FloatToStr, stk, addr stringEntrada
                invoke WriteConsole, consoleOutHandle, addr stringEntrada, sizeof stringEntrada, addr writeCount, NULL
               
    

;-------------------------------------ver se o professor deseja adicionar outra nota----------------------------------

cadastro:
invoke WriteConsole, consoleOutHandle, addr mensagem_7, sizeof mensagem_7, addr writeCount, NULL
invoke WriteConsole, consoleOutHandle, addr mensagem_8, sizeof mensagem_8, addr writeCount, NULL
invoke ReadConsole, consoleInHandle, addr stringEntrada, sizeof stringEntrada, addr readCount, NULL


mov al, [stringEntrada]
mov al, [stringEntrada+1]; 

cmp stringEntrada, "s"
je start
jmp fim

;----------------funcao para converter de asc para int----------------------------------------------------------------
convertAsc:
	mov esi, offset stringEntrada
prox2:
     mov al, [esi]
     inc esi
     cmp al, 48 ; Menor que ASCII 48
     jl  feito2
     cmp al, 58 ; Menor que ASCII 58 
     jl  prox2
feito2:
     dec esi
     xor al, al
     mov [esi], al
        ret
;--------------------------------termino do codigo--------------------------------------------------
fim:
invoke ExitProcess, 0
end start