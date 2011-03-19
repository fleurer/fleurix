puts %{
;; generated by entry.S.rb
;; do not touch

[bits 32]

;;
;; entry to main() in C, should never return
;;
[extern main]
    jmp main
_spin:
    jmp _spin


;;
;; on task switch
;; _do_swtch(struct jmp_buf *old, struct jmp_buf *new);
;;
[global _do_swtch]
_do_swtch:
    mov eax, dword [esp+4]  ;; new
    pop dword [eax]         ;; *old
    mov dword [eax+4], esp
    mov dword [eax+8], ebx
    mov dword [eax+12], ecx
    mov dword [eax+16], edx
    mov dword [eax+20], esi
    mov dword [eax+24], edi
    mov dword [eax+28], ebp

    mov eax, dword [esp+4]

    mov ebp, dword [eax+28]
    mov edi, dword [eax+24]
    mov esi, dword [eax+20]
    mov edx, dword [eax+16]
    mov ecx, dword [eax+12]
    mov ebx, dword [eax+8]
    mov esp, dword [eax+4]
    push dword [eax]
    ret

;;
;; retu(uint eip, uint esp3)
;; return to user mode via an IRET instruction.
;; note:  
;;    USER_CS = 0x1B
;;    USER_DS = 0x23
;; 
[global _retu]
_retu:
    pop dword eax       ;; ignore the returned eip
    pop dword ebx       ;; eip -> ebx
    pop dword ecx       ;; esp3 -> ecx
    mov ax, 0x23 
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    push dword 0x23     ;; ss3
    push dword ecx      ;; esp3
    pushf               ;; eflags
    push dword 0x1B     ;; cs
    push dword ebx      ;; eip
    iretd

;;
;; entry to trap handlers
;; 

[section .text]
[global _hwint_ret]
[extern hwint_common]

;; 
;; hard coded, take an eye on what you does.
;;
;; this routine is called on each isr & irq is raised. store the current cpu state on the kernel stack.
;; kernel stack is pointed by the esp0 field inside tss.
;; 
;; the routine _hwint_ret is the execution entry of a new proc. 
;;
_hwint_common_stub:
    sti
    pusha
    push dword ds
    push dword es
    push dword fs
    push dword gs
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov eax, esp
    push eax                        ; esp is just the pointer to struct trap *.
    mov eax, hwint_common           ; calls hwint_common() in C
    call eax
    pop eax
_hwint_ret:
    pop dword gs
    pop dword fs
    pop dword es
    pop dword ds
    popa
    add esp, 8
    iret
}

NINT = 128
0.upto(NINT) do |i|
  puts %{
    _hwint#{i}:
      #{'push  dword 0' if i!=17 and (i<8 or i>14)}
      push  dword #{i}
      jmp   _hwint_common_stub
  }
end

# generate the vector table
puts %{
; vector table
[section .data]
[global  _hwint]

_hwint:
}
0.upto(NINT) do |i|
  puts "  dd _hwint#{i}"
end
