org 100h

section .text
start:
    LAHF
    jmp start

    printRMdisp:
    push bx
    call readMOD_rm

    cmp byte [mod], 0
        jne .mod1
        cmp byte [rm], 110b
        jne .rmNot110
            printStr 1, "["
            mov bx, [opCode+2]
            call printWHex
            printStr 1, "]"
            jmp .next
                    
            .rmNot110
            call printRM
            printStr 1, "]"
            jmp .next

        .mod1
        cmp byte [mod], 1
        jne .mod2
            call printRM

            cmp byte [opCode+2], 0
            je .zero

            cmp byte [opCode+2], 128
            jb .notNegative
            printStr 1, "-"
            neg byte [opCode+2]
            jmp .printDISP

            .notNegative
            printStr 1, "+"

            .printDISP
            mov bl, [opCode+2]
            call printBHex
            .zero
            printStr 1, "]"
            jmp .next

        .mod2
        cmp byte [mod], 2
        jne .mod3
            call printRM
            printStr 1, "+"
            mov bx, [opCode+2]
            call printWHex
            printStr 1, "]"
            jmp .next

        .mod3
            call rmAsReg
            jmp .next

    .next
    pop bx
    ret