SYS_READ  equ 0
SYS_WRITE equ 1
SYS_EXIT  equ 60
STDIN     equ 0
STDOUT    equ 1

%define ppi r12
%define pidx r13
%define max r14

SECTION .DATA
    hello:     db 'Hello world!',10
    helloLen:  equ $-hello

SECTION .TEXT
        GLOBAL pix
        extern pixtime

;text, length
%macro print 2
        mov     rax, SYS_WRITE      ; write()
        mov     rdi, STDOUT         ; STDOUT
        mov     rsi, %1
        mov     rdx, %2
        syscall 
%endmacro

; k = n + 1, j, result
%macro second_sum 3
        xor     %3, %3
        mov     rax, 8          ; rax = 8
        mul     %1              ; rax = 8k
        add     rax, %2         ; rax = 8k + j
        mov     r9, 16
        mul     r9              ; rax = 16(8k + j)
        mov     rdi, rax        ; rdi = 16(8k + j)

        mov     rcx, 16 
%%loop:

        mov     rdx, 1
        xor     rax, rax        ; result * 2^64

        div     rdi             ; rax = 2^64 * 1/(16(8k + j))
        mov     rdi, rax

        add     %3, rax         ; add component to sum

        mov     rax, 16
        mul     rcx 

        mov     rcx, rax        ; rcx = 16 ^ (k - n + 1)

        inc     %1              ; k++
        mov     rax, 8
        mul     %1              ; rax = 8 * (k + 1)

        add     rax, %2         ; rax = 8 * (k + 1) + j
 
        mul     rcx             ; rax = 16 ^ (k - n + 1) * (8 * (k + 1) + j)
        cmp     rdx, 0          ; if rax > 2 ^ 64, end the loop
        jne     %%end
        mov     rdi, rax        ; rdi = 16 ^ (k - n + 1) * (8 * (k + 1) + j)
        
        jmp     %%loop
%%end:

%endmacro

;power, modulo, result
%macro quick_pow_mod 3

        mov    %3, 0x1       ; store result in %3
        test   %1, %1
        je     %%end         ; if power == 0 result is 1
        mov    ecx, 0x10     ; store power of 16 in rcx
        mov    %3, 0x1       ; store result in %3
%%loop:	
        test   %1, 0x1       
        je     %%even_odd    ; for even power skip odd part
        mov    rax, %3
        xor    edx, edx
        imul   rax, rcx      ; multiply result by current power of 16
        div    %2            ; rdx = result % modulo
        mov    %3, rdx       ; result = result % modulo
%%even_odd:
        imul   rcx, rcx      ; double current power of 16
        xor    edx, edx
        mov    rax, rcx
        div    %2           ; rdx = (current power of 16) % modulo
        shr    %1, 1        ; power = power/2
        mov    rcx,rdx      ; rcx = rdx = (current power of 16) % modulo
        jne    %%loop       ; continue if power != 0
  %%end:	   	
%endmacro

;j, n, result
%macro first_sum 3
        push    rbx
        push    rcx
        push    r12
        push    r13
        xor     rcx, rcx        ; k = 0
        mov     rbx, %1         ; store 8k + j in rbx
        xor     %3, %3          ; set sum to 0
        mov     r12, %2         ; store n - k in r12
%%loop:
        cmp     rcx, %2
        jg      %%end           ; if k > n, end loop

        push    r12
        push    rcx
        quick_pow_mod r12, rbx, r13 ;r13 = 16 ^ (n - k) % (8k + j)
        pop     rcx
        pop     r12

        xor     rax, rax
        mov     rdx, r13        ; (16 ^ (n - k) % (8k + j)) * 2^64

        div     rbx             ; rax = ((16 ^ (n - k) % (8k + j)) * 2^64)
                                ;       -----------------------------------
                                ;                   8k + j

        add     %3, rax         ; add component to sum

        inc     rcx             ; k++
        dec     r12             ; r12 = n - (k + 1)
        add     rbx, 8          ; rbx = 8(k + 1) + j
        jmp     %%loop          ; continue
%%end:
        pop     r13
        pop     r12
        pop     rcx
        pop     rbx
%endmacro

; n, j, result
%macro count_sj 3
        push    rbx
        push    r12
        push    r14

        mov     rsi, %2         ; j
        mov     r8, %1          ; n
        first_sum rsi, r8, r14  ; j, n, result

        mov     rsi, %2         ; j
        mov     r8, %1          ; n
        inc     r8              ; n + 1

        second_sum r8, rsi, %3  ; k = n + 1, j, result

        add     %3, r14
        pop     r14
        pop     r12
        pop     rbx
%endmacro

pix:
        push    rbx
        push    rsp
        push    rbp
        push    r12
        push    r13
        push    r14
        push    r15

        mov     r12, rdi
        mov     r13, rsi
        mov     r14, rdx

        ; rdtsc                    ; EDX:EAX  
        ; shl     rdx, 32
        ; add     rdx, rax

        mov     rsi, 32
        mov     rdi, 5
        ; n, j, result
        count_sj 32, 5, r15
        mov     rdi, r15
        mov     rax, 0
        call    pixtime


        jmp     exit_0

_pix_end:
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     rbp
        pop     rsp
        pop     rbx
        ret

exit_0:
        mov     eax, SYS_EXIT
        mov     rdi, 0              ; kod powrotu 0
        syscall

my_exit:
        mov     rdi, r12
        mov     eax, SYS_EXIT
        syscall
        
; _loop:
;         mov     r8, 1
;         lock\
;         xadd    [pidx], r8  ;store m value in r8


;         cmp     r8, max
;         jge     _pix_end
;         jmp     _loop