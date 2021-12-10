%macro printStr 2+
    push ax
    push bx
    push cx
    push dx 

    jmp %%skip
    %%string:        
        db %2, '$'
    
    %%skip:

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

%macro printOpCode 1
    push ax
    push bx
    push cx
    push di

    mov di, 0
    mov cl, %1
    mov ch, 0
    .%%printCode
        mov bl, [opCode+di]
        call printBHex
        inc di
    loop .%%printCode
    
    printStr 1, " "
    mov cx, 8
    mov al, %1
    mov ah, 0
    sub cx, ax
    .%%printSpace
        printStr 2, "  "
    loop .%%printSpace

    pop di
    pop cx
    pop bx
    pop ax
%endmacro

%macro printCMDname 2+
    push bx
    push cx
    push di

    printStr 1, " "
    printStr %1, %2
    
    mov cx, 8
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

%macro interpretMod 1
    push bx
    push dx

    mov dx, 0
    call readMOD_rm
    mov bx, %1
    cmp bx, 1
    jne .%%no_data
        cmp byte [lastBit], 1
        jne .%%w_0
            add dl, 2
            call readData
            jmp .%%no_data
        .%%w_0
            add dl, 1
            call readData
    .%%no_data

            cmp byte [mod], 0
            jne .%%mod1
                cmp byte [rm], 110b
                jne .%%rmNot110
                    call readByte
                    call readByte
                    add dl, 4
                    printOpCode dl
                    add word [codeLine], dx
                    jmp .%%next
                    
                .%%rmNot110
                add dl, 2
                printOpCode dl
                add word [codeLine], dx
                jmp .%%next

            .%%mod1
            cmp byte [mod], 1
            jne .%%mod2
                call readByte
                add dl, 3
                printOpCode dl
                add word [codeLine], dx
                jmp .%%next

            .%%mod2
            cmp byte [mod], 2
            jne .%%mod3
                call readByte
                call readByte
                add dl, 4
                printOpCode dl
                add word [codeLine], dx
                jmp .%%next

            .%%mod3
                cmp byte [mod], 3
                add dl, 2
                printOpCode dl
                add word [codeLine], dx
            jmp .%%next

    .%%next

    pop dx
    pop bx
%endmacro

org 100h
section .text

pradzia:
    call readArgument
    call openFiles

    mov word [codeLine], 100h

    .disassemble:
        mov di, 0
        mov byte [lastBit], 1
        call readByte
        cmp ax, 0
        je .exitLoop

        .JMP_Dir_wSeg
        cmp byte [opCode], 0e9h
        jne .JMP_Dir_wSeg_Short

            call printCodeLine
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

            call printCodeLine
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

            call printCodeLine
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
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "RET"
            printNL
            jmp .disassemble
        
        .RET_wSegSP
        cmp byte [opCode], 0c2h
        jne .RET_intSeg
            call printCodeLine
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
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 4, "RETF"
            printNL
            jmp .disassemble
        
        .RET_intSegSP
        cmp byte [opCode], 0cah
        jne .JZ_
            call printCodeLine
            call readByte
            call readByte
            add word [codeLine], 3
            printOpCode 3
            printCMDname 4, "RETF"
            mov bx, [opCode+1]
            call printWHex
            printNL
            jmp .disassemble
        
        .JZ_
        cmp byte [opCode], 74h
        jne .JL_
            call printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 2, "JZ"

            call negJumpByte
            printNL
            jmp .disassemble
        
        .JL_
        cmp byte [opCode], 7ch
        jne .JLE_
            call printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 2, "JL"

            call negJumpByte
            printNL
            jmp .disassemble
        
        .JLE_
        cmp byte [opCode], 7eh
        jne .JB_
            call printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 3, "JLE"

            call negJumpByte
            printNL
            jmp .disassemble
        
        .JB_
        cmp byte [opCode], 72h
        jne .JBE_
            call printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 2, "JB"

            call negJumpByte
            printNL
            jmp .disassemble
        
        .JBE_
        cmp byte [opCode], 76h
        jne .JPE_
            call printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 3, "JBE"

            call negJumpByte
            printNL
            jmp .disassemble

        .JPE_
        cmp byte [opCode], 7ah
        jne .JO_
            call printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 3, "JPE"

            call negJumpByte
            printNL
            jmp .disassemble

        .JO_
        cmp byte [opCode], 70h
        jne .JS_
            call printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 2, "JO"

            call negJumpByte
            printNL
            jmp .disassemble

        .JS_
        cmp byte [opCode], 78h
        jne .JNZ_
            call printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 2, "JS"

            call negJumpByte
            printNL
            jmp .disassemble
        
        .JNZ_
        cmp byte [opCode], 75h
        jne .JGE_
            call printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 3, "JNZ"

            call negJumpByte
            printNL
            jmp .disassemble

        .JGE_
        cmp byte [opCode], 7Dh
        jne .JG_
            call printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 3, "JGE"

            call negJumpByte
            printNL
            jmp .disassemble
        
        .JG_
        cmp byte [opCode], 7Fh
        jne .JAE_
            call printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 2, "JG"

            call negJumpByte
            printNL
            jmp .disassemble

        .JAE_
        cmp byte [opCode], 73h
        jne .JA_
            call printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 3, "JAE"

            call negJumpByte
            printNL
            jmp .disassemble
        
        .JA_
        cmp byte [opCode], 77h
        jne .JPO_
            call printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 2, "JA"

            call negJumpByte
            printNL
            jmp .disassemble
        
        .JPO_
        cmp byte [opCode], 7Bh
        jne .JNO_
            call printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 3, "JPO"

            call negJumpByte
            printNL
            jmp .disassemble
        
        .JNO_
        cmp byte [opCode], 71h
        jne .JNS_
            call printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 3, "JNO"

            call negJumpByte
            printNL
            jmp .disassemble

        .JNS_
        cmp byte [opCode], 79h
        jne .LOOPW_
            call printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 3, "JNS"

            call negJumpByte
            printNL
            jmp .disassemble
        
        .LOOPW_
        cmp byte [opCode], 0e2h
        jne .LOOPZW_
            call printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 5, "LOOPW"

            call negJumpByte
            printNL
            jmp .disassemble
        
        .LOOPZW_
        cmp byte [opCode], 0e1h
        jne .LOOPNZW_
            call printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 6, "LOOPZW"

            call negJumpByte
            printNL
            jmp .disassemble
        
        .LOOPNZW_
        cmp byte [opCode], 0e0h
        jne .JCXZ_
            call printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 7, "LOOPNZW"

            call negJumpByte
            printNL
            jmp .disassemble
        
        .JCXZ_
        cmp byte [opCode], 0e3h
        jne .INT_
            call printCodeLine
            call readByte
            add word [codeLine], 2
            printOpCode 2
            printCMDname 4, "JCXZ"

            call negJumpByte
            printNL
            jmp .disassemble
        
        .INT_
        cmp byte [opCode], 0cdh
        jne .INT3_
            call printCodeLine
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
            call printCodeLine
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
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 4, "INTO"
            printNL
            jmp .disassemble

        .IRET_
        cmp byte [opCode], 0cFh
        jne .CLC_
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 4, "IRET"
            printNL
            jmp .disassemble

        .CLC_
        cmp byte [opCode], 0f8h
        jne .CMC_
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "CLC"
            printNL
            jmp .disassemble

        .CMC_
        cmp byte [opCode], 0f5h
        jne .STC_
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "CMC"
            printNL
            jmp .disassemble

        .STC_
        cmp byte [opCode], 0f9h
        jne .CLD_
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "STC"
            printNL
            jmp .disassemble

        .CLD_
        cmp byte [opCode], 0fCh
        jne .STD_
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "CLD"
            printNL
            jmp .disassemble
        
        .STD_
        cmp byte [opCode], 0fDh
        jne .CLI_
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "STD"
            printNL
            jmp .disassemble
        
        .CLI_
        cmp byte [opCode], 0fah
        jne .STI_
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "CLI"
            printNL
            jmp .disassemble
            
        .STI_
        cmp byte [opCode], 0fbh
        jne .HLT_
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "STI"
            printNL
            jmp .disassemble
        
        .HLT_
        cmp byte [opCode], 0f4h
        jne .WAIT_
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "HLT"
            printNL
            jmp .disassemble

        .WAIT_
        cmp byte [opCode], 09bh
        jne .LOCK_
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 4, "WAIT"
            printNL
            jmp .disassemble
        
        .LOCK_
        cmp byte [opCode], 0f0h
        jne .CALL_dir_wSeg
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 4, "LOCK"
            printNL
            jmp .disassemble
        
        .CALL_dir_wSeg
        cmp byte [opCode], 0e8h
        jne .CALL_dir_intSeg
            call printCodeLine
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
            call printCodeLine
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
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "CWD"
            printNL
            jmp .disassemble
        
        .CBW_
        cmp byte [opCode], 098h
        jne .DAS_
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "CBW"
            printNL
            jmp .disassemble
        
        .DAS_
        cmp byte [opCode], 02Fh
        jne .AAS_
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "DAS"
            printNL
            jmp .disassemble
        
        .AAS_
        cmp byte [opCode], 03Fh
        jne .DAA_
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "AAS"
            printNL
            jmp .disassemble
        
        .DAA_
        cmp byte [opCode], 027h
        jne .AAA_
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "DAA"
            printNL
            jmp .disassemble
        
        .AAA_
        cmp byte [opCode], 037h
        jne .POPF_
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 3, "AAA"
            printNL
            jmp .disassemble
        
        .POPF_
        cmp byte [opCode], 09Dh
        jne .PUSHF_
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 4, "POPF"
            printNL
            jmp .disassemble
        
        .PUSHF_
        cmp byte [opCode], 09Ch
        jne .SAHF_
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 5, "PUSHF"
            printNL
            jmp .disassemble
        
        .SAHF_
        cmp byte [opCode], 09Eh
        jne .LAHF_
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 4, "SAHF"
            printNL
            jmp .disassemble
        
        .LAHF_
        cmp byte [opCode], 09Fh
        jne .XLAT_
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 4, "LAHF"
            printNL
            jmp .disassemble
        
        .XLAT_
        cmp byte [opCode], 0D7h
        jne .LEA_
            call printCodeLine
            add word [codeLine], 1
            printOpCode 1
            printCMDname 4, "XLAT"
            printNL
            jmp .disassemble
        
        .LEA_
        cmp byte [opCode], 08Dh
        jne .LDS_
            call printCodeLine
            call readByte
            interpretMod 0
            mov bl, [opCode+1]
            shl bl, 2
            shr bl, 5
            mov [reg], bl 
            printCMDname 3, "LEA"
            call print16Reg
            printStr 1, ","
            call printRMdisp
            printNL
            jmp .disassemble
        
        .LDS_
        cmp byte [opCode], 0c5h
        jne .LES_
            call printCodeLine
            call readByte
            interpretMod 0
            mov bl, [opCode+1]
            shl bl, 2
            shr bl, 5
            mov [reg], bl 
            printCMDname 3, "LDS"
            call print16Reg
            printStr 1, ","
            call printRMdisp
            printNL
            jmp .disassemble
        
        .LES_
        cmp byte [opCode], 0c4h
        jne .MOV_rm_sr
            call printCodeLine
            call readByte
            interpretMod 0
            mov bl, [opCode+1]
            shl bl, 2
            shr bl, 5
            mov [reg], bl 
            printCMDname 3, "LES"
            call print16Reg
            printStr 1, ","
            call printRMdisp
            printNL
            jmp .disassemble
        
        .MOV_rm_sr
        cmp byte [opCode], 08eh
        jne .MOV_sr_rm
            call printCodeLine
            call readByte
            interpretMod 0
            mov bl, [opCode+1]
            shl bl, 3
            shr bl, 6
            mov [reg], bl 
            printCMDname 3, "MOV"
            call printSegReg
            printStr 10, ",WORD PTR "
            call printRMdisp
            printNL
            jmp .disassemble
        
        .MOV_sr_rm
        cmp byte [opCode], 08ch
        jne .opcode_10001111
            call printCodeLine
            call readByte
            interpretMod 0
            mov bl, [opCode+1]
            shl bl, 3
            shr bl, 6
            mov [reg], bl 
            printCMDname 3, "MOV"
            printStr 9, "WORD PTR "
            call printRMdisp
            printStr 1, ","
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

                call printCodeLine
                interpretMod 0
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

                call printCodeLine
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

                call printCodeLine
                add word [codeLine], 2
                printOpCode 2
                printCMDname 3, "AAM"
                printNL
                jmp .disassemble


        .opCode_1111_1111
        cmp byte [opCode], 0ffh
        jne .7bitcmd

            call readByte
            mov al, [opCode+1]
            and al, 00111000b
            shr al, 3
            cmp al, 100b
            jne .JMP_Indir_intseg
                
                call printCodeLine
                interpretMod 0
                printCMDname 3, "JMP"

                cmp byte [mod], 3
                je .JMP_indir_wSeg_reg
                    printStr 9, "WORD PTR "
                .JMP_indir_wSeg_reg

                call printRMdisp
                printNL
                jmp .disassemble

            .JMP_Indir_intseg
            cmp al, 101b
            jne .CALL_indir_wSeg

                call printCodeLine
                interpretMod 0
                printCMDname 3, "JMP"
                printStr 4, "FAR "
                call printRMdisp
                printNL
                jmp .disassemble
            
            .CALL_indir_wSeg
            cmp al, 010b
            jne .CALL_indir_intSeg
            
                call printCodeLine
                interpretMod 0
                printCMDname 4, "CALL"
                cmp byte [mod], 3
                je .CALL_indir_wSeg_reg
                    printStr 9, "WORD PTR "
                .CALL_indir_wSeg_reg

                call printRMdisp
                printNL
                jmp .disassemble
            
            .CALL_indir_intSeg
            cmp al, 011b
            jne .PUSH_rm
            
                call printCodeLine
                interpretMod 0
                printCMDname 4, "CALL"
                printStr 4, "FAR "
                call printRMdisp
                printNL
                jmp .disassemble
            
            .PUSH_rm
            cmp al, 110b
            jne .disassemble
            
                call printCodeLine
                interpretMod 0
                printCMDname 4, "PUSH"
                call printRMdisp
                printNL
                jmp .disassemble
        
        ;partial jump?
        ;.done_with_6_bit_jmp
        ;jmp .disassemble
        ; 7 bit op code commands
        .7bitcmd
        mov al, [opCode]
        and al, 00000001b
        mov [lastBit], al
        mov al, [opCode]
        shr al, 1
        
        .MOV_Im_to_RegMem
        cmp byte al, 063h       ;should check 2bit
        jne .MOV_mem_to_ax
            call printCodeLine
            call readByte
            interpretMod 1

            printCMDname 3, "MOV"

            call printWordOrByte
            call printRMdisp
            printStr 1, ","
            call printDataWhenMod
            

            printNL
            jmp .disassemble
        
        .MOV_mem_to_ax
        cmp byte al, 050h
        jne .MOV_ax_to_mem
            call printCodeLine
            call readByte
            call readByte
            printOpCode 3
            add byte [codeLine], 3

            printCMDname 3, "MOV"

            call printAcc
            call printAdress
            
            printNL
            jmp .disassemble

        .MOV_ax_to_mem
        cmp byte al, 051h
        jne .NOT_
            call printCodeLine
            call readByte
            call readByte
            printOpCode 3
            add byte [codeLine], 3

            printCMDname 3, "MOV"

            call printAdress
            cmp byte [lastBit], 1
            jne .MOV_ax_to_mem_w_0
                printStr 3, ",AX"
                jmp .MOV_ax_to_mem_done
            .MOV_ax_to_mem_w_0
                printStr 3, ",AL"
            .MOV_ax_to_mem_done

            printNL
            jmp .disassemble
        
        .NOT_
        cmp byte al, 07Bh
        jne .6bitcmd
            call printCodeLine
            call readByte
            interpretMod 0

            printCMDname 3, "NOT"
            call printWordOrByteMod
            call printRMdisp

            printNL
            jmp .disassemble

        ;6 bit op code
        .6bitcmd
        mov al, [opCode]
        and al, 00000010b
        shr al, 1
        mov [secondToLastBit], al
        mov al, [opCode]
        shr al, 2

        .Mov_RegMem_TF_Reg
        cmp byte al, 22h
        jne .opCode_110100
            call printCodeLine
            call readByte
            interpretMod 0
            mov bl, [opCode+1]
            and bl, 00111000b
            shr bl, 3
            mov [reg], bl 

            printCMDname 3, "MOV"

            cmp byte [secondToLastBit], 1
            jne .MOV_d_0
                call printReg
                printStr 1, ","
                call printRMdisp
                jmp .MOV_d_done
            .MOV_d_0
                call printRMdisp
                printStr 1, ","
                call printReg
            
            .MOV_d_done
            printNL
            jmp .disassemble
        
        .opCode_110100
        cmp byte al, 34h
        jne .mov_imd_to_reg
            call readByte
            mov ah, [opCode+1]
            and ah, 00111000b
            shr ah, 3

            cmp ah, 0
            jne .ROR_
                call printCodeLine
                interpretMod 0
                printCMDname 3, "ROL"

                call printWordOrByteMod
                call printRMdisp
                printStr 1, ","
                call printV
                printNL
                jmp .disassemble
            
            .ROR_
            cmp ah, 1
            jne .RCL_
                call printCodeLine
                interpretMod 0
                printCMDname 3, "ROR"

                call printWordOrByteMod
                call printRMdisp
                printStr 1, ","
                call printV
                printNL
                jmp .disassemble
            
            .RCL_
            cmp ah, 2
            jne .RCR_
                call printCodeLine
                interpretMod 0
                printCMDname 3, "RCL"

                call printWordOrByteMod
                call printRMdisp
                printStr 1, ","
                call printV
                printNL
                jmp .disassemble
            
            .RCR_
            cmp ah, 3
            jne .shl_
                call printCodeLine
                interpretMod 0
                printCMDname 3, "RCR"

                call printWordOrByteMod
                call printRMdisp
                printStr 1, ","
                call printV
                printNL
                jmp .disassemble
            

            .shl_
            cmp ah, 4
            jne .shr_
                call printCodeLine
                interpretMod 0
                printCMDname 3, "SHL"

                call printWordOrByteMod
                call printRMdisp
                printStr 1, ","
                call printV
                printNL
                jmp .disassemble

            .shr_
            cmp ah, 5
            jne .SAR_
                call printCodeLine
                interpretMod 0
                printCMDname 3, "SHR"

                call printWordOrByteMod
                call printRMdisp
                printStr 1, ","
                call printV
                printNL
                jmp .disassemble
            
            .SAR_
            cmp ah, 7
            jne .disassemble
                call printCodeLine
                interpretMod 0
                printCMDname 3, "SAR"

                call printWordOrByteMod
                call printRMdisp
                printStr 1, ","
                call printV
                printNL
                jmp .disassemble



        ;edge cases
        .mov_imd_to_reg
        mov al, [opCode]
        shr al, 4
        cmp al, 0bh
        jne .disassemble
            mov al, [opCode]
            and al, 00001000b
            shr al, 3
            mov [lastBit], al

            mov al, [opCode]
            shl al, 5
            shr al, 5
            mov [reg], al

            call printCodeLine
            call readData
            cmp byte [lastBit], 1
            jne .mov_imd_to_reg_w_0
                printOpCode 3
                add word [codeLine], 3
                jmp .mov_imd_to_reg_w_done
            .mov_imd_to_reg_w_0
                printOpCode 2
                add word [codeLine], 2
            .mov_imd_to_reg_w_done

            printCMDname 3, "MOV"
            call printReg
            printStr 1, ","
            call printData
            printNL
            jmp .disassemble

        jmp .disassemble
    .exitLoop

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

            ;cmp byte [opCode+2], 0
            ;je .zero

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
            ;.zero
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
            call rmAsRegW
            jmp .next

    .next
    pop bx
    ret


rmAsRegW:
    cmp byte [lastBit], 1
    jne .w_0
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
            jmp .donePrintingRM

    .w_0
        cmp byte [rm], 0
        jne .0rm1
            printStr 2, "AL"
            jmp .donePrintingRM

        .0rm1
        cmp byte [rm], 1
        jne .0rm2
            printStr 2, "CL"
            jmp .donePrintingRM

        .0rm2
        cmp byte [rm], 2
        jne .0rm3
            printStr 2, "DL"
            jmp .donePrintingRM

        .0rm3
        cmp byte [rm], 3
        jne .0rm4
            printStr 2, "BL"
            jmp .donePrintingRM

        .0rm4
        cmp byte [rm], 4
        jne .0rm5
            printStr 2, "AH"
            jmp .donePrintingRM

        .0rm5
        cmp byte [rm], 5
        jne .0rm6
            printStr 2, "CH"
            jmp .donePrintingRM

        .0rm6
        cmp byte [rm], 6
        jne .0rm7
            printStr 2, "DH"
            jmp .donePrintingRM

        .0rm7
            printStr 2, "BH"

    .donePrintingRM

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

print8Reg:
    cmp byte [reg], 0
    jne .reg1
        printStr 2, "AL"
        jmp .donePrintingREG

    .reg1
    cmp byte [reg], 1
    jne .reg2
        printStr 2, "CL"
        jmp .donePrintingREG

    .reg2
    cmp byte [reg], 2
    jne .reg3
        printStr 2, "DL"
        jmp .donePrintingREG

    .reg3
    cmp byte [reg], 3
    jne .reg4
        printStr 2, "BL"
        jmp .donePrintingREG

    .reg4
    cmp byte [reg], 4
    jne .reg5
        printStr 2, "AH"
        jmp .donePrintingREG

    .reg5
    cmp byte [reg], 5
    jne .reg6
        printStr 2, "CH"
        jmp .donePrintingREG

    .reg6
    cmp byte [reg], 6
    jne .reg7
        printStr 2, "DH"
        jmp .donePrintingREG

    .reg7
        printStr 2, "BH"
    
    .donePrintingREG


    ret

printReg:
    cmp byte [lastBit], 1
        jne .lastBit0
            call print16Reg
            jmp .done
        .lastBit0
        call print8Reg

        .done
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

negJumpByte:
    push ax
    push bx

    mov bl, [opCode+1]
    mov bh, 0
    cmp bl, 128
    jb .notNegative
        neg bl
        mov ax, word [codeLine]
        sub ax, bx
        mov bx, ax
        jmp .print
    .notNegative
        add bx, word [codeLine]

    .print
    call printWHex

    pop ax
    pop bx
    ret

printDataWhenMod:
    push di
    cmp byte [mod], 0
    jne .mod1
        mov di, 0
    .mod1
    cmp byte [mod], 1
    jne .mod2
        mov di, 1
    .mod2
    cmp byte [mod], 2
    jne .mod3
        mov di, 2
    .mod3
    cmp byte [mod], 3
    jne .done
        mov di, 0
    .done

    cmp byte [lastBit], 1
    jne .w0
        mov bx, [opCode+2+di]
        call printWHex
        jmp .done_w_0
    .w0
        mov bl, [opCode+2+di]
        call printBHex
    .done_w_0

    pop di
    ret

printData:
    push bx
    cmp byte [lastBit], 1
        jne .w_0
            mov bx, [opCode+1]
            call printWHex
            jmp .w_done
        .w_0
            mov bl, [opCode+1]
            call printBHex
        .w_done
    pop bx
    ret
printAdress:
    push bx
    printStr 1, "["

    mov bx, [opCode+1]
    call printWHex

    pop bx
    printStr 1, "]"
    ret
readData:
    call readByte
    cmp byte [lastBit], 1
    jne .w_0
        call readByte
    .w_0

    ret

printWordOrByte:

    cmp byte [lastBit], 1
    jne .not_1
        printStr 4, "WORD"
        jmp .done
    .not_1
        printStr 4, "BYTE"
    .done
    printStr 5, " PTR "
    ret

printCodeLine:
    push bx

    mov bx, [Csegment]
    call printWHex
    printStr 1, ":"
    mov bx, [codeLine]
    call printWHex
    printStr 1, " "
    pop bx

    ret

printAcc:
    cmp byte [lastBit], 1
    jne .w_0
        printStr 3, "AX,"
        jmp .done
    .w_0
        printStr 3, "AL,"
    .done
    ret

printV:
    cmp byte [secondToLastBit], 1
    jne .w_0
        printStr 2, "CL"
        jmp .done
    .w_0
        printStr 1, "1"
    .done
    ret
printWordOrByteMod:
    cmp byte [mod], 11b
    jne .next
        ret
    .next
    call printWordOrByte
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
    Csegment: dw 0734h
    opCode: times 10 db 0
    mod: db 0
    rm: db 0
    reg: db 0
    lastBit: db 0
    secondToLastBit: db 0
    num: db 0
    space: db ' ', '$'
    currByte: db 0
    hexNum: db 0, 0