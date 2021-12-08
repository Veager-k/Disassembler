org 100h

section .text
start:
    jmp 5
    jmp .here
    jmp 3
    jmp 04DFh:0234h
    .here
    jmp [bx+si]
    jmp [bx+di]
    jmp [bp+si]
    jmp [bp+di]
    jmp si
    jmp di
    jmp ax
    jmp bx
    jmp [si]
    jmp [di]
    jmp [bp]
    jmp [bx]
    jmp [bp+si+4h]
    jmp [bp+di+16h]
    jmp [si-5]
    jmp [di-128]
    jmp [di+127]
    jmp [bp+111h]
    jmp [bx+257]
    jmp [bx+si+32h]
    jmp [bx+di+1h]
    jmp far [bx]
    jmp far [bx+si+4584]

    ret
    ret 548h
    retf
    retf 87A5h
      
    .jmp_here
    je .jmp_here
    jl .jmp_here
    jle .jmp_here
    jb .jmp_here
    jbe .jmp_here
    jp .jmp_here
    jo .jmp_here
    js .jmp_here
    jne .jmp_here
    jnl .jmp_here
    jnle .jmp_here
    jnb .jmp_here
    ja .jmp_here
    jnp .jmp_here
    jpo .jmp_here
    jno .jmp_here
    jns .jmp_here
    loop .jmp_here
    loopz .jmp_here
    loopnz .jmp_here
    jcxz .jmp_here

    int 21h
    int 3
    int 80h

    INTO
    IRET

    clc
    cmc
    stc
    cld
    std
    cli
    sti
    hlt
    wait
    lock