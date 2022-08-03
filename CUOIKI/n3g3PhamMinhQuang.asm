.eqv SEVENSEG_LEFT    0xFFFF0011 # Dia chi cua den led 7 doan trai	
					#Bit 0 = doan a         
					#Bit 1 = doan b	
					#Bit 7 = dau . 
.eqv SEVENSEG_RIGHT   0xFFFF0010 # Dia chi cua den led 7 doan phai 
.eqv IN_ADRESS_HEXA_KEYBOARD       0xFFFF0012  
.eqv OUT_ADRESS_HEXA_KEYBOARD      0xFFFF0014	
.eqv KEY_CODE   0xFFFF0004         # ASCII code from keyboard, 1 byte 
.eqv KEY_READY  0xFFFF0000        	# =1 if has a new keycode ?                                  
				        # Auto clear after lw  
.eqv DISPLAY_CODE   0xFFFF000C   	# ASCII code to show, 1 byte 
.eqv DISPLAY_READY  0xFFFF0008   	# =1 if the display has already to do  
	                                # Auto clear after sw  
.eqv MASK_CAUSE_KEYBOARD   0x0000034     # Keyboard Cause    
  
.data 
BYTE_HEX     : .byte 63,6,91,79,102,109,125,7,127,111 #he thap phan cua cac chu so hien tren left 7 thanh tu 0 den 9
inputString : .space 1000				#cap phat dia chi luu chuoi nhap vao
initString :.space 1000
STRING_DEFAULT:   .asciiz "Bo mon ky thuat may tinh" 
STRING_INFO_MESSAGE: .asciiz "Please enter string(under 100 character):"
INPUT_STRING_MESSAGE: .asciiz "Do you want change default string"
STRING_PER_SECOND_MESSAGE: .asciiz "\n total key per second  :  "
COUNT_KEY_CORRECT: .asciiz  "\n number of key corect: "  
QUIT_MESSAGE: .asciiz "\n Do you countine progam? "
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
# MAIN
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
.text
#--------------------------------------------------------------------------------------------
# @brief		Hoi nguoi dung muon dung STRING_DEFAULT hay tu khoi tao mot chuoi khac tu ban phim 

# @param[out]		$a0 la status cua confirm dialog
#--------------------------------------------------------------------------------------------	
	li $v0,50
	la $a0,INPUT_STRING_MESSAGE
	syscall
	bnez $a0,defaultString
#--------------------------------------------------------------------------------------------
# @brief		Khoi tao gia chuoi ban dau tu ban phim
# @param[out]		$s7 Do dai cua chuoi vua khoi tao
#--------------------------------------------------------------------------------------------	
changeDefaultString:
	li $v0,54
	la,$a0,STRING_INFO_MESSAGE
	la $a1,initString
	li,$a2,100
	syscall
	getLength:
	la $s0, initString
	addi $s1, $zero, 0	#s1 = length = 0
	addi $t1, $zero, 0	#t1 = i = 0
	findNullChar:
		add $t2, $s0, $t1	#t2 = pointer = initString + i 
		lb $t3, 0($t2) 		#t3 = STRING_INT[i]
		
		beq $t3, $zero,finishGetLength #if string_init[i] == '\0' -> finishGetLength
		
		addi $s7, $zero, 10
		beq $t3, $s7, updateString#if string_init[i] == '\n' -> bo di '\n'
		
		addi $s1, $s1, 1
		addi $t1, $t1, 1
		j findNullChar
	updateString:
		add $t1, $s0, $t1
		sb $zero, 0($t1)
	finishGetLength:
		add $s7, $zero, $s1 #i = length
		j finishCopyString
#--------------------------------------------------------------------------------------------
# @brief		Khoi tao gia tri mac dinh cho initString
# @param[out]		$s7 Do dai cua chuoi vua khoi tao
#--------------------------------------------------------------------------------------------	
defaultString:
	la $s0,initString
	la $s1,STRING_DEFAULT
	li $s7,24
	li,$t0,0 # bien dem chi so i cua vong lap
	copyString:
	slt $t1,$t0,$s7
	beq $t1,$zero, finishCopyString
	add $t1,$s1,$t0
	lb $t2,0($t1)
	add $t1,$s0,$t0
	sb $t2,0($t1)
	add $t0,$t0,1
	j copyString

	li,$v0,4
	la $a0,initString
	syscall

#--------------------------------------------------------------------------------------------
# @brief		Khoi tao ban phim MMIO
#--------------------------------------------------------------------------------------------	
finishCopyString:
	li   $k0,  KEY_CODE              
	li   $k1,  KEY_READY                    
	li   $s0, DISPLAY_CODE              
	li   $s1, DISPLAY_READY  	
main:         
	
	li $s4,0 			#dem toan bo ki tu nhap vao
  	li $s3,0			#dem so vong lap
 	li $t4,10			#hang so dung cho hien thi tren led 7 thanh
  	li $t5,200			#luu gia tri so vong lap
	li $t6,0			#bien dem so ky tu nhap duoc trong 1s
	li $s6,0			# khoi tao trang thai da so sanh inputString voi stringInit, mac dinh la chua so sanh
		
loop:          
waitForKey:  
 	lw   $t1, 0($k1)                  # $t1 = [$k1] = KEY_READY              
	beq  $t1, $zero,countTime         # if $t1 == 0 then Polling             
makeInterupt:
	addi $t6,$t6,1    		  #tang bien dem ky tu nhap duoc trong 1s len 1
	teqi $t1, 1                       # if $t0 = 1 then raise an Interrupt    
#--------------------------------------------------------------------------------------------
# @brief		Dem khoang thoi gian cho du 1s va thong bao so ki tu nguoi dung go duoc trong 1s
# @param[in]	$s3	So vong lap
# @param[out]		nhay dep sleep da du 1s
#--------------------------------------------------------------------------------------------	

countTime:          
	#neu da lap dk 200 vong( 1s) se nhay den xu ly so ky tu nhap trong 1s.
	addi    $s3, $s3, 1      	# dem so ky tu nhap vao tu ban phim.
	div $s3,$t5			#lay so vong lap chia cho 200 de xac dinh da duoc 1s hay chua
	mfhi $t7			#luu phan du cua phep chia tren
	bne $t7,0,sleep		#neu chua duoc 1s nhay den label sleep
					#neu da duoc 1s thi nhay den nhan SETCOUNT de thuc hien in ra man hinh
#--------------------------------------------------------------------------------------------
# @brief		Khoi tao lai so vong lap va in so ki tu nhap vao trong 1s
# @param[out]	$s3	So vong lap 
# @param[out]	$t6	So ki tu nhap vao trong 1s
#--------------------------------------------------------------------------------------------	
setCount:
	li $s3,0				#tai lap gia tri cua $t3 ve 0 de dem lai so vong lap cho cac lan tiep theo
	li $v0,4				
	la $a0,STRING_PER_SECOND_MESSAGE	
	syscall	
	li    $v0,1            		#in ra so ki nhap vao trong 1 giay
	add   $a0,$t6,$zero    		
	syscall
#--------------------------------------------------------------------------------------------
# @brief		Hien thi gia tri len 2 led 7 thanh
# @param[in]	$t6	Gia tri muon hien thi len led
#--------------------------------------------------------------------------------------------	
displayDigital: 
	div $t6,$t4			#lay so ky tu nhap duoc trong 1s chia cho 10, phan nguyen la gia tri hang chuc, phan du la gia tri hang don vi
	mflo $t7			#luu gia tri phan nguyen, gia tri nay se duoc luu o den LED ben trai( la gia tri hang chuc)
	la $s2,BYTE_HEX			#lay dia chi cua danh sach luu gia tri cua tung chu so den LED (la gia tri hang don vi)
	add $s2,$s2,$t7			#xac dinh dia chi cua gia tri 
	lb $a0,0($s2)                 	#lay noi dung cho vao $a0           
	jal  showSevenSegLeft       	# ngay den label den LED trai
#------------------------------------------------------------------------
	mfhi $t7			#luu gia tri phan du cua phep chia, gia tri nay se duoc in ra trong den LED ben phai
	la $s2,BYTE_HEX			
	add $s2,$s2,$t7
	lb $a0,0($s2)                	# set value for segments           
	jal showSevenSegRight      	# show    
#------------------------------------------------------------------------                                            
	li    $t6,0			#sau khi da hoan thanh dua bien dem so ky tu nhap duoc trong 1s ve 0 de bat dau cho chu ky moi
	beq $s6,1,quitProgram
#--------------------------------------------------------------------------------------------
# @brief		Sleep 5ms
#--------------------------------------------------------------------------------------------	
sleep:  
	addi    $v0,$zero,32                   
	li      $a0,5              	# sleep 5 ms         
	syscall         
	nop           	          	  
	b       loop          	 # Loop 
endMain: 
	li $v0,10
	syscall
	
showSevenSegLeft:  
	li   $t0,  SEVENSEG_LEFT 	# assign port's address                   
	sb   $a0,  0($t0)        	# assign new value                    
	jr   $ra 
	
showSevenSegRight: 
	li   $t0,  SEVENSEG_RIGHT 	# assign port's address                  
	sb   $a0,  0($t0)         	# assign new value                   
	jr   $ra 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  Interrupt subroutine
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
.ktext    0x80000180         		#chuong trinh con chay sau khi interupt duoc goi.         
	mfc0  $t1, $13                  # cho biet nguyên nhân làm tham chieu dia chi bo nho khong hop
	li    $t2, MASK_CAUSE_KEYBOARD              
	and   $at, $t1,$t2              
	beq   $at,$t2, counterKeyboard               
	j    endProcess  


counterKeyboard: 
keyRead:  lb   $t0, 0($k0)            		# $t0 = [$k0] = KEY_CODE 
waitForDis: 
	     lw   $t2, 0($s1)            	# $t2 = [$s1] = DISPLAY_READY            
	     beq  $t2, $zero, waitForDis	# if $t2 == 0 then Polling                             
showKey: 
	     sb $t0, 0($s0)              	# hien thi ky tu vua nhap tu ban phim tren man hinh MMIO
             la  $t7,inputString			# lay $t7 lam dia chi co so cua chuoi nhap vao
             add $t7,$t7,$s4		
             sb $t0,0($t7)
             addi $s4,$s4,1
             beq $t0,10,end		# neu nhan enter thi show so ki tu dung nguoi dung da nhap                          
endProcess:                         
next_PC:   mfc0    $at, $14	        # $at <= Coproc0.$14 = Coproc0.epc              
	    addi    $at, $at, 4	        # $at = $at + 4 (next instruction)              
            mtc0    $at, $14	       	# Coproc0.$14 = Coproc0.epc <= $at  
return:   eret                       	# tro ve len ke tiep cua chuong trinh chinh
end:
	li $v0,11         
	li $a0,'\n'         		#in xuong dong
	syscall 
	li $t1,0 			#dem so ky tu da duoc xet
	li $t3,0                        # dem so ky tu nhap dung
	add $t8,$s7,$zero		#luu $t8 la do dai xau da luu tru trong ma nguon.
	slt $t7,$s4,$t8			#so sanh xem do dai xau nhap tu ban phim va do dai cua xau co dinh trong ma nguon
					#xau nao nho hon thi duyet theo do dai cua xau do
	bne $t7,1, compareString	
	add $t8,$0,$s4
	addi $t8,$t8,-1			#tru 1 vi ky tu cuoi cung la dau enter thi khong can xet.
#--------------------------------------------------------------------------------------------
# @brief		kiem tra xem chuoi minh nhap vao tu ban phim voi chuoi initString 
# @params[in]	$s7	Do dai cua chuoi initString 	
# @params[in]	$s4	Do dai cua chuoi nhap vao
# @params[out] $t3	So ki tu go chinh xac cua nguoi dung
#--------------------------------------------------------------------------------------------	
compareString:			
	la $t2,inputString
	add $t2,$t2,$t1
	li $v0,11			#in ra cac ky tu da nhap tu ban phim.
	lb $t5,0($t2)			#lay ky tu thu $t1 trong inputString luu vao $t5 de so sanh voi ky tu thu $t1 o initString
	move $a0,$t5			
	syscall 			
	la $t4,initString		
	add $t4,$t4,$t1			
	lb $t6,0($t4)			#lay ky tu thu $t1 trong initString luu vao $t6
	bne $t6,$t5,continue		#neu 2 ky tu thu $t1 giong nhau thi tang bien dem so ky tu dung len 1
	addi $t3,$t3,1			
continue: 
	addi $t1,$t1,1			#sau khi so sanh 1 ky tu, tang bien i dem len 
	beq $t1,$t8,printResult		#neu da duyet het so ky tu can xet thi in ra man hinh so ky tu nhap dung
	j compareString		#con khong thi tiep tuc xet tiep cac ky tu 
#--------------------------------------------------------------------------------------------
# @brief		in ket qua ra led 7 thanh va man hinh
# @params[in]	$t3	So ki tu nguoi dung nhap dung 	
# @params[in]	$s6	Trang thai cua nguoi dung xem ket thuc nhap chua
# @params[out] $t6	So ki tu go chinh xac cua nguoi dung
#--------------------------------------------------------------------------------------------	
printResult:	
	li $v0,4
	la $a0,COUNT_KEY_CORRECT	
	syscall
	li $v0,1
	add $a0,$0,$t3
	syscall				#in ra so ki tu nguoi dung nhap dung
	
	li $t6,0			#sau khi ket thuc chuong trinh, so ky tu dung duoc luu vao $t6 roi quay tro ve phan hien thi.
	li $t4,10			# thanh ghi $t4 gan tro lai gia tri 10 o lenh tren $t4 luu gia tri dia chi cua source code
	add $t6,$zero,$t3
	li $s6,1			#set trang thai da so sanh chuoi nhap vao(inputString) voi chuoi (stringInit)
	b  displayDigital
#--------------------------------------------------------------------------------------------
# @brief		Xac nhan nguoi dung co muon thoat chuong trinh khong 
#--------------------------------------------------------------------------------------------
quitProgram: 
	li $v0, 50
	la $a0, QUIT_MESSAGE
	syscall
	beq $a0,0,main		
	li,$v0,10
	syscall
	



