%define ppi r12
%define pidx r13
%define max r14

SECTION .TEXT
        GLOBAL pix
        extern pixtime

; Counts second sum from stackexchange formula
; Macro arguments: k = n + 1, j, result
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
        
        shl     rcx, 4          ; rcx = 16 ^ (k - n + 1)

        inc     %1              ; k++
        mov     rax, 8
        mul     %1              ; rax = 8 * (k + 1)

        add     rax, %2         ; rax = 8 * (k + 1) + j
 
        mul     rcx             ; rax = 16 ^ (k - n + 1) * (8 * (k + 1) + j)
        cmp     rdx, 0          ; if rax > 2 ^ 64, end the loop
        jne     %%end
        mov     rdi, rax        ; rdi = 16 ^ (k - n + 1) * (8 * (k + 1) + j)
        
        jmp     %%loop          ; continue loop
%%end:

%endmacro

; Counts 16 to the given power, taking given modulo in O(log power)
; Macro arguments: power, modulo, result
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
        div    %2            ; rdx = (current power of 16) % modulo
        shr    %1, 1         ; power = power/2
        mov    rcx,rdx       ; rcx = rdx = (current power of 16) % modulo
        jne    %%loop        ; continue if power != 0
  %%end:	   	
%endmacro

; Counts first sum from stackexchange formula
; Macro arguments: j, n, result
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

        xor     rax, rax        ; set rax to 0
        mov     rdx, r13        ; rdx:rax = (16 ^ (n - k) % (8k + j)) * 2^64
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

; Prints number of processor cycles
%macro print_pixtime 0
rdtsc                           ; EDX:EAX             
        shl     rdx, 32
        add     rdx, rax        ; store rdtsc result in rdx
        mov     rdi, rdx
        mov     rax, 0
        call    pixtime
%endmacro

pix:
        push    rbx             ; store on stack values of registers that 
        push    rsp             ; should remain unchanged
        push    rbp
        push    r12
        push    r13
        push    r14
        push    r15

        mov     ppi, rdi
        mov     pidx, rsi
        mov     max, rdx
        
        print_pixtime           ; call function pixtime

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

        mov     rax, 6
        push    rax
        call count_sj_function
        pop     rax             ; j value - garbage
        push    r15             ; stack : S6
        mov     rax, 5
        push    rax
        call count_sj_function
        pop     rax             ; j value - garbage   
        push    r15             ; stack : S5, S6
        mov     rax, 4
        push    rax
        call count_sj_function
        pop     rax             ; j value - garbage
        shl     r15, 1          ; r15 = 2S4
        push    r15             ; stack : 2S4, S5, S6
        mov     rax, 1
        push    rax
        call count_sj_function
        pop     rax             ; j value - garbage
        shl     r15, 2          ; r15 = 4S1
        
        pop     r13             ; r13 = S5
        sub     r15, r13
        pop     r13             ; r13 = 2S4
        sub     r15, r13
        pop     r13             ; r13 = 4S1
        sub     r15, r13        ; r15 = 
                                ; {4{16nS1}−2{16nS4}−{16nS5}−{16nS6}} * 2 ^ 64
        pop     r13             ; restore value of r13

        shr     r15, 32         ; take 32 elder bits

        pop     rbx             ; pop m value from stack

        pop     ppi             ; pop ppi pointer from stack
        
        mov     [ppi + 4 * rbx], r15d
        jmp     _loop

_pix_end:
        pop    ppi              ; ppi is on top of the stack
        print_pixtime           ; call function pixtime
        pop     r15             ; pop unchanged registers from stack 
        pop     r14
        pop     r13
        pop     r12
        pop     rbp
        pop     rsp
        pop     rbx
        ret

; stack: function call, j value
count_sj_function:
        push    rbx
        push    r14

        mov     rsi, [rsp + 8 * 3]  ; copy j  value from stack
        mov     r8, r12             ; n
        first_sum rsi, r8, r14      ; j, n, result

        mov     rsi, [rsp + 8 * 3]  ; copy j  value from stack

        mov     r8, r12             ; n
        inc     r8                  ; n + 1

        second_sum r8, rsi, r15     ; k = n + 1, j, result

        add     r15, r14            ; r15 = first sum result + second sum result
        pop     r14
        pop     rbx
        ret