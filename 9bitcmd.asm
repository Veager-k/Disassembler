org 100h

section .text
start:
    mov word [bx], 1548h
    mov word [si+4], 0FAB3h
    mov byte [di+3456], dl
    mov ds, word [bx]