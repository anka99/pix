SYS_WRITE equ 1
SYS_EXIT  equ 60
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


; k = n + 1, j, result
%macro second_sum 3
        mov     qword %3, 0     ; set result to 0
        ;xor     %3, %3
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
        cmp     rbx, 1
        je      %%inc
        div     rbx             ; rax = ((16 ^ (n - k) % (8k + j)) * 2^64)
                                ;       -----------------------------------
                                ;                   8k + j

        add     %3, rax         ; add component to sum
%%inc:
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
        pop     rbx
%endmacro



%macro print_pixtime 0
        rdtsc                       ;EDX:EAX             ;
        shl     rdx, 32
        add     rdx, rax
        mov     rdi, rdx
        mov     rax, 0
        call    pixtime
%endmacro

; ;n, result
; %macro count_sum 2
;         push    r15
;         count_sj %1, 1, r15     ; r15 = S1
;         mov     rax, 4          
;         mul     r15             ; rax = 4 * S1
;         mov     %2, rax         ; result = 4 * S1
;         count_sj %1, 4, r15     ; r15 = S4
;         mov     rax, 2
;         mul     r15             ; rax = 2 * S4
;         add     %2, rax         ; result = 2 * S4 + 4 * S1
;         count_sj %1, 5, r15     ; r15 = S5
;         add     %2, r15         ; result = S5 + 2 * S4 + 4 * S1
;         count_sj %1, 6, r15     ; r15 = S6
;         add     %2, r15         ; result = S6 + S5 + 2 * S4 + 4 * S1
;         pop     r15
; %endmacro

pix:
        push    rbx
        push    rsp
        push    rbp
        push    r12
        push    r13
        push    r14
        push    r15

        mov     ppi, rdi
        mov     pidx, rsi
        mov     max, rdx
        
        print_pixtime

_loop:
        push    ppi             ; store ppi pointer on stack
        mov     r15, 1
        lock\
        xadd    [pidx], r15     ; r15 = m, [pidx] = m + 1
        cmp     r15, max
        jge     _pix_end

        push    r15             ; store m value on stack
        mov     rax, 8          ; rax = 8m
        mul     r15             ; rax = 8m
        mov     r12, rax        ; r12 = rax = 8m
        
        push    r13             ; store r13 value on stack

        push    r15
        push    qword 6
        push    r12
        call    count_sj_function
        pop     r12
        pop     rax             ; garbage
        push    r15             ; result
        push    r15             ; stack : S6
        count_sj r12, 5, r15    
        push    r15             ; stack : S5, S6
        count_sj r12, 4, r15
        shl     r15, 1          ; r15 = 2S4
        push    r15             ; stack : 2S4, S5, S6
        count_sj r12, 1, r15
        shl     r15, 2          ; r15 = 4S1
        
        pop     r13             ; r13 = S5
        sub     r15, r13
        pop     r13             ; r13 = 2S4
        sub     r15, r13
        pop     r13             ; r13 = 4S1
        sub     r15, r13        ; r15 = {4{16nS1}−2{16nS4}−{16nS5}−{16nS6}} * 2 ^ 64

        pop     r13             ; restore value of r13

        shr     r15, 32         ; take 32 elder bits

        pop     rbx             ; pop m value from stack

        pop     ppi             ; pop ppi pointer from stack
        
        mov     [ppi + 4 * rbx], r15d
        jmp     _loop

_pix_end:
        pop    ppi
        print_pixtime
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     rbp
        pop     rsp
        pop     rbx
        ret

; stack : function call, n, j, result
count_sj_function:
        push    r14
        mov     rsi, [rsp + 3 * 8]              ; j
        mov     r8, [rsp + 2 * 8]               ; n

        jmp     my_exit
        first_sum rsi, r8, r14                  ; j, n, result

        mov     rsi, [rsp + 3 * 8]              ; j
        mov     r8, [rsp + 2 * 8]               ; n
        inc     r8                              ; n + 1

        second_sum r8, rsi, [rsp + 4 * 8]       ; k = n + 1, j, result

        add     [rsp + 4 * 8], r14              ; add first sum to the second 
                                                ; sum result 
        pop     r14
        ret

exit_0:
        mov     eax, SYS_EXIT
        mov     rdi, 0              ; kod powrotu 0
        syscall

my_exit:
        mov     rdi, rsi
        mov     eax, SYS_EXIT
        syscall
