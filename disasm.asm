%macro printStr 2+
    push ax
    push bx
    push cx
    push dx 

    jmp %%skip
    %%string:        
        db %2, '$'
    
    %%skip:
    mov dx, %%string 
    mov ah, 09 
    int 21h 

    mov cx, %1
    mov bx, [outputFileHandle]
    mov ah, 40h
    mov dx, %%string
    int 21h

    pop dx
    pop cx
    pop bx  
    pop ax
%endmacro

%macro printCodeLine 0
;prints line of code(ip) and the op code of the command
;argument is op code length
    push bx

    mov bl, [codeLine+1]
    call printBHex
    mov bl, [codeLine]
    call printBHex

    printStr 1, " "
    ;mov bl, [opCode]
    ;call printBHex

    pop bx

%endmacro

%macro printOpCode 1
    push bx
    push cx
    push di

    mov di, 0
    mov cx, %1
    .%%printCode
        mov bl, [opCode+di]
        call printBHex
        inc di
    loop .%%printCode
    
    mov cx, 6
    sub cx, %1
    .%%printSpace
        printStr 2, "  "
    loop .%%printSpace

    pop di
    pop cx
    pop bx
%endmacro

%macro printCMDname 2+
    push bx
    push cx
    push di

    printStr 1, " "
    printStr %1, %2
    
    mov cx, 7
    sub cx, %1
    .%%printSpace
        printStr 1, " "
    loop .%%printSpace

    pop di
    pop cx
    pop bx
%endmacro

%macro printNL 0
    printStr 2, 0dh, 0ah
%endmacro

org 100h
section .text

pradzia:
    call readArgument
    call openFiles

    mov word [codeLine], 100h

    .disassemble:
        mov di, 0
        call readByte
        cmp ax, 0
        je .exitLoop

        .JMP_Dir_wSeg
        cmp byte [opCode], 0e9h
        jne .JMP_Dir_wSeg_Short

            printCodeLine
            add word [codeLine], 3

            call readByte
            call readByte
            printOpCode 3

            printCMDname 3, "JMP"
            mov bx, [opCode+1]
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble

        .JMP_Dir_wSeg_Short
        cmp byte [opCode], 0ebh
        jne .JMP_Dir_intSeg

            printCodeLine
            add word [codeLine], 2
            call readByte
            printOpCode 2

            printCMDname 3, "JMP"
            mov bh, 0
            mov bl, [opCode+1]
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble
            
        .JMP_Dir_intSeg
        cmp byte [opCode], 0eah
        jne .RET_wSeg

            printCodeLine
            add word [codeLine], 5
            call readByte
            call readByte
            call readByte
            call readByte
            printOpCode 5

            printCMDname 3, "JMP"
            mov bx, [opCode+3]
            call printWHex
            printStr 1, ":"
            mov bx, [opCode+1]
            call printWHex
            printNL
            jmp .disassemble
        
        .RET_wSeg
        cmp byte [opCode], 0c3h
        jne .RET_wSegSP
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "RET"
            printNL
            jmp .disassemble
        
        .RET_wSegSP
        cmp byte [opCode], 0c2h
        jne .RET_intSeg
            printCodeLine
            call readByte
            call readByte
            add word [codeLine], 3
            printOpCode 3
            printCMDname 3, "RET"
            mov bx, [opCode+1]
            call printWHex
            printNL
            jmp .disassemble

        .RET_intSeg
        cmp byte [opCode], 0cbh
        jne .RET_intSegSP
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 4, "RETF"
            printNL
            jmp .disassemble
        
        .RET_intSegSP
        cmp byte [opCode], 0cah
        jne .JE_
            printCodeLine
            call readByte
            call readByte
            add word [codeLine], 3
            printOpCode 3
            printCMDname 4, "RETF"
            mov bx, [opCode+1]
            call printWHex
            printNL
            jmp .disassemble
        
        .JE_
        cmp byte [opCode], 74h
        jne .JL_
            printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 2, "JE"

            mov bl, [opCode+1]
            mov bh, 0
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble
        
        .JL_
        cmp byte [opCode], 7ch
        jne .JLE_
            printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 2, "JL"

            mov bl, [opCode+1]
            mov bh, 0
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble
        
        .JLE_
        cmp byte [opCode], 7eh
        jne .JB_
            printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 3, "JLE"

            mov bl, [opCode+1]
            mov bh, 0
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble
        
        .JB_
        cmp byte [opCode], 72h
        jne .JBE_
            printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 2, "JB"

            mov bl, [opCode+1]
            mov bh, 0
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble
        
        .JBE_
        cmp byte [opCode], 76h
        jne .JP_
            printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 3, "JBE"

            mov bl, [opCode+1]
            mov bh, 0
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble

        .JP_
        cmp byte [opCode], 7ah
        jne .JO_
            printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 2, "JP"

            mov bl, [opCode+1]
            mov bh, 0
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble

        .JO_
        cmp byte [opCode], 70h
        jne .JS_
            printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 2, "JO"

            mov bl, [opCode+1]
            mov bh, 0
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble

        .JS_
        cmp byte [opCode], 78h
        jne .JNE_
            printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 2, "JS"

            mov bl, [opCode+1]
            mov bh, 0
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble
        
        .JNE_
        cmp byte [opCode], 75h
        jne .JNL_
            printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 3, "JNE"

            mov bl, [opCode+1]
            mov bh, 0
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble

        .JNL_
        cmp byte [opCode], 7Dh
        jne .JNLE_
            printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 3, "JNL"

            mov bl, [opCode+1]
            mov bh, 0
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble
        
        .JNLE_
        cmp byte [opCode], 7Fh
        jne .JNB_
            printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 4, "JNLE"

            mov bl, [opCode+1]
            mov bh, 0
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble

        .JNB_
        cmp byte [opCode], 73h
        jne .JA_
            printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 3, "JNB"

            mov bl, [opCode+1]
            mov bh, 0
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble
        
        .JA_
        cmp byte [opCode], 77h
        jne .JNP_
            printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 2, "JA"

            mov bl, [opCode+1]
            mov bh, 0
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble
        
        .JNP_
        cmp byte [opCode], 7Bh
        jne .JNO_
            printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 3, "JNP"

            mov bl, [opCode+1]
            mov bh, 0
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble
        
        .JNO_
        cmp byte [opCode], 71h
        jne .JNS_
            printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 3, "JNO"

            mov bl, [opCode+1]
            mov bh, 0
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble

        .JNS_
        cmp byte [opCode], 79h
        jne .LOOP_
            printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 3, "JNS"

            mov bl, [opCode+1]
            mov bh, 0
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble
        
        .LOOP_
        cmp byte [opCode], 0e2h
        jne .LOOPZ_
            printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 4, "LOOP"

            mov bl, [opCode+1]
            mov bh, 0
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble
        
        .LOOPZ_
        cmp byte [opCode], 0e1h
        jne .LOOPNZ_
            printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 5, "LOOPZ"

            mov bl, [opCode+1]
            mov bh, 0
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble
        
        .LOOPNZ_
        cmp byte [opCode], 0e0h
        jne .JCXZ_
            printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 6, "LOOPNZ"

            mov bl, [opCode+1]
            mov bh, 0
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble
        
        .JCXZ_
        cmp byte [opCode], 0e3h
        jne .INT_
            printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 4, "JCXZ"

            mov bl, [opCode+1]
            mov bh, 0
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble
        
        .INT_
        cmp byte [opCode], 0cdh
        jne .INT3_
            printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 3, "INT"

            mov bl, [opCode+1]
            call printBHex
            printNL
            jmp .disassemble
        
        .INT3_
        cmp byte [opCode], 0cch
        jne .INTO_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "INT"

            mov bl, 3
            call printBHex
            printNL
            jmp .disassemble
        
        .INTO_
        cmp byte [opCode], 0ceh
        jne .IRET_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 4, "INTO"
            printNL
            jmp .disassemble

        .IRET_
        cmp byte [opCode], 0cFh
        jne .CLC_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 4, "IRET"
            printNL
            jmp .disassemble

        .CLC_
        cmp byte [opCode], 0f8h
        jne .CMC_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "CLC"
            printNL
            jmp .disassemble

        .CMC_
        cmp byte [opCode], 0f5h
        jne .STC_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "CMC"
            printNL
            jmp .disassemble

        .STC_
        cmp byte [opCode], 0f9h
        jne .CLD_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "STC"
            printNL
            jmp .disassemble

        .CLD_
        cmp byte [opCode], 0fCh
        jne .STD_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "CLD"
            printNL
            jmp .disassemble
        
        .STD_
        cmp byte [opCode], 0fDh
        jne .CLI_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "STD"
            printNL
            jmp .disassemble
        
        .CLI_
        cmp byte [opCode], 0fah
        jne .STI_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "CLI"
            printNL
            jmp .disassemble
            
        .STI_
        cmp byte [opCode], 0fbh
        jne .HLT_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "STI"
            printNL
            jmp .disassemble
        
        .HLT_
        cmp byte [opCode], 0f4h
        jne .WAIT_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "HLT"
            printNL
            jmp .disassemble

        .WAIT_
        cmp byte [opCode], 09bh
        jne .LOCK_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 4, "WAIT"
            printNL
            jmp .disassemble
        
        .LOCK_
        cmp byte [opCode], 0f0h
        jne .CALL_dir_wSeg
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 4, "LOCK"
            printNL
            jmp .disassemble
        
        .CALL_dir_wSeg
        cmp byte [opCode], 0e8h
        jne .CALL_dir_intSeg
            printCodeLine
            call readByte
            call readByte
            add word [codeLine], 3
            printOpCode 3
            printCMDname 4, "CALL"

            mov bx, [opCode+1]
            add bx, word [codeLine]
            call printWHex
            printNL
            jmp .disassemble
        
        .CALL_dir_intSeg
        cmp byte [opCode], 09ah
        jne .CWD_
            printCodeLine
            add word [codeLine], 5
            call readByte
            call readByte
            call readByte
            call readByte
            printOpCode 5

            printCMDname 4, "CALL"
            mov bx, [opCode+3]
            call printWHex
            printStr 1, ":"
            mov bx, [opCode+1]
            call printWHex
            printNL
            jmp .disassemble
        
        .CWD_
        cmp byte [opCode], 099h
        jne .CBW_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "CWD"
            printNL
            jmp .disassemble
        
        .CBW_
        cmp byte [opCode], 098h
        jne .DAS_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "CBW"
            printNL
            jmp .disassemble
        
        .DAS_
        cmp byte [opCode], 02Fh
        jne .AAS_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "DAS"
            printNL
            jmp .disassemble
        
        .AAS_
        cmp byte [opCode], 03Fh
        jne .DAA_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "AAS"
            printNL
            jmp .disassemble
        
        .DAA_
        cmp byte [opCode], 027h
        jne .AAA_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "DAA"
            printNL
            jmp .disassemble
        
        .AAA_
        cmp byte [opCode], 037h
        jne .POPF_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "AAA"
            printNL
            jmp .disassemble
        
        .POPF_
        cmp byte [opCode], 09Dh
        jne .PUSHF_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 4, "POPF"
            printNL
            jmp .disassemble
        
        .PUSHF_
        cmp byte [opCode], 09Ch
        jne .SAHF_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 5, "PUSHF"
            printNL
            jmp .disassemble
        
        .SAHF_
        cmp byte [opCode], 09Eh
        jne .LAHF_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 4, "SAHF"
            printNL
            jmp .disassemble
        
        .LAHF_
        cmp byte [opCode], 09Fh
        jne .XLAT_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 4, "LAHF"
            printNL
            jmp .disassemble
        
        .XLAT_
        cmp byte [opCode], 0D7h
        jne .LEA_
            printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 4, "XLAT"
            printNL
            jmp .disassemble
        
        .LEA_
        cmp byte [opCode], 08Dh
        jne .LDS_
            printCodeLine
            call readByte
            call interpretMod
            mov bl, [opCode+1]
            shl bl, 2
            shr bl, 5
            mov [reg], bl 
            printCMDname 3, "LEA"
            call print16Reg
            printStr 2, ", "
            call printRMdisp
            printNL
            jmp .disassemble
        
        .LDS_
        cmp byte [opCode], 0c5h
        jne .LES_
            printCodeLine
            call readByte
            call interpretMod
            mov bl, [opCode+1]
            shl bl, 2
            shr bl, 5
            mov [reg], bl 
            printCMDname 3, "LDS"
            call print16Reg
            printStr 2, ", "
            call printRMdisp
            printNL
            jmp .disassemble
        
        .LES_
        cmp byte [opCode], 0c4h
        jne .MOV_rm_sr
            printCodeLine
            call readByte
            call interpretMod
            mov bl, [opCode+1]
            shl bl, 2
            shr bl, 5
            mov [reg], bl 
            printCMDname 3, "LES"
            call print16Reg
            printStr 2, ", "
            call printRMdisp
            printNL
            jmp .disassemble
        
        .MOV_rm_sr
        cmp byte [opCode], 08eh
        jne .MOV_sr_rm
            printCodeLine
            call readByte
            call interpretMod
            mov bl, [opCode+1]
            shl bl, 3
            shr bl, 6
            mov [reg], bl 
            printCMDname 3, "MOV"
            call printSegReg
            printStr 2, ", "
            call printRMdisp
            printNL
            jmp .disassemble
        
        .MOV_sr_rm
        cmp byte [opCode], 08ch
        jne .opcode_10001111
            printCodeLine
            call readByte
            call interpretMod
            mov bl, [opCode+1]
            shl bl, 3
            shr bl, 6
            mov [reg], bl 
            printCMDname 3, "MOV"
            call printRMdisp
            printStr 2, ", "
            call printSegReg
            printNL
            jmp .disassemble
        
        .opcode_10001111
        cmp byte [opCode], 08fh
        jne .opcode_11010101

            call readByte
            mov al, [opCode+1]
            and al, 00111000b
            shr al, 3
            cmp al, 000b
            jne .opcode_11010101

                printCodeLine
                call interpretMod
                printCMDname 3, "POP"
                call printRMdisp
                printNL
                jmp .disassemble
        
        .opcode_11010101
        cmp byte [opCode], 0d5h
        jne .opcode_11010100

            call readByte
            cmp byte [opCode+1], 0ah
            jne .opcode_11010100

                printCodeLine
                add word [codeLine], 2
                printOpCode 2
                printCMDname 3, "AAD"
                printNL
                jmp .disassemble
            
        .opcode_11010100
        cmp byte [opCode], 0d4h
        jne .opCode_1111_1111

            call readByte
            cmp byte [opCode+1], 0ah
            jne .opCode_1111_1111

                printCodeLine
                add word [codeLine], 2
                printOpCode 2
                printCMDname 3, "AAM"
                printNL
                jmp .disassemble


        .opCode_1111_1111
        cmp byte [opCode], 0ffh
        jne .disassemble

            call readByte
            mov al, [opCode+1]
            and al, 00111000b
            shr al, 3
            cmp al, 100b
            jne .JMP_Indir_intseg
                
                printCodeLine
                call interpretMod
                printCMDname 3, "JMP"
                call printRMdisp
                printNL
                jmp .disassemble

            .JMP_Indir_intseg
            cmp al, 101b
            jne .CALL_indir_wSeg

                printCodeLine
                call interpretMod
                printCMDname 3, "JMP"
                printStr 4, "far "
                call printRMdisp
                printNL
                jmp .disassemble
            
            .CALL_indir_wSeg
            cmp al, 010b
            jne .CALL_indir_intSeg
            
                printCodeLine
                call interpretMod
                printCMDname 4, "CALL"
                call printRMdisp
                printNL
                jmp .disassemble
            
            .CALL_indir_intSeg
            cmp al, 011b
            jne .PUSH_rm
            
                printCodeLine
                call interpretMod
                printCMDname 4, "CALL"
                printStr 4, "far "
                call printRMdisp
                printNL
                jmp .disassemble
            
            .PUSH_rm
            cmp al, 110b
            jne .disassemble
            
                printCodeLine
                call interpretMod
                printCMDname 4, "PUSH"
                call printRMdisp
                printNL
                jmp .disassemble
            
        
        jmp .disassemble
    .exitLoop:

    call closeFile
    jmp pabaiga

readArgument:
;reads commandline argument, prepares it for file opening and prints it
    push si
    push di
    push dx
    push ax

    mov dx, 0
    mov ax, 0

    mov si, 80h
    mov dl, [es:si]
    cmp dl, 0
    je noArg
    mov [cmdArgSize], dl
    mov di, cmdArg

    .aloop
        inc si
        mov al, [es:si]
        cmp al, ' '
        je .check
        cmp al, 0Dh
        je .check
        cmp al, 0Ah
        je .check

        mov ah, 1
        mov [di], al
        inc di
        jmp .aloop

        .check
        cmp ah, 1
        jne .aloop

    .addCOM
    mov [di], byte "."
    mov [di+1], byte "C"
    mov [di+2], byte "O"
    mov [di+3], byte "M"

    pop ax
    pop dx
    pop di
    pop si
    ret

openFiles:
    push ax
    push bx
    push cx
    push dx

    clc
    mov ah, 3Dh
    mov al, 00h
    mov dx, cmdArg
    int 21h

    jc failedToOpenInputFile
    mov [inputFileHandle], ax

    clc
    mov ah, 3Ch
    mov cx, 0
    mov dx, outputFileName
    int 21h

    jc failedToOpenOutputFile
    mov [outputFileHandle], ax

    pop dx
    pop cx
    pop bx
    pop ax
    ret

readByte:
;reads byte from input file and saves it in currByte
    push bx
    push cx
    push dx

    mov bx, [inputFileHandle]
    mov cx, 1
    mov dx, opCode
    add dx, di
    mov ah, 3Fh
    mov al, 0
    int 21h

    inc di

    pop dx
    pop cx
    pop bx


    ret

closeFile:
    push ax
    push bx

    mov ah, 3Eh
    mov al, 0
    mov bx, [inputFileHandle]
    int 21h

    jc failedToCloseFile

    pop bx
    pop ax
    ret

printBHex:
;prints bl in Hex format
    push ax
    push bx
    push cx
    push dx

    mov dl, bl
    mov dh, 0
    shr dl, 4
    cmp dl, 10
    jae .letter

    .arabNum
    add dl, 48
    jmp .printHexNum

    .letter
    add dl, 55

    .printHexNum
    mov ah, 02h
    int 21h
    mov [hexNum], dl

    mov dl, bl
    mov dh, 0
    rol dl, 4
    shr dl, 4
    cmp dl, 10
    jae .letter2

    .arabNum2
    add dl, 30h
    jmp .printHexNum2

    .letter2
    add dl, 55

    .printHexNum2
    mov ah, 02h
    int 21h
    mov [hexNum+1], dl

    mov bx, [outputFileHandle]
    mov ah, 40h
    mov cx, 2
    mov dx, hexNum
    int 21h

    pop dx
    pop cx
    pop bx
    pop ax

    ret

printWHex:
;prints bx in Hex format
    xchg bl, bh
    call printBHex
    xchg bl, bh
    call printBHex

    ret

readMOD_rm:
    push ax

    mov al, [opCode+1]
    shr al, 6
    mov [mod], al

    mov al, [opCode+1]
    and al, 00000111b
    mov [rm], al

    pop ax
    ret

printRM:
    cmp byte [rm], 0
    jne .rm1
        printStr 6, "[BX+SI"
        jmp .donePrintingRM

    .rm1
    cmp byte [rm], 1
    jne .rm2
        printStr 6, "[BX+DI"
        jmp .donePrintingRM

    .rm2
    cmp byte [rm], 2
    jne .rm3
        printStr 6, "[BP+SI"
        jmp .donePrintingRM

    .rm3
    cmp byte [rm], 3
    jne .rm4
        printStr 6, "[BP+DI"
        jmp .donePrintingRM

    .rm4
    cmp byte [rm], 4
    jne .rm5
        printStr 3, "[SI"
        jmp .donePrintingRM

    .rm5
    cmp byte [rm], 5
    jne .rm6
        printStr 3, "[DI"
        jmp .donePrintingRM

    .rm6
    cmp byte [rm], 6
    jne .rm7
        printStr 3, "[BP"
        jmp .donePrintingRM

    .rm7
        printStr 3, "[BX"
    
    .donePrintingRM
    ret

rmAsReg:
    cmp byte [rm], 0
    jne .rm1
        printStr 2, "AX"
        jmp .donePrintingRM

    .rm1
    cmp byte [rm], 1
    jne .rm2
        printStr 2, "CX"
        jmp .donePrintingRM

    .rm2
    cmp byte [rm], 2
    jne .rm3
        printStr 2, "DX"
        jmp .donePrintingRM

    .rm3
    cmp byte [rm], 3
    jne .rm4
        printStr 2, "BX"
        jmp .donePrintingRM

    .rm4
    cmp byte [rm], 4
    jne .rm5
        printStr 2, "SP"
        jmp .donePrintingRM

    .rm5
    cmp byte [rm], 5
    jne .rm6
        printStr 2, "BP"
        jmp .donePrintingRM

    .rm6
    cmp byte [rm], 6
    jne .rm7
        printStr 2, "SI"
        jmp .donePrintingRM

    .rm7
        printStr 2, "DI"
    
    .donePrintingRM

    ret

interpretMod:
    push bx
    call readMOD_rm

            cmp byte [mod], 0
            jne .mod1
                cmp byte [rm], 110b
                jne .rmNot110
                    call readByte
                    call readByte
                    printOpCode 4
                    add word [codeLine], 4
                    jmp .next
                    
                .rmNot110
                printOpCode 2
                add word [codeLine], 2
                jmp .next

            .mod1
            cmp byte [mod], 1
            jne .mod2
                call readByte
                printOpCode 3
                add word [codeLine], 3
                jmp .next

            .mod2
            cmp byte [mod], 2
            jne .mod3
                call readByte
                call readByte
                printOpCode 4
                add word [codeLine], 4
                jmp .next

            .mod3
                cmp byte [mod], 3
                printOpCode 2
                add word [codeLine], 2
            jmp .next

    .next
    pop bx
    ret

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

print16Reg:
    cmp byte [reg], 0
    jne .reg1
        printStr 2, "AX"
        jmp .donePrintingREG

    .reg1
    cmp byte [reg], 1
    jne .reg2
        printStr 2, "CX"
        jmp .donePrintingREG

    .reg2
    cmp byte [reg], 2
    jne .reg3
        printStr 2, "DX"
        jmp .donePrintingREG

    .reg3
    cmp byte [reg], 3
    jne .reg4
        printStr 2, "BX"
        jmp .donePrintingREG

    .reg4
    cmp byte [reg], 4
    jne .reg5
        printStr 2, "SP"
        jmp .donePrintingREG

    .reg5
    cmp byte [reg], 5
    jne .reg6
        printStr 2, "BP"
        jmp .donePrintingREG

    .reg6
    cmp byte [reg], 6
    jne .reg7
        printStr 2, "SI"
        jmp .donePrintingREG

    .reg7
        printStr 2, "DI"
    
    .donePrintingREG
    ret


printSegReg:
    cmp byte [reg], 0
    jne .reg1
        printStr 2, "ES"
        jmp .donePrintingREG

    .reg1
    cmp byte [reg], 1
    jne .reg2
        printStr 2, "CS"
        jmp .donePrintingREG

    .reg2
    cmp byte [reg], 2
    jne .reg3
        printStr 2, "SS"
        jmp .donePrintingREG

    .reg3
        printStr 2, "DS"
    
    .donePrintingREG
    ret


pabaiga:
    mov ah, 4Ch
    mov al, 0
    int 21h 


failedToOpenInputFile:
    mov dx, openInputFileErrorMessage
    mov ah, 09h
    mov al, 0
    int 21h
    jmp pabaiga

failedToOpenOutputFile:
    mov bx, ax
    call printWHex
    mov dx, openOutputFileErrorMessage
    mov ah, 09h
    mov al, 0
    int 21h
    jmp pabaiga

failedToCloseFile:
    mov dx, closeFileErrorMessage
    mov ah, 09h
    mov al, 0
    int 21h
    jmp pabaiga

noArg:
    mov dx, noArgumentMessage
    mov ah, 09h
    mov al, 0
    int 21h
    jmp pabaiga



section .data

    cmdArgSize: db 0
    cmdArg: times 128 db 0
    outputFileName: db "disRez.txt", 0
    inputFileHandle: db 0, 0
    outputFileHandle: db 0, 0
    openInputFileErrorMessage: db "Failed to open Input file", 0ah, 0dh, '$'
    openOutputFileErrorMessage: db "Failed to open Output file", 0ah, 0dh, '$'
    closeFileErrorMessage: db "Failed to close file", 0ah, 0dh, '$'
    noArgumentMessage: db "No argument provided", 0ah, 0dh, '$'
    codeLine: db 0, 0
    Csegment: db 0, 0
    opCode: times 6 db 0
    mod: db 0
    rm: db 0
    reg: db 0
    space: db ' ', '$'
    currByte: db 0
    hexNum: db 0, 0