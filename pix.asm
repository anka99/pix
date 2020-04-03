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
        xor     %3, %3          ; set result to 0
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
point1:
        mov     rcx, rax        ; rcx = 16 ^ (k - n + 1)

        inc     %1              ; k++
        mov     rax, 8
        mul     %1              ; rax = 8 * (k + 1)
point2:
        add     rax, %2         ; rax = 8 * (k + 1) + j
 
        mul     rcx             ; rax = 16 ^ (k - n + 1) * (8 * (k + 1) + j)
        cmp     rdx, 0          ; if rax > 2 ^ 64, end the loop
        jne     %%end
        mov     rdi, rax        ; rdi = 16 ^ (k - n + 1) * (8 * (k + 1) + j)
        
        jmp     %%loop
%%end:

%endmacro

pix:
        ; push    rbx
        ; push    rsp
        ; push    rbp
        ; push    r12
        ; push    r13
        ; push    r14
        ; push    r15

        mov     r12, rdi
        mov     r13, rsi
        mov     r14, rdx

        rdtsc                       ;EDX:EAX             ;
        shl     rdx, 32
        add     rdx, rax
        mov     rdi, rdx
        mov     rax, 0
        call    pixtime

        mov     rsi, 7
        mov     r8, 5

        second_sum rsi, r8, r15

        mov     rdi, r15
        mov     rax, 0
        call    pixtime


        jmp     my_exit



; _loop:
;         mov     r8, 1
;         lock\
;         xadd    [pidx], r8  ;store m value in r8
;         cmp     r8, max
;         jge     _pix_end



;         jmp     _loop
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