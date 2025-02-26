.global main

.text
    FmtSpecifier: .asciz "%"
    d: .asciz "d"
    u: .asciz "u"
    s: .asciz "s"
    
    FmtString: .asciz "Hi im %s, I am %u years %% old %t"
    Param1: .asciz "Simon"   # %s paramters are stored in memory at .text directory
    Param2: .asciz "Pietro"

    cleanOuput: .asciz "\n"


main: 
    pushq %rbp
    movq %rsp, %rbp             
    
    # push parameters on stack, placeholder parameters have to be pushed in opposite order of their specifiers in fmtString
    # the amount of specifier parameters pushed on stack has to equal or greater than their occurence in the fmtstring
    
    ###########  placeholder parameters  ############# 
    pushq $-2000                    # %d & %u paramters are pushed as their immediate value      
    pushq $Param2                   # for %s paramters u shall pass the address of the first character
    pushq $-2000
    pushq $Param1
    ##################################################

    pushq $FmtString                # last item pushed on stack is to be the formatString address

    call my_printf
                   
    movq $cleanOuput, %rsi 
    movq $1, %rax
    movq $1, %rdi
    movq $1, %rdx
    syscall                       
    
    movq $0, %rdi
    call exit


my_printf:
    pushq %rbp      
    movq %rsp, %rbp             # calling convention storing previous %base pointer
    movq 16(%rsp), %rsi         # stack: PrevBasePointer--> Return Address(8) --> FormatString(16), %rsi contains address at $fmtString      

    movq $d, %rbx               # store all format specifiers in dedicated callee saved 8-bit registers
    movb (%rbx), %r13b          #
    movq $u, %rbx
    movb (%rbx), %r14b          #
    movq $s, %rbx
    movb (%rbx), %r15b          #   
    
    movq $FmtSpecifier, %rbx    # "%" detection in string 
    movb (%rbx), %bl            
loop1:
    movb (%rsi), %al            # check char at %rsi 
    cmpb $0x0, %al              # string has terminated(.asciz) end routine
    je end
    cmpb %al, %bl               # possible format specifier detected 
    je checkSpecifier           # check

    movq $1, %rax
    movq $1, %rdi
    movq $1, %rdx
    syscall                     # if "%" wasnt detected & string has not ended, print char normally

    incq %rsi                   # point %rsi to next char 
    jmp loop1                   
end:
    popq %rbp                   # restore contents of %rbp for the calling routine
    ret                         # pop return address from stack and return 

# # # # # # # #     % char has been detected, check for compatible specifiers   # # # # # # # #  


checkSpecifier:
    incq %rsi               # point %rsi to char next to "%"
    movb (%rsi), %al        

    cmpb %al, %r13b             # compare char next to "%" with all compatible specifiers for our program  
    je SignedIntPrint           #
    cmpb %al, %r14b             #
    je UnsignedIntPrint         #
    cmpb %al, %r15b             #
    je NullTerminatedPrint      #
    cmpb %al, %bl               #
    je PercentageSignPrint      #

    decq %rsi               # none of the compatible specifiers where detected, point %rsi back to % --> print % char normally 

    movq $1, %rax
    movq $1, %rdi
    movq $1, %rdx
    syscall     

    incq %rsi               # point %rsi to next char 
    jmp loop1


# # # # # # # #  Section To Format the values accordingly # # # # # # # #


SignedIntPrint:
    movq %rsp, %rax
    addq $24, %rax          # rax now pointing to second parameter on stack
    movq (%rax), %rax       # rax now contains parameter content 

    movq %rsi, %r12         # save contents of %rsi in temporay %r12 as %rsi will be used in printNumString
    movq $0, %rbx           # set buildNumString counter to 0
    jmp checkSign


UnsignedIntPrint:
    movq %rsp, %rax
    addq $24, %rax          # %rax now pointing to second parameter on stack
    movq (%rax), %rax       # %rax now contains parameter content 

    movq %rsi, %r12         # save contents of %rsi in temporay %r12 as %rsi will be used in printNumString
    movq $0, %rbx           # set buildNumString counter to 0
    jmp buildNumString
    

NullTerminatedPrint:
    movq %rsp, %rax
    addq $24, %rax          # %rax now pointing to second paramter on stack 
    
    pushq %rsi              # save %rsi in stack
    movq (%rax), %rsi       # move parameter at %rax into %rsi
loop2: 
    movb (%rsi), %al        # move 8-bit char at location %rsi(paramter) into %al
    cmpb $0x0, %al          # if %al contains null byte, string has terminated
    je endNullstrPrint  

    movq $1, %rax
    movq $1, %rdi
    movq $1, %rdx
    syscall                 # while string has not terminated, print char at %rsi

    incq %rsi               # point %rsi to next char
    jmp loop2               
endNullstrPrint:
    popq %rsi               # restore contents of %rsi to point to the main fmtString
    incq %rsi               # increase %rsi to point to the next char

    popq %r8                # save %rbp
    popq %r9                # save return address
    popq %r10               # save FmtString
    addq $8, %rsp           # remove parameter from stack
    pushq %r10              # restore stack contents
    pushq %r9               #
    pushq %r8               # 
    
    jmp loop1


PercentageSignPrint:
    pushq %rsi                  # save contents of %rsi

    movq $FmtSpecifier, %rsi    # location of percentage sign char found at (same as)$formatSpecifier    
    movq $1, %rax
    movq $1, %rdi
    movq $1, %rdx
    syscall                     # print %percentage sign (aka formatSpecifier)

    popq %rsi                   # restore contents at %rsi
    incq %rsi                   # %rsi pointing to next char
    jmp loop1
    

# # # # # # # #   Section For Unsigned & Signed Integer Print   # # # # # # # #


checkSign:
    cmpq $0, %rax
    jge buildNumString
    #                       # if %rax is negative 
    notq %rax               # convert %rax to positive
    incq %rax

    pushq %rax
    pushq $45               # ascii value for hyphen sign ("-")

    movq %rsp, %rsi         # location of hyphen sign store in %rsp to be printed                         
    movq $1, %rax
    movq $1, %rdi
    movq $1, %rdx
    syscall                 # print Hyphen sign

    addq $8, %rsp           # pop Hyphen sign
    popq %rax               # get positive value back
    jmp buildNumString      # begin printing process for positive number in %rax 


buildNumString:
    movq $0, %rdx           # set remainder register to 0
    movq $10, %rcx          
    divq %rcx               # divide %rax by 10 and store result in %rax
    addq $48, %rdx          # the remainder digit is increased by 48 as digits in asci are encoded as x + 48
    pushq %rdx              # push ascii encoded digit on stack
    incq %rbx               # increment %rbx counter
    cmpq $0, %rax           # if rax = 0, all remainders are pushed on stack, print remainders in opposite order
    je printNumString       
    jmp buildNumString
printNumString:
    cmpq $0, %rbx           # check counter, if 0 --> all stack remainders have been popped --> end Print
    je EndNumPrint

    movq %rsp, %rsi         # location of last pushed asci converted remainder in %rdx moved to %rsi for print                         
    movq $1, %rax
    movq $1, %rdi
    movq $1, %rdx
    syscall
                
    addq $8, %rsp           # pop stack without saving content
    decq %rbx               # decrease %rbx counter
    jmp printNumString


EndNumPrint:
    movq $FmtSpecifier, %rbx    # restore contentx of %rbx, previously used as a counter, for %bl to contain % char
    movb (%rbx), %bl            

    popq %r8                # save %rbp
    popq %r9                # save return address
    popq %r10               # save FmtString
    addq $8, %rsp           # remove parameter from stack
    pushq %r10              # restore stack contents
    pushq %r9               #
    pushq %r8               #

    movq %r12, %rsi         # restore contents of %rsi
    incq %rsi               # increment %rsi to next char ins FmtString
    jmp loop1               # jmp to loop1





