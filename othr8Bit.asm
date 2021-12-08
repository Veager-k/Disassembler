org 100h

section .text
start:
    call 6879h
    call bx
    call far [si+65]
    call 6AF8h:5487h

    XLATB
    LAHT
    SAHF
    PUSHF
    POPF
    AAA
    DAA
    AAS
    DAS
    CBW
    CWD
    AAM
    AAD

    lea di, [12]
    lds cx, [bp+si+54]
    les dx, [bp]

    mov DS, bx
    mov ss, [bx+si+2]
    mov ax, CS
    mov [di+6875h], es

    push word [bx+0f5eah]
    pop word [di+5]

