  ; DWIN OS
  ;;R0-R9特殊用途寄存器
  ;****故障显示和保存****
  ;
  ;。
  ;R255上电初始化判断。
  ;R236-R239(R239用于延时10s)给上传下载;R216 R217给新故障发生标志,R219在系统参数页只赋值一次.R210用于控制上电收到主板数据后延时跳到主界面
  ;DGUS变量6FFA~6FFF已用
  
初始化:;上电初始化,INT上电后只会运行一次。;INT:
  
  IJNE   R255,0,INIRET
  LDBR   R255,1,1
  ;;;;;lsz 11.23添加
  ;;;;
  LDWR	R30,400H
  MOVRD	R30,4AH,2	;4s的定时器
  LDBR	R33,64H,1
  MOVRD	R33,02H,1	;蜂鸣器响1S
  
  ;;;;;;;;
	    LDBR 	R4,02H,1;加载用户数据库地址02 87 01 10到R4、R5、R6、R7
		LDBR 	R5,87H,1
		LDBR 	R6,01H,1
		LDBR 	R7,10H,1
		LDWR 	R0,6FFFH
		MOVXL 	2,01H;上电写存储的从机地址值
		MOVXR	R42,1,1
		LDWR	R40,0003H
		JS		R42,R40,3;比较从机范围大小是否超出3，超出则改为1,并存到数据库
		LDWR	R42,0001H
		MOVXR	R42,0,0
		MOVXL	3,01H
		
		LDWR	R40,0000H
		JS		R40,R42,3;比较从机范围大小是否小于等于0，改为1,并存到数据库
		LDWR	R42,0001H
		MOVXR	R42,0,0
		MOVXL	3,01H
		
		LDBR	R33,5AH,1
		MOVRD	R33,1DH,1
		LDWR	R0,6FFFH
		MOVXR	R30,1,1
		MOVRD	R31,13H,1;修改从机地址为存储的值 
  
;  LDWR	R0,0314H	;转换上电置1标志 
;  LDWR  R30,0001H
;  MOVXR  R30,0,1
   
  LDWR   R0,6FFBH;版本号
  ;LDWR   R30,000AH   ;1.0版本
  LDWR   R30,000BH	  ;1.1版本
  MOVXR  R30,0,1
  
  	    LDBR 	R4,02H,1;加载用户数据库地址02 87 01 0F到R4、R5、R6、R7
		LDBR 	R5,87H,1
		LDBR 	R6,01H,1
		LDBR 	R7,0FH,1
		LDWR 	R0,0421H
		MOVXL 	2,01H;上电写存储的曲线等级值(同时也是目标温度上限等级)
		MOVXR	R42,1,1
		LDWR	R40,0002H
		JS		R42,R40,3;比较从机范围大小是否超出2，超出则改为0,并存到数据库
		LDWR	R42,0000H
		MOVXR	R42,0,0
		MOVXL	3,01H
 
  LDWR	 R0,04CEH;在主板没有写参数过来的前提下，默认开始时间=0，结束时间=1
  LDWR	 R30,0001H;定时器1结束时间=1
  MOVXR	 R30,0,1
  
  LDWR   R0,0BC3H;3001的第0位为上电写所有参数 标志位，置1时通知主机进行写操作，同时在所有数据写入成功前禁止用户对系统参数进行更改
  LDWR   R30,8000H
  MOVXR  R30,0,1  
  
  CALL  Fault_Recover;恢复故障记录 
  
  CALL	Clocker_Recover	;lsz.ll 2017-04-7 
  
  ;===========曲线功能
       LDWR		R0,2060H;JH，为了让每次上电后进入历史曲线界面时是在第1页而不是没有用处的第0页。
       LDWR		R30,1
       MOVXR	R30,0,1
       LDBR		R234,2,1;保险起见，这里上电也给赋了一个不同的值，可以删除本行。
       
       LDBR   R227,99,1
       LDWR   R4,0X028A
       LDWR   R6,0X0000
       LDWR   R0,0X2030
       MOVXL  2,3
       MOVXR  R228,1,3
       IJNE   R228,0XAB,WRITEINITE
       IJNE   R229,0XAB,WRITEINITE
       LDBR   R228,0,6
       GOTO   INIRET
	WRITEINITE:
       LDWR   R228,0XABAB  ;
       LDWR   R230,0X028A
       LDWR   R232,0X0003
       MOVXR  R228,0,3
       MOVXL  3,3
       LDBR   R228,0,6
INIRET:NOP
       RET
 
 MAIN:
	 CALL   初始化
	; CALL	主界面开关机
	 CALL	Power_on_jumping
	 CALL	星期一
	 CALL	Runtime_conversion;运行时间转换	 
	 CALL 	Factory_Password;   工厂密码
	 CALL 	Clock_DISPLAY;  定时
	 CALL 	Status_Display;			数据显示,包括模式、恒温停机、故障页显示	 
;	 LDWR  R33,5AA5H;  测试
;     LDWR  R0,0827H
;     MOVXR R33,0,1
     CALL	EEV_2000N
	 CALL 	Fault_Handle;			故障处理-故障显示、记录、读取	 
	 CALL 	Key_Handle;			按键处理:上传、下载触发
	 CALL 	PageID_Handle;		页面处理，主要是在特殊下，输入密码页面跳转处理
	 CALL 	Quit_dispaly
	 CALL 	SYSTEM_PAGE_JUMPING  ;各项参数跳转
;	 CALL 	SsyClock_Set         ;系统时间设置
	 CALL 	S09_display;A14=0时S09显示“无”，A14=1时S09显示“闭合“/”断开”
	 
	 ;;;;;;;;;;;;;;;;;;;;
	 ;;;;新添加的功能
	 CALL   newlyAddedFeature
	 ;;;;;;;;;;;;;;;;;;;
	 
	 ;===========曲线功能
	 曲线功能:
     CALL   清除数据库
     CALL   CLRSQL
     CALL   5分钟数据保存
     CALL   翻页画历史曲线
     CALL   翻页键功能
     CALL   CS
     CALL	横坐标显示
     CALL	曲线等级选择
 ;===========曲线功能
	 
;	 LDWR	R0,0BC3H;上电标志不为0，则不进行参数改动标志位的判断   jh 2016040B注销
;	 MOVXR	R30,1,1
;	 IJNE	R31,0,STOP
	 CALL 	READ;	*********485允许线控器与屏都可以修改工厂参数*******
	
 STOP:
     END
 
 Power_on_jumping:
	 LDWR	R40,0000H
	 MOVDR	04H,R41,1
	 LDWR	R42,0005H
	 JS		R40,R42,1;是否在上电界面，界面小于5则为上电界面
	 GOTO	Power_on_jumping_Ret
	 
	 LDWR	R0,0856H;上电界面，判断主板有没有写通信检测变量过来，有则立即跳到主界面，没有就等待
	 MOVXR	R30,1,1
	 LDWR	R32,0000H
	 JS		R32,R30,1
	 GOTO	Power_on_jumping_Ret
	 
	 INC	R210,0,01H
	 IJNE	R210,0AH,Power_on_jumping_Ret
	 LDBR	R210,0,1
	 LDBR	R40,05H,1
	 MOVRD	R40,04H,1;跳到主界面
 
 Power_on_jumping_Ret:
 	RET
 	
 
 Factory_Password:;-工厂密码 
		MOVDR   04H,R50,1
	    IJNE    R50,0CH,1
	    GOTO    Password_Compare	    
	    
	    IJNE    R50,0FH,Factory_Password_RET	
		
		Password_Compare:
		LDWR 	R0,340AH
		MOVXR 	R40,1,1
		IJNE 	R40,00H,Client_Password_error1
		IJNE 	R41,42H,Client_Password_error1;密码为066
		LDBR 	R44,14H,1;
		MOVRD 	R44,04H,1;密码正确切到第19页-工厂参数
		
		LDWR 	R40,0000H		
		LDWR 	R0,340AH;密码清零	
		MOVXR	R40,0,1
		GOTO    Factory_Password_RET
		
   Client_Password_error1:				 	
		IJNE 	R40,00H,Setting_Password_error1
		IJNE 	R41,16H,Setting_Password_error1;密码为022
		LDBR    R44,13H,1
		MOVRD   R44,04H,1
		
		LDWR 	R40,0000H		
		LDWR 	R0,340AH;密码清零	
		MOVXR	R40,0,1
		GOTO    Factory_Password_RET		
		
   Setting_Password_error1:				 	
		IJNE 	R40,03H,Run_Password_error1
		IJNE 	R41,57H,Run_Password_error1;密码为855
		LDBR    R44,58H,1
		MOVRD   R44,04H,1
		
		LDWR 	R40,0000H		
		LDWR 	R0,340AH;密码清零	
		MOVXR	R40,0,1
		GOTO    Factory_Password_RET
    
    Run_Password_error1:
		LDWR 	R0,3102H;转换过后的机组已运行时间
		MOVXR 	R36,1,1;将07D4H已运行时间传给R36到R37。		
		CALL	Password_calculate;
		LDWR	R0,3104H
		MOVXR	R66,0,1

		CJNE 	R40,R66,Password_error1;寄存器之间的比较用cjne指令
		CJNE 	R41,R67,Password_error1;		
		LDBR 	R44,11,1
		MOVRD 	R44,04H,1;密码正确切到11画面-             运行时间设定
		LDWR 	R30,0
		LDWR 	R0,340AH;密码地址清零
		MOVXR 	R30,0,1      
		GOTO    Factory_Password_RET
	    
   Password_error1:	
		;IJNE 	R41,0,1		
		IJNE 	R41,0,realy_erro
		LDBR	R50,0,2	;读输入状态,
		LDBR	R50,0CH,1
		MOVRD	R50,04H,1;跳转到第6页
		MOVDR 	E9H,R51,1
		IJNE	R51,0,Factory_Password_RET;如果光标闪烁，那么不跳转，如果光标不闪烁，那么就跳转
		LDBR	R36,02H,1
		MOVRD	R36,4FH,1;
		GOTO 	Factory_Password_RET;密码为0没反应  
		
       realy_erro:
		LDBR	R30,01,1 
		MOVRD 	R30,4FH,1
		
		LDBR 	R44,0FH,1 
		MOVRD 	R44,04H,1;跳到密码错误界面
		LDWR 	R40,0000H	
		LDWR 	R0,340AH;密码地址清零
		MOVXR 	R40,0,1	
		GOTO    Factory_Password_RET
   
  Factory_Password_RET: 
        RET 
 
  ;此函数输入为R36:R37（运行时间），输出为R66:R67(密码)        
 Password_calculate:;计算运行时间的密码[(1303+(运行时间/10))*3^（运行时间%10）]%10000	   			
		
		LDBR 	R30,0,6;运行时间R34：R35：R36：R37
		LDBR	R90,0,6
		LDWR	R96,000AH
		DIV		R30,R90,0;得到的商(即运行时间/10)放到R30~R37,得到的余数(即运行时间%10)放到R96：R97			
		
		LDBR	R48,0,2;
		LDWR	R50,0517H;1303		
		LDBR	R52,0,8		
		ADD		R34,R48,R52;1303+(运行时间/10)得到的和放在R56:R57:R58:R59	
		
		LDWR	R100,0001H
		LDBR	R80,0,6
		LDWR	R86,1;R84/R85/R86/R87
	
		LOOP_FOR_3_n:;要写循环语句求幂3^n了，n代表（运行时间%10）			
		JS		R96,R100,LOOP_FOR_3_n_END
		
		LDBR	R110,0,8
		LDBR	R74,0,2
		LDWR	R76,3				
		MAC		R84,R74,R110;得到3^n的结果放在R80~R87;R84:R85:R86:R87的值继续拿出来做下一次乘法				
		MOV		R114,R84,4;R110作为中间寄存器，是因为MAC做的是A*B+C的运算，因此每次必须把C赋值为0，乘法得到的结果又要传递给A用于下一次的计算		
		
		INC		R100,0001H,1
		GOTO	LOOP_FOR_3_n

		LOOP_FOR_3_n_END:			
		LDBR	R90,0,8
		MAC		R56,R84,R90;(1303+(运行时间/10))*3^n得到的积放到R90~R98
			
		LDBR	R60,0,6
		LDWR	R66,10000		
		DIV		R90,R60,0;得到余数(个十百千位)作为密码，放到R66,R67	

 Password_calculate_RET:
 	RET

 Runtime_conversion:;将运行的小时数转化为天数。将设置的天数转化成小时传给主板。
 ;将运行的小时数转化为天数。	
 	LDBR	R50,0,6
 	LDWR	R0,07DEH
 	MOVXR	R56,1,1	
 	LDBR	R60,0,6
 	LDWR	R66,24	
 	DIV		R50,R60,0;商放在R56:R57
 	LDWR	R0,3102H;运行天数
 	MOVXR	R56,0,1
 	
 Runtime_conversion_RET:
 	RET
 
  Clock_DISPLAY:
 
    MOVDR 	20H,R100,7;获取当前时间- 年 月 日 星期 时 分  秒
	MOV 	R104,R103,1;因为TIME只计算年月日时分秒，所以要把星期滤掉
	MOV 	R105,R104,1
	MOV 	R106,R105,1;年、月、日、时、分、秒
	
	LDWR	R36,0000H
	MOV		R100,R37,1
	CALL	HEX_TO_DEC
	LDWR	R0,0BC9H
	MOVXR	R36,0,1
	
	LDWR	R36,0000H
	MOV		R101,R37,1
	CALL	HEX_TO_DEC
	LDWR	R0,0BCAH
	MOVXR	R36,0,1
	
	LDWR	R36,0000H
	MOV		R102,R37,1
	CALL	HEX_TO_DEC
	LDWR	R0,0BCBH
	MOVXR	R36,0,1	
	
	LDWR	R36,0000H
	MOV		R103,R37,1
	CALL	HEX_TO_DEC
	LDWR	R0,0BCCH
	MOVXR	R36,0,1	
	
	LDWR	R36,0000H
	MOV		R104,R37,1
	CALL	HEX_TO_DEC
	LDWR	R0,0BCDH
	MOVXR	R36,0,1	
	
 Clock_DISPLAY_RET:
        RET
        
HEX_TO_DEC:
 	;16进制先除以16
	LDBR	R30,0,6;R30~R37为被除数
	LDBR	R40,0,6
	LDWR	R46,16;R40~R47为除数
	DIV		R30,R40,0;商R36：R37     余数R46:R47
	
	;再乘法，拿商乘以10
	LDWR	R56,10
	LDBR	R60,0,8
	MAC		R34,R54,R60;积R66:R67	
	;再加法，将商乘以10后的积加上先前得到的余数,得到10进制
	LDBR	R30,0,8
	ADD		R64,R44,R30;和R36:R37
 	
 HEX_TO_DEC_RET:
 RET
	  
  READ:
     CALL Machine_Status; 开关机、模式
 	 
; 	 LDWR	R0,0BC3H;标志位清零了之后才能继续置1
; 	 MOVXR	R30,1,1
; 	 LDWR	R32,8006H
; 	 AND	R32,R30,2
; 	 LDWR	R30,0000H
; 	 JS		R30,R32,READ_RET
 	 
 	 CALL READ1_A;   A类参数
 	 CALL READ1_D;
     CALL READ1_E;
     CALL READ1_F;
 	 CALL READ1_H;
	 CALL READ1_R;
	 CALL READ1_P;
	 CALL READ1_U;
  READ_RET:
     RET
 
  Machine_Status:
  ;;;;;;;;;;;;
  ;;;jh   2016.12.23 
  ;;;;;;;;;;;;;
  LDWR	R0,07DBH	;开关机状态
  MOVXR	R30,1,1
  LDWR	R0,06A0H	;开关机状态中间变量
  MOVXR	R32,1,1
  	CJNE	R30,R32,Machine_Power_State_Change
  	CJNE    R31,R33,Machine_Power_State_Change;
  		GOTO    Machine_Mod_if_change
  	Machine_Power_State_Change:
  	LDWR	R0,03F3H	;开关机按键与主板实际开关机状态同步
  	LDWR  R0,0BE9H
    MOVXR  R30,0,1
   	LDWR  R0,06A0H
    MOVXR  R30,0,1
 ;判断当前是主机模式还是从机模式，如果是从机模式，则模式跟随模式开关的状态
  Machine_Mod_if_change:
  LDWR  R0,0402H
  MOVXR  R30,1,1
  IJNE  R31,1,Machine_Power_Handle	
  ;如果是从机，则与模式与模式开关同步
      LDWR  R0,07F7H
	  MOVXR  R36,1,1
	  LDWR  R34,0400H;模式开关
      AND  R34,R36,2  
      IJNE  R34,04H,6
   ;模式开关断开
  LDWR  R0,03F4H;模式
  LDWR  R30,0;制冷
  MOVXR  R30,0,1
  LDWR  R0,0BEAH;模式中间
  MOVXR  R30,0,1
  GOTO  Machine_Power_Handle   
   ;模式开关闭合
  LDWR  R0,03F4H;模式
  LDWR  R30,1;制热
  MOVXR  R30,0,1
  LDWR  R0,0BEAH;模式中间
  MOVXR  R30,0,1
  GOTO  Machine_Power_Handle    
  
  Machine_Power_Handle:
  ;;;;;;;;;;;;;;
  Machine_Power:
     LDWR  R0,03F3H;读取开关机状态值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0BE9H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,Machine_Power_RET;++
  	 CJNE  R31,R33,Machine_Power_RET;++
  	 GOTO  Machine_Mode;++  	
  Machine_Power_RET:;++ 
  ;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;jh 2016.12.23 
   LDWR  R0,07F7H
   MOVXR  R36,1,1
   LDWR  R34,0200H;应急开关
   AND  R34,R36,2
   IJNE  R34,02H,4
   IJNE  R31,1,3
   LDWR  R0,03F3H
   MOVXR  R32,0,1
   GOTO  Machine_Mode
  ;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;
  	 LDWR	R0,0BC3H
	 MOVXR	R32,1,1
	 LDWR	R34,0002H
	 AND	R34,R32,2
	 IJNE	R35,00H,8

  	 LDWR  R0,0BE9H;++
	 MOVXR R30,0,1

	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
	 OR    R30,R32,2; 0BC3的第1位为1，则A参数发生变化
	 MOVXR R30,0,1
	 GOTO	Machine_Mode
	 
;	 LDWR	R0,0A00H
;	 MOVXR	R30,1,1
;	 LDWR	R0,03F3H
;	 MOVXR	R30,0,1
	 
  Machine_Mode:
     LDWR  R0,03F4H;读取模式状态值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0BEAH;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,Machine_Mode_RET;++
  	 CJNE  R31,R33,Machine_Mode_RET;++
  	 GOTO  Machine_off;++  	
  Machine_Mode_RET:;++
  	 LDWR	R0,0BC3H
	 MOVXR	R32,1,1
	 LDWR	R34,0002H
	 AND	R34,R32,2
	 IJNE	R35,00H,8
  	
  	 LDWR  R0,0BEAH;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
	 OR    R30,R32,2; 0BC3的第1位为1，则A参数发生变化
	 MOVXR R30,0,1 
	 GOTO	Machine_off
	 
;	 LDWR	R0,0A01H
;	 MOVXR	R30,1,1
;	 LDWR	R0,03F4H
;	 MOVXR	R30,0,1
  Machine_off:
     RET
     
  READ1_A:
  READ1_A3:
  	 LDWR  R0,0414H;读取A-03值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C0AH;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_A3_RET;++
  	 CJNE  R31,R33,READ1_A3_RET;++
  	 GOTO  READ1_A4;++  	
  READ1_A3_RET:;++
  	 LDWR  R0,0C0AH;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
	 OR    R30,R32,2;  0BC3的第1位为1，则A参数发生变化
	 MOVXR R30,0,1 
	
  READ1_A4:
     LDWR  R0,0415H;读取A-04值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C0BH;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_A4_RET;++
  	 CJNE  R31,R33,READ1_A4_RET;++
  	 GOTO  READ1_A5;++
  READ1_A4_RET:
     LDWR  R0,0C0BH;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
	 OR    R30,R32,2;  0BC3的第1位为1，则A参数发生变化
	 MOVXR R30,0,1
		 
  READ1_A5:
     LDWR  R0,0416H;读取A-05值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C0CH;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_A5_RET;++
  	 CJNE  R31,R33,READ1_A5_RET;++
  	 GOTO  READ1_A6;++
  READ1_A5_RET:
     LDWR  R0,0C0CH;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
	 OR    R30,R32,2;  0BC3的第1位为1，则A参数发生变化
	 MOVXR R30,0,1
	
  READ1_A6: 
     LDWR  R0,0417H;读取A-06值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C0DH;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_A6_RET;++
  	 CJNE  R31,R33,READ1_A6_RET;++
  	 GOTO  READ1_A10;++
  READ1_A6_RET:
     LDWR  R0,0C0DH;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
	 OR    R30,R32,2; 0BC3的第1位为1，则A参数发生变化
	 MOVXR R30,0,1
	 
  READ1_A10: 
     LDWR  R0,0418H;读取A-10值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C0EH;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_A10_RET;++
  	 CJNE  R31,R33,READ1_A10_RET;++
  	 GOTO  READ1_A11;++
  READ1_A10_RET:
     LDWR  R0,0C0EH;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
	 OR    R30,R32,2; 0BC3的第1位为1，则A参数发生变化
	 MOVXR R30,0,1
	
  READ1_A11: 
     LDWR  R0,0419H;读取A-11值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C0FH;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_A11_RET;++
  	 CJNE  R31,R33,READ1_A11_RET;++
  	 GOTO  READ1_A12;++
  READ1_A11_RET:
     LDWR  R0,0C0FH;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
	 OR    R30,R32,2;  0BC3的第1位为1，则A参数发生变化
	 MOVXR R30,0,1
	
  READ1_A12:
     LDWR  R0,041AH;读取A-12值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C10H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_A12_RET;++ 
  	 CJNE  R31,R33,READ1_A12_RET;++
  	 GOTO  READ1_A13;++
  READ1_A12_RET: 
 
	    LDWR	R0,041BH;    A13 
	   	MOVXR	R40,1,1
	   	LDWR	R0,041AH;    A12
	   	MOVXR	R30,1,1
	   	JS		R40,R30,1;
	    MOV		R40,R30,2
	   	MOVXR	R30,0,1
	 
	 LDWR  R0,0C10H;++
	 MOVXR R30,0,1
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
	 OR    R30,R32,2;  0BC3的第1位为1，则A参数发生变化
	 MOVXR R30,0,1
	 
  READ1_A13:
     LDWR  R0,041BH;读取A-12值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C11H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_A13_RET;++
  	 CJNE  R31,R33,READ1_A13_RET;++
  	 GOTO  READ1_A18;++
  READ1_A13_RET: 

 
	    LDWR	R0,041AH;    A12 
	   	MOVXR	R40,1,1
	   	LDWR	R0,041BH;    A13
	   	MOVXR	R30,1,1
	   	JS		R30,R40,1;
	    MOV		R40,R30,2
	   	MOVXR	R30,0,1 
	   	
	 LDWR  R0,0C11H;++
	 MOVXR R30,0,1
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
	 OR    R30,R32,2;  0BC3的第1位为1，则A参数发生变化
	 MOVXR R30,0,1
	 
;  READ1_A14:
;     LDWR  R0,041CH;读取A-12值++
; 	 MOVXR R30,1,1;传给R30
;  	 LDWR  R0,0C12H;公共寄存器++
;  	 MOVXR R32,1,1;传给R32
;  	 CJNE  R30,R32,READ1_A14_RET;++
;  	 CJNE  R31,R33,READ1_A14_RET;++
;  	 GOTO  READ1_A15;++
;  READ1_A14_RET: 
;     LDWR  R0,0C12H;++
;	 MOVXR R30,0,1
;	 
;	 LDWR  R0,0BC3H
;	 MOVXR R30,1,1
;	 LDWR  R32,0002H;
;	 OR    R30,R32,2;  0BC3的第1位为1，则A参数发生变化
;	 MOVXR R30,0,1
;	
;  READ1_A15: 
;     LDWR  R0,041DH;读取A-12值++
; 	 MOVXR R30,1,1;传给R30
;  	 LDWR  R0,0C13H;公共寄存器++
;  	 MOVXR R32,1,1;传给R32
;  	 CJNE  R30,R32,READ1_A15_RET;++
;  	 CJNE  R31,R33,READ1_A15_RET;++
;  	 GOTO  READ1_A16;++
;  READ1_A15_RET:
;	 LDWR  R0,0C13H;++
;	 MOVXR R30,0,1
;	 
;	 LDWR  R0,0BC3H
;	 MOVXR R30,1,1
;	 LDWR  R32,0002H;
;	 OR    R30,R32,2;  0BC3的第1位为1，则A参数发生变化
;	 MOVXR R30,0,1
;	
;  READ1_A16: 
;     LDWR  R0,041EH;读取A-12值++
; 	 MOVXR R30,1,1;传给R30
;  	 LDWR  R0,0C14H;公共寄存器++
;  	 MOVXR R32,1,1;传给R32
;  	 CJNE  R30,R32,READ1_A16_RET;++
;  	 CJNE  R31,R33,READ1_A16_RET;++
;  	 GOTO  READ1_A17;++
;  READ1_A16_RET:
;	 LDWR  R0,0C14;++
;	 MOVXR R30,0,1
;	 
;	 LDWR  R0,0BC3H
;	 MOVXR R30,1,1
;	 LDWR  R32,0002H;
;	 OR    R30,R32,2;  0BC3的第1位为1，则A参数发生变化
;	 MOVXR R30,0,1
;	 
;  READ1_A17: 
;     LDWR  R0,041FH;读取A-12值++
; 	 MOVXR R30,1,1;传给R30
;  	 LDWR  R0,0C15H;公共寄存器++
;  	 MOVXR R32,1,1;传给R32
;  	 CJNE  R30,R32,READ1_A17_RET;++
;  	 CJNE  R31,R33,READ1_A17_RET;++
;  	 GOTO  READ1_A18;++
;  READ1_A17_RET:
;	 LDWR  R0,0C15H;++
;	 MOVXR R30,0,1
;	 
;	 LDWR  R0,0BC3H
;	 MOVXR R30,1,1
;	 LDWR  R32,0002H;
;	 OR    R30,R32,2;  0BC3的第1位为1，则A参数发生变化
;	 MOVXR R30,0,1
     
 READ1_A18:;               **********01-11 wxm
     LDWR  R0,0420H;读取A-12值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C16H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_A18_RET;++
  	 CJNE  R31,R33,READ1_A18_RET;++
  	 GOTO  READ1_A19;++
  READ1_A18_RET:
	 LDWR  R0,0C16H;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
	 OR    R30,R32,2;  0BC3的第1位为1，则参数发生变化
	 MOVXR R30,0,1
     
 READ1_A19: 
	 RET
	 
  READ1_D:
  
  READ1_D1:
	 LDWR  R0,045CH;读取D-1值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C48H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_D1_RET;++
  	 CJNE  R31,R33,READ1_D1_RET;++
  	 GOTO  READ1_D1YA;++
  READ1_D1_RET:
     LDWR  R0,0C48H;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第1位为1，则参数发生变化
	 MOVXR R30,0,1
     
  READ1_D1YA:           ;D01压力值显示
	 LDWR  R0,045DH;读取D-1值++ （ D1压力值）
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C49H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_D1YA_RET;++
  	 CJNE  R31,R33,READ1_D1YA_RET;++
  	 GOTO  READ1_D2;++
  READ1_D1YA_RET:
     LDWR  R0,0C49H;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第1位为1，则参数发生变化
	 MOVXR R30,0,1
  
  READ1_D2:
	 LDWR  R0,045EH;读取D-2值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C4AH;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_D2_RET;++
  	 CJNE  R31,R33,READ1_D2_RET;++
  	 GOTO  READ1_D3;++
  READ1_D2_RET:
     LDWR  R0,0C4AH;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第1位为1，则参数发生变化
	 MOVXR R30,0,1
	 
  READ1_D3:
	 LDWR  R0,045FH;读取D-3值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0CABH;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_D3_RET;++
  	 CJNE  R31,R33,READ1_D3_RET;++
  	 GOTO  READ1_D4;++
  READ1_D3_RET:
     LDWR  R0,0CABH;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第1位为1，则参数发生变化
	 MOVXR R30,0,1 
	 
  READ1_D4:
	 LDWR  R0,0460H;读取D-4值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C4CH;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_D4_RET;++
  	 CJNE  R31,R33,READ1_D4_RET;++
  	 GOTO  READ1_D6;++
  READ1_D4_RET:
     LDWR  R0,0C4CH;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2; 0BC3的第1位为1，则参数发生变化
	 MOVXR R30,0,1
	
  READ1_D6:
	 LDWR  R0,0461H;读取D-6值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C4DH;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_D6_RET;++
  	 CJNE  R31,R33,READ1_D6_RET;++
  	 GOTO  READ1_D7;++
  READ1_D6_RET:
     LDWR  R0,0C4DH;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
  
  READ1_D7:
	 LDWR  R0,0462H;读取D-7值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C4EH;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_D7_RET;++
  	 CJNE  R31,R33,READ1_D7_RET;++
  	 GOTO  READ1_D8;++
  READ1_D7_RET:
     LDWR  R0,0C4EH;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
	
  READ1_D8:
	 LDWR  R0,0463H;读取D-8值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C4FH;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_D8_RET;++
  	 CJNE  R31,R33,READ1_D8_RET;++
  	 GOTO  READ1_D9;++
  READ1_D8_RET:
     LDWR  R0,0C4FH;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
	
  READ1_D9:
	 LDWR  R0,0464H;读取D-9值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C50H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_D9_RET;++
  	 CJNE  R31,R33,READ1_D9_RET;++
  	 GOTO  READ1_D10;++
  READ1_D9_RET:
     LDWR  R0,0C50H;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
 
  READ1_D10:
	 LDWR  R0,0465H;读取D-10值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C51H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_D10_RET;++
  	 CJNE  R31,R33,READ1_D10_RET;++
  	 GOTO  READ1_D10YA;++
  READ1_D10_RET:
     LDWR  R0,0C51H;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1

  READ1_D10YA:     ;显示D10压力值
	 LDWR  R0,0466H;读取D-10值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C52H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_D10YA_RET;++
  	 CJNE  R31,R33,READ1_D10YA_RET;++
  	 GOTO  READ1_D11;++
  READ1_D10YA_RET:
     LDWR  R0,0C52H;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
	 	 
  READ1_D11: 
  	 LDWR  R0,0467H;读取D-11值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C53H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_D11_RET;++
  	 CJNE  R31,R33,READ1_D11_RET;++
  	 GOTO  READ1_D11YA;++
  READ1_D11_RET:
     LDWR  R0,0C53H;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
	 
 READ1_D11YA:     ;显示D11压力值
	 LDWR  R0,0468H;读取D-11值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C54H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_D11YA_RET;++
  	 CJNE  R31,R33,READ1_D11YA_RET;++
  	 GOTO  READ1_D12;++
  READ1_D11YA_RET:
     LDWR  R0,0C54H;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1	 
	 
  READ1_D12:	 
     RET
 
  READ1_E:     ;E类参数
  READ1_E1:
     LDWR  R0,0473H;读取E-1值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C5FH;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E1_RET;++
  	 CJNE  R31,R33,READ1_E1_RET;++
  	 GOTO  READ1_E3;++
  READ1_E1_RET:
     LDWR  R0,0C5FH;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
	 
  READ1_E3:
     LDWR  R0,0474H;读取E-3值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C60H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E3_RET;++
  	 CJNE  R31,R33,READ1_E3_RET;++
  	 GOTO  READ1_E7;++
  READ1_E3_RET:
     LDWR  R0,0C60H;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1	 
	
  READ1_E7:
     LDWR  R0,0475H;读取E-7值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C61H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E7_RET;++
  	 CJNE  R31,R33,READ1_E7_RET;++
  	 GOTO  READ1_E8;++
  READ1_E7_RET:
     LDWR  R0,0C61H;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
		 
  READ1_E8:
	 LDWR  R0,0476H;读取E-8值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C62H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E8_RET;++
  	 CJNE  R31,R33,READ1_E8_RET;++
  	 GOTO  READ1_E13;++
  READ1_E8_RET:
     LDWR  R0,0C62H;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
  
;  READ1_E12:
;	 LDWR  R0,0477H;读取E-12值++
; 	 MOVXR R30,1,1;传给R30
;  	 LDWR  R0,0C63H;公共寄存器++
;  	 MOVXR R32,1,1;传给R32
;  	 CJNE  R30,R32,READ1_E12_RET;++
;  	 CJNE  R31,R33,READ1_E12_RET;++
;  	 GOTO  READ1_E13;++
;  READ1_E12_RET:
;     LDWR  R0,0C63H;++
;	 MOVXR R30,0,1
;	 
;	 LDWR  R0,0BC3H
;	 MOVXR R30,1,1
;	 LDWR  R32,0004H;
;	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
;	 MOVXR R30,0,1
	 
  READ1_E13:
	 LDWR  R0,0477H;读取E-13值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C63H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E13_RET;++
  	 CJNE  R31,R33,READ1_E13_RET;++
  	 GOTO  READ1_E14;++
  READ1_E13_RET:
     LDWR  R0,0C63H;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1 
	 	 
  READ1_E14:
	 LDWR  R0,0478H;读取E-14值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C64H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E14_RET;++
  	 CJNE  R31,R33,READ1_E14_RET;++
  	 GOTO  READ1_E15;++
  READ1_E14_RET:
     LDWR  R0,0C64H;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
	 
  READ1_E15:
	 LDWR  R0,0479H;读取E-15值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C65H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E15_RET;++
  	 CJNE  R31,R33,READ1_E15_RET;++
  	 GOTO  READ1_E16;++
  READ1_E15_RET:
     LDWR  R0,0C65H;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
	 
  READ1_E16:
	 LDWR  R0,047AH;读取E-16值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C66H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E16_RET;++
  	 CJNE  R31,R33,READ1_E16_RET;++
  	 GOTO  READ1_E17;++
  READ1_E16_RET:
 
	    LDWR	R0,047BH; E17
	   	MOVXR	R40,1,1
	   	LDWR	R0,047AH; E16
	   	MOVXR	R30,1,1
	   	JS		R30,R40,1;
	   	MOV		R40,R30,2
	   	MOVXR	R30,0,1
	   	
     LDWR  R0,0C66H;++
	 MOVXR R30,0,1	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1 
	 
  READ1_E17:
	 LDWR  R0,047BH;读取E-17值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C67H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E17_RET;++
  	 CJNE  R31,R33,READ1_E17_RET;++
  	 GOTO  READ1_E18;++
  READ1_E17_RET:
	 
	    LDWR	R0,047AH; E16
	   	MOVXR	R40,1,1
	   	LDWR	R0,047BH; E17
	   	MOVXR	R30,1,1
	   	JS		R40,R30,1;
	   	MOV		R40,R30,2
	   	MOVXR	R30,0,1
	   	
	 LDWR  R0,0C67H;++
	 MOVXR R30,0,1
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
	 
  READ1_E18:
	 LDWR  R0,047CH;读取E-18值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C68H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E18_RET;++
  	 CJNE  R31,R33,READ1_E18_RET;++
  	 GOTO  READ1_E19;++
  READ1_E18_RET:
     LDWR  R0,0C68H;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
	 
  READ1_E19:
	 LDWR  R0,047DH;读取E-19值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C69H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E19_RET;++
  	 CJNE  R31,R33,READ1_E19_RET;++
  	 GOTO  READ1_E20;++
  READ1_E19_RET:
     LDWR  R0,0C69H;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
	 
  READ1_E20:
	 LDWR  R0,047EH;读取E-20值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C6AH;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E20_RET;++
  	 CJNE  R31,R33,READ1_E20_RET;++
  	 GOTO  READ1_E21;++
  READ1_E20_RET:
     LDWR  R0,0C6AH;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1 
	 
  READ1_E21:
	 LDWR  R0,047FH;读取E-21值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C6BH;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E21_RET;++
  	 CJNE  R31,R33,READ1_E21_RET;++
  	 GOTO  READ1_E22;++
  READ1_E21_RET:
     LDWR  R0,0C6BH;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1 
	 	
  READ1_E22:
	 LDWR  R0,0480H;读取E-22值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C6CH;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E22_RET;++
  	 CJNE  R31,R33,READ1_E22_RET;++
  	 GOTO  READ1_E23;++
  READ1_E22_RET:
     LDWR  R0,0C6CH;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
	 
  READ1_E23:   
	 LDWR  R0,0481H;读取E-23值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C6DH;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E23_RET;++
  	 CJNE  R31,R33,READ1_E23_RET;++
  	 GOTO  READ1_E24;++
  READ1_E23_RET:
  	 LDWR  R46,01F4H ;500N  lsz.12.9添加
  	 JS	   R46,R30,maxE23
     LDWR  R0,0C6DH;++
	 MOVXR R30,0,1
  maxE23:
     
;	 LDWR  R0,0BC3H
;	 MOVXR R50,1,1
;	 LDWR  R32,0004H;
;	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
;	 MOVXR R30,0,1	
;	LDBR	R40,10H,1
;	MOVRD	R40,02H,1
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
	 
  READ1_E24:
	 LDWR  R0,0482H;读取E-22值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C6EH;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E24_RET;++
  	 CJNE  R31,R33,READ1_E24_RET;++
  	 GOTO  READ1_E25;++
  READ1_E24_RET:
     LDWR  R0,0C6EH;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
	 
  READ1_E25:
	 LDWR  R0,0483H;读取E-22值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C6FH;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E25_RET;++
  	 CJNE  R31,R33,READ1_E25_RET;++
  	 GOTO  READ1_E26;++
  READ1_E25_RET:
     LDWR  R0,0C6FH;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
	
  READ1_E26:
	 LDWR  R0,0484H;读取E-22值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C70H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E26_RET;++
  	 CJNE  R31,R33,READ1_E26_RET;++
  	 GOTO  READ1_E27;++
  READ1_E26_RET:
     LDWR  R0,0C70H;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
	
  READ1_E27:
	 LDWR  R0,0485H;读取E-22值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C71H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E27_RET;++
  	 CJNE  R31,R33,READ1_E27_RET;++
  	 GOTO  READ1_E28;++
  READ1_E27_RET:
     LDWR  R0,0C71H;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
	
  READ1_E28:
	 LDWR  R0,0486H;读取E-22值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C72H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E28_RET;++
  	 CJNE  R31,R33,READ1_E28_RET;++
  	 GOTO  READ1_E29;++
  READ1_E28_RET:
     LDWR  R0,0C72H;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
	 
  READ1_E29:
	 LDWR  R0,0487H;读取E-22值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C73H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E29_RET;++
  	 CJNE  R31,R33,READ1_E29_RET;++
  	 GOTO  READ1_E30;++
  READ1_E29_RET:
     LDWR  R0,0C73H;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
		
  READ1_E30:
	 LDWR  R0,0488H;读取E-22值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C74H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E30_RET;++
  	 CJNE  R31,R33,READ1_E30_RET;++
  	 GOTO  READ1_E31;++
  READ1_E30_RET:
     LDWR  R0,0C74H;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
 
  READ1_E31:
	 LDWR  R0,0489H;读取E-22值++
 	 MOVXR R30,1,1;传给R30
  	 LDWR  R0,0C75H;公共寄存器++
  	 MOVXR R32,1,1;传给R32
  	 CJNE  R30,R32,READ1_E31_RET;++
  	 CJNE  R31,R33,READ1_E31_RET;++
  	 GOTO  READ1_E32;++
  READ1_E31_RET:
     LDWR  R0,0C75H;++
	 MOVXR R30,0,1
	 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
	 OR    R30,R32,2;  0BC3的第2位为1，则参数发生变化
	 MOVXR R30,0,1
	 
	READ1_E32: 
     RET
  
  READ1_F:       ;F类参数
  READ1_F1:
     LDWR  R0,042DH;读取F-01值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C23H;公共寄存器++
     MOVXR R32,1,1H;传给R32
     CJNE  R30,R32,READ1_F1_RET
     CJNE  R31,R33,READ1_F1_RET
     GOTO  READ1_F2
  READ1_F1_RET:
     LDWR  R0,0C23H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
    
  READ1_F2:
     LDWR  R0,042EH;读取F-02值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C24H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F2_RET
     CJNE  R31,R33,READ1_F2_RET
     GOTO  READ1_F2YA
  READ1_F2_RET:
     LDWR  R0,0C24H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2 ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
       
  READ1_F2YA:   ; 显示F02压力值
     LDWR  R0,042FH;读取F-02 压力值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C25H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F2YA_RET;
     CJNE  R31,R33,READ1_F2YA_RET;++
     GOTO  READ1_F3
  READ1_F2YA_RET:
     LDWR  R0,0C25H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
  
  READ1_F3:
     LDWR  R0,0430H;读取F-03值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C26H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F3_RET;
     CJNE  R31,R33,READ1_F3_RET;++
     GOTO  READ1_F3YA
  READ1_F3_RET:
     LDWR  R0,0C26H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
    	 
  READ1_F3YA:
     LDWR  R0,0431H;读取F-04值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C27H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F3YA_RET;
     CJNE  R31,R33,READ1_F3YA_RET;++
     GOTO  READ1_F5
  READ1_F3YA_RET:
     LDWR  R0,0C27H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2 ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1 
     
;  READ1_F4:
;     LDWR  R0,041EH;读取F-04值++
;     MOVXR R30,1,1;传给R30
;     LDWR  R0,0A30H;公共寄存器++
;     MOVXR R32,1,1;传给R32
;     CJNE  R30,R32,READ1_F4_RET;
;     CJNE  R31,R33,READ1_F4_RET;++
;     GOTO  READ1_F4YA
;  READ1_F4_RET:
;     LDWR  R0,0A30H
;     MOVXR R30,0,1
;     
;     LDWR  R0,0BC3H
;	 MOVXR R30,1,1
;	 LDWR  R32,0002H;
;     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
;     MOVXR R30,0,1
;    
;  READ1_F4YA:
;     LDWR  R0,041FH;读取F-04压力值++
;     MOVXR R30,1,1;传给R30
;     LDWR  R0,0A31H;公共寄存器++
;     MOVXR R32,1,1;传给R32
;     CJNE  R30,R32,READ1_F4YA_RET;
;     CJNE  R31,R33,READ1_F4YA_RET;++
;     GOTO  READ1_F5
;   READ1_F4YA_RET:
;     LDWR  R0,0A31H
;     MOVXR R30,0,1
;     
;     LDWR  R0,0BC3H
;	 MOVXR R30,1,1
;	 LDWR  R32,0002H;
;     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
;     MOVXR R30,0,1 
     
  READ1_F5:
     LDWR  R0,0434H;读取F-05值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C2AH;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F5_RET;
     CJNE  R31,R33,READ1_F5_RET;++
     GOTO  READ1_F5YA
   READ1_F5_RET:
     LDWR  R0,0C2AH
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1 
     
  READ1_F5YA:
     LDWR  R0,0435H;读取F-05压力值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C2BH;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F5YA_RET;
     CJNE  R31,R33,READ1_F5YA_RET;++
     GOTO  READ1_F6
  READ1_F5YA_RET:
     LDWR  R0,0C2BH
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
    
  READ1_F6:
     LDWR  R0,0436H;读取F-06值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C2CH;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F6_RET;++
     CJNE  R31,R33,READ1_F6_RET;++
     GOTO  READ1_F6YA 
  READ1_F6_RET:
     LDWR  R0,0C2CH
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1 
     
  READ1_F6YA:
     LDWR  R0,0437H;读取F-06压力值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C2DH;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F6YA_RET;++
     CJNE  R31,R33,READ1_F6YA_RET;++
     GOTO  READ1_F11 
  READ1_F6YA_RET:
     LDWR  R0,0C2DH
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     
;  READ1_F7:
;     LDWR  R0,042EH;读取F-07值++
;     MOVXR R30,1,1;传给R30
;     LDWR  R0,0A36H;公共寄存器++
;     MOVXR R32,1,1;传给R32
;     CJNE  R30,R32,READ1_F7_RET;++
;     CJNE  R31,R33,READ1_F7_RET;++
;     GOTO  READ1_F8 ;    F7YA改成F8   01-13
;  READ1_F7_RET:
;     LDWR  R0,0A36H
;     MOVXR R30,0,1
;     
;     LDWR  R0,0BC3H
;	 MOVXR R30,1,1
;	 LDWR  R32,0002H;
;     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
;     MOVXR R30,0,1
;      
;  READ1_F7YA:    ;标志位跳变
;     LDWR  R0,042FH;读取F-07压力值++
;     MOVXR R30,1,1;传给R30
;     LDWR  R0,0A37H;公共寄存器++
;     MOVXR R32,1,1;传给R32
;     CJNE  R30,R32,READ1_F7YA_RET;++
;     CJNE  R31,R33,READ1_F7YA_RET;++
;     GOTO  READ1_F8 
;  READ1_F7YA_RET:
;     LDWR  R0,0A37H
;     MOVXR R30,0,1
     
;     LDWR  R0,0BC3H
;	 MOVXR R50,1,1
;	 LDWR  R32,0002H;       
;     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
;     MOVXR R30,0,1
   
;  READ1_F8:
;     LDWR  R0,0430H;读取F-08值++
;     MOVXR R30,1,1;传给R30
;     LDWR  R0,0A38H;公共寄存器++
;     MOVXR R32,1,1;传给R32
;     CJNE  R30,R32,READ1_F8_RET;++
;     CJNE  R31,R33,READ1_F8_RET;++
;     GOTO  READ1_F9 
;  READ1_F8_RET:
;     LDWR  R0,0A38H
;     MOVXR R30,0,1
;     
;     LDWR  R0,0BC3H
;	 MOVXR R30,1,1
;	 LDWR  R32,0002H   ;0BC3的第1位为1，则参数发生变化
;     OR    R30,R32,2
;     MOVXR R30,0,1  
;    
;     LDWR	R0,3800H
;     LDBR	R50,00H,48
;     MOVXR	R50,0,24;清空了静音定时图标显示变量     
;     CALL	MUTE_SET_CONTROL
;     
;  READ1_F9:
;     LDWR  R0,0431H;读取F-09值++
;     MOVXR R30,1,1;传给R30
;     LDWR  R0,0A39H;公共寄存器++
;     MOVXR R32,1,1;传给R32
;     CJNE  R30,R32,READ1_F9_RET;++  
;     CJNE  R31,R33,READ1_F9_RET;++
;     GOTO  READ1_F10 
;  READ1_F9_RET:
;     LDWR  R0,0A39H
;     MOVXR R30,0,1
;     
;     LDWR  R0,0BC3H
;	 MOVXR R30,1,1
;	 LDWR  R32,0002H   ;0BC3的第1位为1，则参数发生变化
;     OR    R30,R32,2
;     MOVXR R30,0,1  
;    
;     LDWR	R0,3800H
;     LDBR	R50,00H,48
;     MOVXR	R50,0,24;清空了静音定时图标显示变量
;     CALL	MUTE_SET_CONTROL
;     
;  READ1_F10:
;  	 LDWR	R0,03F1H
;  	 MOVXR	R30,1,1
;  	 IJNE	R31,1,3
;  	 LDWR	R0,0428H
;  	 LDWR	R32,0000H
;  	 MOVXR	R32,0,1
;  	 
;     LDWR  R0,0428H;读取F-10值++
;     MOVXR R30,1,1;传给R30
;     LDWR  R0,0A3AH;公共寄存器++
;     MOVXR R32,1,1;传给R32
;     CJNE  R30,R32,READ1_F10_RET;++
;     CJNE  R31,R33,READ1_F10_RET;++
;     GOTO  READ1_F11 
;  READ1_F10_RET:
;     LDWR  R0,0A3AH
;     MOVXR R30,0,1
;     
;     LDWR  R0,0BC3H
;	 MOVXR R30,1,1
;	 LDWR  R32,0002H;
;     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
;     MOVXR R30,0,1
    
  READ1_F11:
     LDWR  R0,043AH;读取F-11值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C30H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F11_RET;++
     CJNE  R31,R33,READ1_F11_RET;++
     GOTO  READ1_F15 
  READ1_F11_RET:
     LDWR  R0,0C30H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
    
  READ1_F15:
     LDWR  R0,043BH;读取F-15值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C31H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F15_RET;++
     CJNE  R31,R33,READ1_F15_RET;++
     GOTO  READ1_F15YA 
  READ1_F15_RET:
     LDWR  R0,0C31H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
    
  READ1_F15YA:
     LDWR  R0,043CH;读取F-15YA值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C32H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F15YA_RET;++
     CJNE  R31,R33,READ1_F15YA_RET;++
     GOTO  READ1_F16 
  READ1_F15YA_RET:
     LDWR  R0,0C32H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_F16:
     LDWR  R0,043DH;读取F-16值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C33H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F16_RET;++
     CJNE  R31,R33,READ1_F16_RET;++
     GOTO  READ1_F17 
  READ1_F16_RET:
     LDWR  R0,0C33H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_F17:
     LDWR  R0,043FH;读取F-17值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C35H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F17_RET;++
     CJNE  R31,R33,READ1_F17_RET;++
     GOTO  READ1_F17RATE 
  READ1_F17_RET:
      
 	 LDWR	R0,0441H; F18
	 MOVXR	R40,1,1
	 LDWR	R0,044DH; F19
	 MOVXR	R42,1,1
	 JS		R42,R40,1;
	 MOV	R42,R40,2   ;选择两个中最大的
     
     JS		R40,R30,1
	 MOV	R40,R30,2	;判断最高转速大于等于最低转速
	 
	 LDWR  R0,043FH
	 MOVXR R30,0,1
     LDWR  R0,0C35H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
    
  READ1_F17RATE:
     LDWR  R0,043EH;读取F-17占空比
     MOVXR R30,1,1;传给R30
     LDWR  R0,0A3FH;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F17RATE_RET;++
     CJNE  R31,R33,READ1_F17RATE_RET;++
     GOTO  READ1_F18 
  READ1_F17RATE_RET:
 	 LDWR	R0,0440H; F18
	 MOVXR	R40,1,1
	 LDWR	R0,0442H; F19
	 MOVXR	R42,1,1
	 JS		R42,R40,1;
	 MOV	R42,R40,2   ;选择两个中最大的
     
     JS		R40,R30,1
	 MOV	R40,R30,2	;判断最高转速大于等于最低转速
	 
	 LDWR  R0,043EH
	 MOVXR R30,0,1
     LDWR  R0,0A3FH
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_F18:
     LDWR  R0,0441H;读取F-18值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C37H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F18_RET;++
     CJNE  R31,R33,READ1_F18_RET;++
     GOTO  READ1_F18RATE 
  READ1_F18_RET:

	 LDWR	R0,043FH; F17
	 MOVXR	R40,1,1
	 JS		R30,R40,1;小于等于最高转速
	 MOV	R40,R30,2
	 
	 LDWR  R0,0441H
	 MOVXR R30,0,1
     LDWR  R0,0C37H
     MOVXR R30,0,1     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
;     
  READ1_F18RATE:
     LDWR  R0,0440H;读取F-18压力值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0A41H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F18RATE_RET;++
     CJNE  R31,R33,READ1_F18RATE_RET;++
     GOTO  READ1_F19 
  READ1_F18RATE_RET:

	 LDWR	R0,043EH; F17
	 MOVXR	R40,1,1
	 JS		R30,R40,1;小于等于最高转速
	 MOV	R40,R30,2
	 
	 LDWR  R0,0440H
	 MOVXR R30,0,1
     LDWR  R0,0A41H
     MOVXR R30,0,1     
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_F19:
     LDWR  R0,044DH;读取F-19值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C39H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F19_RET;++
     CJNE  R31,R33,READ1_F19_RET;++
     GOTO  READ1_F19RATE 
  READ1_F19_RET:
  	 LDWR	R0,043FH; F17
	 MOVXR	R40,1,1
	 JS		R30,R40,1;小于等于最高转速
	 MOV	R40,R30,2
	 
	 LDWR  R0,044DH
 	 MOVXR R30,0,1
     LDWR  R0,0C39H
     MOVXR R30,0,1
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
     OR    R30,R32,2 ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_F19RATE:
     LDWR  R0,0442H;读取F-19压力值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0A43H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F19RATE_RET;++
     CJNE  R31,R33,READ1_F19RATE_RET;++
     GOTO  READ1_F22 
  READ1_F19RATE_RET:
	 LDWR	R0,043EH; F17
	 MOVXR	R40,1,1
	 JS		R30,R40,1;小于等于最高转速
	 MOV	R40,R30,2
	 
	 LDWR  R0,0442H
	 MOVXR R30,0,1
     LDWR  R0,0A43H
     MOVXR R30,0,1     
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     
;  READ1_F20:
;     LDWR  R0,043CH;读取F-20值++
;     MOVXR R30,1,1;传给R30
;     LDWR  R0,0A44H;公共寄存器++
;     MOVXR R32,1,1;传给R32
;     CJNE  R30,R32,READ1_F20_RET;++
;     CJNE  R31,R33,READ1_F20_RET;++
;     GOTO  READ1_F20YA 
;  READ1_F20_RET:
;     LDWR  R0,0A44H
;     MOVXR R30,0,1
;     
;     LDWR  R0,0BC3H
;	 MOVXR R30,1,1
;	 LDWR  R32,0002H;
;     OR    R30,R32,2 ;0BC3的第1位为1，则参数发生变化
;     MOVXR R30,0,1
;     
;  READ1_F20YA:
;     LDWR  R0,043DH;读取F-20压力值++
;     MOVXR R30,1,1;传给R30
;     LDWR  R0,0A45H;公共寄存器++
;     MOVXR R32,1,1;传给R32
;     CJNE  R30,R32,READ1_F20YA_RET;++
;     CJNE  R31,R33,READ1_F20YA_RET;++
;     GOTO  READ1_F21 
;  READ1_F20YA_RET:
;     LDWR  R0,0A45H
;     MOVXR R30,0,1
;     
;     LDWR  R0,0BC3H
;	 MOVXR R30,1,1
;	 LDWR  R32,0002H;
;     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
;     MOVXR R30,0,1 
;     
;  READ1_F21:
;     LDWR  R0,0434H;读取F-21值++
;     MOVXR R30,1,1;传给R30
;     LDWR  R0,0A46H;公共寄存器++
;     MOVXR R32,1,1;传给R32
;     CJNE  R30,R32,READ1_F21_RET;++
;     CJNE  R31,R33,READ1_F21_RET;++
;     GOTO  READ1_F22 
;  READ1_F21_RET:
;     LDWR  R0,0A46H
;     MOVXR R30,0,1
;     
;     LDWR  R0,0BC3H
;	 MOVXR R30,1,1
;	 LDWR  R32,0002H;
;     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
;     MOVXR R30,0,1
     
  READ1_F22:
     LDWR  R0,044EH;读取F-22值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C3AH;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F22_RET;++
     CJNE  R31,R33,READ1_F22_RET;++
     GOTO  READ1_F23
  READ1_F22_RET:
     LDWR  R0,0C3AH
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_F23:
     LDWR  R0,0450H;读取F-23值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C3CH;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F23_RET;++
     CJNE  R31,R33,READ1_F23_RET;++
     GOTO  READ1_F24 
  READ1_F23_RET:
     LDWR  R0,0C3CH
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_F24:
     LDWR  R0,0451H;读取F-24++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C3DH;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F24_RET;++
     CJNE  R31,R33,READ1_F24_RET;++
     GOTO  READ1_F23RATE 
  READ1_F24_RET:
     LDWR  R0,0C3DH
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_F23RATE:
     LDWR  R0,044FH;读取F-23占空比值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0A6CH;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F24RATE_RET;++
     CJNE  R31,R33,READ1_F24RATE_RET;++
     GOTO  READ1_F25 
  READ1_F24RATE_RET:
     LDWR  R0,0A6CH
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1

  
  READ1_F25: ;
     LDWR  R0,0452H;读取F-25++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0A6DH;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F25_RET;++
     CJNE  R31,R33,READ1_F25_RET;++
     GOTO  READ1_F26 
  READ1_F25_RET:
     LDWR  R0,0A6DH
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     

  
  READ1_F26: 
     LDWR  R0,0453H;读取F-26++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0A6EH;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F26_RET;++
     CJNE  R31,R33,READ1_F26_RET;++
     GOTO  READ1_F27 
  READ1_F26_RET:
     LDWR  R0,0A6EH
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     
   READ1_F27:    
     LDWR  R0,0454H;读取F-27++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0A6FH;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F27_RET;++
     CJNE  R31,R33,READ1_F27_RET;++
     GOTO  READ_END 
  READ1_F27_RET:
     LDWR  R0,0A6FH
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1  
  
     GOTO	READ_END  
  
  READ1_F28:   ;预留
     LDWR  R0,0455H;读取F-28++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0A70H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_F28_RET;++
     CJNE  R31,R33,READ1_F28_RET;++
     GOTO  READ_END 
  READ1_F28_RET:
     LDWR  R0,0A70H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1   
   READ_END:
     RET
     
  READ1_H:
  READ1_H1:
     LDWR  R0,03FDH;读取H-01值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0BF3H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_H1_RET
     CJNE  R31,R33,READ1_H1_RET
     GOTO  READ1_H2
  READ1_H1_RET:
     LDWR  R0,0BF3H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2       ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_H2:
     LDWR  R0,03FEH;读取H-02值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0BF4H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_H2_RET
     CJNE  R31,R33,READ1_H2_RET
     GOTO  READ1_H3
  READ1_H2_RET:
     LDWR  R0,0BF4H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_H3:
     LDWR  R0,03FFH;读取H-03值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0BF5H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_H3_RET
     CJNE  R31,R33,READ1_H3_RET
     GOTO  READ1_H5
  READ1_H3_RET:
     LDWR  R0,0BF5H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2   ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_H5:
     LDWR  R0,0400H;读取H-05值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0BF6H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_H5_RET
     CJNE  R31,R33,READ1_H5_RET
     GOTO  READ1_H6
  READ1_H5_RET:
     LDWR  R0,0BF6H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2    ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_H6:
     LDWR  R0,0401H;读取H-06值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0BF7H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_H6_RET
     CJNE  R31,R33,READ1_H6_RET
     GOTO  READ1_H7
  READ1_H6_RET:
     LDWR  R0,0BF7H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2   ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_H7:
     LDWR  R0,0402H;读取H-07值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0BF8H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_H7_RET
     CJNE  R31,R33,READ1_H7_RET
     GOTO  READ1_H10
  READ1_H7_RET:
     LDWR  R0,0BF8H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2    ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_H10:
     LDWR  R0,0403H;读取H-10值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0BF9H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_H10_RET
     CJNE  R31,R33,READ1_H10_RET
     GOTO  READ1_H15
  READ1_H10_RET:
     LDWR  R0,0BF9H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2  ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
    
  READ1_H15:
     LDWR  R0,0404H;读取H-15值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0BFAH;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_H15_RET
     CJNE  R31,R33,READ1_H15_RET
     GOTO  READ1_H16
  READ1_H15_RET:
     LDWR  R0,0BFAH
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2   ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
  
  READ1_H16:
     LDWR  R0,0405H;读取H-16值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0BFBH;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_H16_RET
     CJNE  R31,R33,READ1_H16_RET
     GOTO  READ1_H17
  READ1_H16_RET:
     LDWR  R0,0BFBH
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2    ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_H17:
     LDWR  R0,0406H;读取H-16值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0BFCH;公共寄存器++;      02-22增加
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_H17_RET
     CJNE  R31,R33,READ1_H17_RET
     GOTO  READ1_H18
  READ1_H17_RET:
     LDWR  R0,0BFCH
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2    ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_H18:
     LDWR  R0,0407H;读取H-16值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0BFDH;公共寄存器++;      02-22增加
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_H18_RET
     CJNE  R31,R33,READ1_H18_RET
     GOTO  READ1_H19
  READ1_H18_RET:
     LDWR  R0,0BFDH
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2    ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_H19:
     LDWR  R0,0408H;读取H-16值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0BFEH;公共寄存器++;      02-22增加
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_H19_RET
     CJNE  R31,R33,READ1_H19_RET
     GOTO  READ1_H20
  READ1_H19_RET:
     LDWR  R0,0BFEH
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2    ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1

  READ1_H20:
     LDWR  R0,0409H;读取H-16值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0BFFH;公共寄存器++;      02-22增加
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_H20_RET
     CJNE  R31,R33,READ1_H20_RET
     GOTO  READ1_H21
  READ1_H20_RET:
     LDWR  R0,0BFFH
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2    ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_H21:
     LDWR	R0,03F4H
     MOVXR	R40,1,1
     IJNE	R41,1,不能急热   
    GOTO	急热判断
     不能急热:;非制热模式，不能选择急热
     LDWR	R0,040AH
     LDWR	R34,0
     MOVXR	R34,0,1
    
    急热判断:
    LDWR  R0,040AH;
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C00H;公共寄存器++;      02-22增加
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_H21_RET
     CJNE  R31,R33,READ1_H21_RET
     GOTO  READ1_H22
  READ1_H21_RET:

     
     LDWR  R0,0C00H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2    ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1  
     GOTO	READ1_H22
     
  READ1_H22:
     LDWR  R0,040BH;
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C01H;公共寄存器++;      02-22增加
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_H22_RET
     CJNE  R31,R33,READ1_H22_RET
     GOTO  READ1_H23
  READ1_H22_RET:
     LDWR  R0,0C01H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2    ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
     
   READ1_H23:  ;运行天数
     LDWR  R0,3103H;读取H-16值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0A73H;公共寄存器++;      02-22增加
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_H23_RET
     CJNE  R31,R33,READ1_H23_RET
 	LDBR	R50,0,6;用户没有设置，则把040BH覆盖3103H
 	LDWR	R0,040BH
 	MOVXR	R56,1,1	
 	LDBR	R60,0,6
 	LDWR	R66,24	
 	DIV		R50,R60,0;商放在R56:R57
 	LDWR	R0,3103H
 	MOVXR	R56,0,1
 	  
     GOTO  READ1_H24
  READ1_H23_RET:
     LDWR  R0,0A73H
     MOVXR R30,0,1
        
     LDWR  R0,0BC3H;标志位置位
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
     OR    R30,R32,2    ;0BC3的第1位为1，则参数发生变化
     MOVXR R30,0,1
      
   	LDBR	R30,0,8;用户更改了设置，则把3103H转化成小时040BH，传递给主板
 	LDBR	R40,0,8
 	LDWR	R0,3103H
 	MOVXR	R32,1,1;天
 	LDWR	R36,24;24h	
 	MAC		R30,R34,R40;R46:R47
 	LDWR	R0,040BH
 	MOVXR	R46,0,1     
  
  READ1_H24:   
    RET
     
  READ1_R:  ;R类参数
  READ1_R1:  
     LDWR  R0,0491H;读取R-01值++
     MOVXR R30,1,1;传给R30     
     LDWR  R0,0C7DH;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_R1_RET
     CJNE  R31,R33,READ1_R1_RET
     GOTO  READ1_R2
  READ1_R1_RET:
 
        LDWR  R0,0495H; R08
        MOVXR R40,1,1
        LDWR  R0,0496H; R09
        MOVXR R42,1,1
        LDWR  R0,0491H
        MOVXR R30,1,1        
        JS    R40,R30,1;若R01小于R08，则把R08赋给R01
        MOV   R40,R30,2
        JS    R30,R42,1;若R01大于R09，则把R09赋给R01
        MOV   R42,R30,2
        MOVXR R30,0,1  
        
     LDWR  R0,0C7DH
     MOVXR R30,0,1
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H;
     OR    R30,R32,2   ;0BC3的第2位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_R2:  
     LDWR  R0,0492H;读取R-02值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C7EH;公共寄存器++ 
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_R2_RET
     CJNE  R31,R33,READ1_R2_RET
     GOTO  READ1_R4
  READ1_R2_RET:

        LDWR  R0,0497H; R10
        MOVXR R40,1,1
        LDWR  R0,0498H; R11
        MOVXR R42,1,1
        LDWR  R0,0492H
        MOVXR R30,1,1        
        JS    R40,R30,1;若R02小于R10，则把R10赋给R02
        MOV   R40,R30,2
        JS    R30,R42,1;若R02大于R11，则把R11赋给R02
        MOV   R42,R30,2
        MOVXR R30,0,1 
        
     LDWR  R0,0C7EH
     MOVXR R30,0,1
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H
     OR    R30,R32,2  ;0BC3的第2位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_R4:
     LDWR  R0,0493H;读取R-04值++    
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C7FH;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_R4_RET
     CJNE  R31,R33,READ1_R4_RET
     GOTO  READ1_R5
  READ1_R4_RET:
     LDWR  R0,0C7FH
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H
     OR    R30,R32,2   ;0BC3的第2位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_R5:
     LDWR  R0,0494H;读取R-04值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C80H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_R5_RET
     CJNE  R31,R33,READ1_R5_RET
     GOTO  READ1_R8
  READ1_R5_RET:
     LDWR  R0,0C80H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H
     OR    R30,R32,2  ;0BC3的第2位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_R8:        
     LDWR  R0,0495H;读取R-04值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C81H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_R8_RET
     CJNE  R31,R33,READ1_R8_RET
     GOTO  READ1_R9
  READ1_R8_RET:

     LDWR	R0,0496H; R09
	 MOVXR	R40,1,1
	 JS		R30,R40,1;
	 MOV	R40,R30,2
	 
	 LDWR  R0,0495H;
	 MOVXR R30,0,1    	
     LDWR  R0,0C81H
     MOVXR R30,0,1    
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H
     OR    R30,R32,2   ;0BC3的第2位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_R9:
        
     LDWR  R0,0496H;读取R-04值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C82H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_R9_RET
     CJNE  R31,R33,READ1_R9_RET
     GOTO  READ1_R10
  READ1_R9_RET:

     LDWR	R0,0495H; R08
	 MOVXR	R40,1,1
	 JS		R40,R30,1;
	 MOV	R40,R30,2
	 
	 LDWR  R0,0496H
	 MOVXR R30,0,1  
     LDWR  R0,0C82H
     MOVXR R30,0,1  
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H
     OR    R30,R32,2   ;0BC3的第2位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_R10:
     LDWR  R0,0497H;读取R-04值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C83H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_R10_RET
     CJNE  R31,R33,READ1_R10_RET
     GOTO  READ1_R11
  READ1_R10_RET:
     LDWR	R0,0498H; R11
	 MOVXR	R40,1,1
	 JS		R30,R40,1;
	 MOV	R40,R30,2
	 
	 LDWR  R0,0497H
	 MOVXR R30,0,1  
     LDWR  R0,0C83H
     MOVXR R30,0,1 
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H
     OR    R30,R32,2;0BC3的第2位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_R11:
     LDWR  R0,0498H;读取R-04值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C84H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_R11_RET
     CJNE  R31,R33,READ1_R11_RET
     GOTO  READ1_R15
  READ1_R11_RET:

     LDWR	R0,0497H; R10
	 MOVXR	R40,1,1
	 JS		R40,R30,1;
	 MOV	R40,R30,2
	 
	 LDWR  R0,0498H
	 MOVXR R30,0,1    	
     LDWR  R0,0C84H
     MOVXR R30,0,1
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H
     OR    R30,R32,2;0BC3的第2位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_R15:
     LDWR  R0,0499H;读取R-04值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C85H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_R15_RET
     CJNE  R31,R33,READ1_R15_RET
     GOTO  READ1_R29
  READ1_R15_RET:
     LDWR  R0,0C85H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H
     OR    R30,R32,2;0BC3的第2位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_R29:
     LDWR  R0,049AH;读取R-04值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C86H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_R29_RET
     CJNE  R31,R33,READ1_R29_RET
     GOTO  READ1_R30
  READ1_R29_RET:
  
     LDWR	R0,049BH; R30
	 MOVXR	R40,1,1
	 JS		R40,R30,1;
	 MOV	R40,R30,2 	
	 
	 LDWR  R0,049AH
	 MOVXR R30,0,1  
     LDWR  R0,0C86H
     MOVXR R30,0,1
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H
     OR    R30,R32,2;0BC3的第2位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_R30:
     LDWR  R0,049BH;读取R-04值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C87H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_R30_RET
     CJNE  R31,R33,READ1_R30_RET
     GOTO  READ1_R31
  READ1_R30_RET:
     LDWR	R0,049AH; R29
	 MOVXR	R40,1,1
	 JS		R30,R40,1;
	 MOV	R40,R30,2
	 
	 LDWR  R0,049BH
	 MOVXR R30,0,1  
     LDWR  R0,0C87H
     MOVXR R30,0,1 
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H
     OR    R30,R32,2;0BC3的第2位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_R31:
     LDWR  R0,049CH;读取R-04值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C88H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_R31_RET
     CJNE  R31,R33,READ1_R31_RET
     GOTO  READ1_R32
  READ1_R31_RET:
     LDWR  R0,0C88H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0004H
     OR    R30,R32,2;0BC3的第2位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_R32:
     LDWR  R0,04A7H;读取R-04值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C89H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_R32_RET
     CJNE  R31,R33,READ1_R32_RET
     GOTO  READ1_R33
  READ1_R32_RET:
     LDWR	R0,04A8H; R33
	 MOVXR	R40,1,1
	 JS		R30,R40,1;
	 MOV	R40,R30,2
	 
	 LDWR  R0,04A7H
	 MOVXR R30,0,1    
     LDWR  R0,0C89H
     MOVXR R30,0,1 
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0008H
     OR    R30,R32,2;0BC3的第2位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_R33:
     LDWR  R0,04A8H;读取R-04值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C8AH;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_R33_RET
     CJNE  R31,R33,READ1_R33_RET
     GOTO  READ1_R34   
  READ1_R33_RET:
  
     LDWR	R0,04A7H; R32
	 MOVXR	R40,1,1
	 JS		R40,R30,1;
	 MOV	R40,R30,2
	 
	 LDWR  R0,04A8H
	 MOVXR R30,0,1
     LDWR  R0,0C8AH
     MOVXR R30,0,1
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0008H
     OR    R30,R32,2;0BC3的第2位为1，则参数发生变化
     MOVXR R30,0,1
     
   READ1_R34:
     LDWR  R0,04A9H;读取R-04值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C8BH;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_R34_RET
     CJNE  R31,R33,READ1_R34_RET
     GOTO  READ1_R35
  READ1_R34_RET:
     LDWR  R0,0C8BH
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0008H
     OR    R30,R32,2;0BC3的第2位为1，则参数发生变化
     MOVXR R30,0,1
    
  READ1_R35:
     LDWR  R0,04AAH;读取R-04值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0C8CH;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_R35_RET
     CJNE  R31,R33,READ1_R35_RET
     GOTO  READ1_R36
  READ1_R35_RET:
     LDWR  R0,0C8CH
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0008H
     OR    R30,R32,2;0BC3的第2位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_R36:
     RET
  
  READ1_P:
   READ1_P01:
     LDWR  R0,04BFH;读取P-01值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0CA1H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_P01_RET
     CJNE  R31,R33,READ1_P01_RET
     GOTO  READ1_P02 
   READ1_P01_RET:  
     LDWR  R0,0CA1H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0008H
     OR    R30,R32,2;0BC3的第2位为1，则参数发生变化
     MOVXR R30,0,1
     
  READ1_P02:
     LDWR  R0,04C0H;读取P-02值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0CA2H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_P02_RET
     CJNE  R31,R33,READ1_P02_RET
     GOTO  READ1_P03
     
   READ1_P02_RET:
     LDWR  R0,0CA2H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0008H
     OR    R30,R32,2;0BC3的第2位为1，则参数发生变化
     MOVXR R30,0,1
    
   READ1_P03:
     LDWR  R0,04C1H;读取P-03值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0CA3H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_P03_RET
     CJNE  R31,R33,READ1_P03_RET
     GOTO  READ1_P04
     
   READ1_P03_RET:
     LDWR  R0,0CA3H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0008H
     OR    R30,R32,2;0BC3的第2位为1，则参数发生变化
     MOVXR R30,0,1
     
   READ1_P04:  
     LDWR  R0,04C2H;读取P-03值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0CA4H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_P04_RET
     CJNE  R31,R33,READ1_P04_RET
     GOTO  READ1_T01
     
   READ1_P04_RET:
     LDWR  R0,0CA4H
     MOVXR R30,0,1
     
     LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0008H
     OR    R30,R32,2;0BC3的第3位为1，则参数发生变化
     MOVXR R30,0,1
     
   READ1_U:
;     READ1_U01:
;     LDWR  R0,04AAH;读取P-03值++
;     MOVXR R30,1,1;传给R30
;     LDWR  R0,0A67H;公共寄存器++
;     MOVXR R32,1,1;传给R32
;     CJNE  R30,R32,READ1_U01_RET
;     CJNE  R31,R33,READ1_U01_RET
;     GOTO  READ1_T01
;     
;   READ1_U01_RET:
;     LDWR  R0,0A67H
;     MOVXR R30,0,1
;     
;     LDWR  R0,0BC3H
;	 MOVXR R30,1,1
;	 LDWR  R32,0004H
;     OR    R30,R32,2;0BC3的第2位为1，则参数发生变化
;     MOVXR R30,0,1
     
     
   READ1_T01:
     LDWR  R0,04CCH;0499H;读取    值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0CAEH;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_T01_RET
     CJNE  R31,R33,READ1_T01_RET
     GOTO  READ1_T02
     
    READ1_T01_RET:;++

	 LDWR 	 R0,0CAEH;++取出参数当前值，用于下一轮比较
     MOVXR   R30,0,1
    
     LDWR    R0,0BC3H
	 MOVXR   R30,1,1
	 LDWR    R32,0008H;0BC3的第3位为1，则参数发生变化
     OR      R30,R32,2
     MOVXR   R30,0,1 
    
     LDWR	R0,3900H
	 LDBR	R30,00H,48
	 MOVXR	R30,0,24;清空了定时1绿色图标显示变量
     CALL	TIMER1_IF_SET  
    
 READ1_T02:    
     LDWR  R0,04CEH;049BH;读取P-03值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0CB0H;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_T02_RET
     CJNE  R31,R33,READ1_T02_RET
     GOTO  READ1_T03
     
    READ1_T02_RET:;++

	 LDWR 	R0,0CB0H;++取出参数当前值，用于下一轮比较
     MOVXR   R30,0,1
   
     LDWR    R0,0BC3H
	 MOVXR   R30,1,1
	 LDWR    R32,0008H;0BC3的第2位为1，则参数发生变化
     OR      R30,R32,2
     MOVXR   R30,0,1 
    
     LDWR	R0,3900H
	 LDBR	R30,00H,48
	 MOVXR	R30,0,24;清空了定时1绿色图标显示变量
     CALL	TIMER1_IF_SET  
     
  READ1_T03:    
     LDWR  R0,04CBH;读取P-03值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0CADH;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_T03_RET
     CJNE  R31,R33,READ1_T03_RET
     GOTO  READ1_T04
     
    READ1_T03_RET:;++

	 LDWR 	 R0,0CADH;++取出参数当前值，用于下一轮比较
     MOVXR   R30,0,1
   
     LDWR    R0,0BC3H
	 MOVXR   R30,1,1
	 LDWR    R32,0008H;0BC3的第2位为1，则参数发生变化
     OR      R30,R32,2
     MOVXR   R30,0,1 
     LDWR	R0,3900H
	 LDBR	R30,00H,48
	 MOVXR	R30,0,24;清空了定时1绿色图标显示变量
     CALL	TIMER1_IF_SET   
     
  READ1_T04:    
     LDWR  R0,04CDH;049AH;读取P-03值++
     MOVXR R30,1,1;传给R30
     LDWR  R0,0CAFH;公共寄存器++
     MOVXR R32,1,1;传给R32
     CJNE  R30,R32,READ1_T04_RET
     CJNE  R31,R33     ,READ1_T04_RET
     GOTO  READ1_T05
     
    READ1_T04_RET:;++

	 LDWR 	 R0,0CAFH;++取出参数当前值，用于下一轮比较
     MOVXR   R30,0,1
   
     LDWR    R0,0BC3H
	 MOVXR   R30,1,1
	 LDWR    R32,0008H;0BC3的第3位为1，则参数发生变化
     OR      R30,R32,2
     MOVXR   R30,0,1 
     LDWR	R0,3900H
	 LDBR	R30,00H,48
	 MOVXR	R30,0,24;清空了定时1绿色图标显示变量
     CALL	TIMER1_IF_SET      
     
    READ1_T05:
    
    READ1_MODBUS_SLAVE:
	LDWR 	R0,6FFFH;		修改彩屏的从机地址
    MOVXR   R30,1,1;传给R30
    LDWR    R0,6FFCH;公共寄存器++，
    MOVXR   R32,1,1;传给R32
    CJNE 	R30,R32,READ1_RET_MODBUS_SLAVE;++
    CJNE 	R31,R33,READ1_RET_MODBUS_SLAVE;++
    GOTO 	READ_NEXT_RET;++
 
    READ1_RET_MODBUS_SLAVE:;++
	LDWR	R20,0002H
	JS		R20,R30,READ_NEXT_RET


	LDWR 	R0,6FFCH;++取出参数当前值，用于下一轮比较
    MOVXR   R30,0,1
    
    LDBR	R40,5AH,1
    MOVRD	R40,1DH,1
    MOVRD	R31,13H,1
    
    LDBR 	R4,02H,1;加载用户数据库地址02 87 01 10到R4、R5、R6、R7
	LDBR 	R5,87H,1
	LDBR 	R6,01H,1
	LDBR 	R7,10H,1
	LDWR 	R0,6FFFH
	MOVXL 	3,01H;存储本次的设定值，下次上电时启用
	READ_NEXT_RET:
     RET
   
    
  Status_Display:    
;     LDWR   R55,07D9H; 状态拆分起始地址
;	 MOV    R55,R0,2
;	 MOVXR  R11,1,1
;	 BITS   R11,0900H;0900H~0907H 高八位状态
;	 BITS   R12,0908H;0908H~090FH 低八位状态 
	 
	 LDWR   R0,07DCH
	 MOVXR  R30,1,1
	 IJNE   R31,00H,next_judge01
	 LDWR   R0,0320H
	 LDWR   R40,0000H
	 MOVXR  R40,0,1
	 GOTO   Status_Display_RET
	 
	 next_judge01:
	 IJNE   R31,01H,next_judge02
	 LDWR   R0,0320H
	 LDWR   R40,0001H
	 MOVXR  R40,0,1
	 GOTO   Status_Display_RET
	
	 next_judge02:
	 IJNE   R31,FAH,Status_Display_RET
	 LDWR   R0,0320H
	 LDWR   R40,0002H
	 MOVXR  R40,0,1
	 GOTO   Status_Display_RET
	 
  Status_Display_RET:
     RET;
     
     
  Fault_Handle:
     LDWR  R48,3404H;故障状态,为1时表示故障已报不需要重复报，为0表示先前未报故障     
	 LDWR  R35,0FCDH;MCU故障图标实时显示,有故障时主界面显示红色的图标        
	 LDWR  R46,0859H;通信检测变量，主板不断写5AA5到该变量          *******2016-02-18
	 LDWR  R68,3400H;通讯故障开始时间保存地址（共3个）
	 LDWR  R64,3403H;通讯故障计时标志 
     
     MOV   R46,R0,2;0827H，读取正常的情况下值为5AA5，读取不正常时为0
	 MOVXR R38,1,1
	 IJNE  R38,5AH,2
	 IJNE  R39,A5H,1
	 GOTO  communicate_ok;返回为0就通讯不正常,返回不为0则通讯正常
	 MOV   R64,R0,2;3403H，控制计时的标志位
	 MOVXR R66,1,1;判断计时启动标志.如果为0，则启动或重新启动计时，如果为1，则继续计时。
	 IJNE  R67,0,communicate_fault_continue;故障持续
     
     LDWR  R66,0001H
	 MOVXR R66,0,1;计时标志置1
	 LDWR	R0,1021H;计时清零
	 LDWR	R30,0000H
	 MOVXR	R30,0,1
;	 MOVDR 20H,R100,7;获取当前时间-只进来一次 年 月 日 星期 时 分  秒
;	 MOV   R104,R103,1;因为TIME只计算年月日时分秒，所以要把星期滤掉
;	 MOV   R105,R104,1　　
;	 MOV   R106,R105,1
;	 MOV   R68,R0,2
;	 MOVXR R100,0,3;计时起始时间保存3400H 3401H 3402H  年月 日时 分秒
	 
  communicate_fault_continue:
;	 MOV 	R68,R0,2;3400H,3401H,3402H保存的是计时起点的值
;	 MOVXR 	R100,1,3;读取计时起始时间
;	 TIME 	R90,R100,2;当前时间减去已保存的起始时间得到差值放在R90---计算默认是6个字节的计算
;	 LDBR 	R60,0,1;先清零，消除干扰
;	 MOV 	R94,R61,1;
;	 LDWR 	R62,1;1分钟
;	 JS 	R60,R62,communicate_ok_RET;≥1min就往下执行，否则跳转 
	 
	 LDWR	R0,1021H
	 MOVXR	R30,1,1
	 INC	R30,1,0001H
	 MOVXR	R30,0,1
	 LDWR	R32,0131H
	 JS		R30,R32,communicate_ok_ret
	 
     LDWR 	R40,0001H;
	 MOV 	R35,R0,2;
	 MOVXR 	R40,0,1;通讯不正常写97图标,主界面显示故障图标	 *******test11-06	
	 
	 LDWR	R40,0000H;清掉非通信故障报警的标志位。如果通信和非通信两个标志位同时为1，两个闪烁叠加的效果就是静态的。
	 LDWR	R0,0FCFH
	 MOVXR	R40,0,1	  
	 
	 MOV 	R48,R0,2;3404H,R48保存了故障标志位
	 MOVXR 	R90,1,1	 
	 IJNE 	R91,0,communicate_ok_RET;如果标志位被置1了,说明通讯故障已报
		
	 LDWR 	R40,0001H;
	 MOV 	R48,R0,2;3404H
	 MOVXR 	R40,0,1;故障标志置1，下一次就不会再进来运行下面的故障移位		
     CALL	Fault_Shift;故障移位

	 LDWR 	R137,006DH
	 LDWR 	R0,6101H  
	 MOVXR 	R137,0,1;故障序号65显示第65个图标   (通信故障图标)            *******test11-06
		
	 MOVDR 	20H,R100,7;取出当前时间，滤掉星期，显示在后面
	 MOV 	R104,R103,1
	 MOV 	R105,R104,1
	 MOV 	R106,R105,1;R100年 R101月 R102日 R103时 R104分 R105秒
	 
;	 MOV		R100,R30,1
;	 MOV		R101,R100,1
;	 MOV		R102,R101,1
;	 MOV		R30,R102,1;R100月 R101日 R102年 R103时 R104分 R105秒
	 
	 LDWR 	R0,6103H
	 MOVXR 	R100,0,3;故障发生时间显示		
	 CALL 	Fault_SAVE;保存
	 GOTO	communicate_ok_RET;保存完毕就跳出
  
 communicate_fault_continue_RET: 
 
 communicate_ok:
     LDWR	R0,1021H;计时清零
	 LDWR	R30,0000H
	 MOVXR	R30,0,1
  
	 MOV 	R46,R0,2;0827H，读取正常的情况下值为5AA5，读取不正常时为0
	 LDWR	R30,0000H
	 MOVXR	R30,0,1	
	 
	 LDWR 	R90,0
	 MOV 	R64,R0,2
	 MOVXR 	R90,0,1;通讯故障计时保存标志0--重新计时.
	 LDWR 	R40,0;通讯故障状态，为0表示未报故障，下次为1时故障参数将会产生移位
	 MOV 	R48,R0,2
	 MOVXR 	R40,0,1	 
     LDWR 	R40,0000H;主界面故障图标置1
	 LDWR	R0,0FCDH;主界面故障显示30图标(30图标不存在,因此不会有显示)
	 MOVXR 	R40,0,1			
  communicate_ok_RET:
  
  CALL_Fault_MCU_Function:
	 CALL Fault_MCU_Function
  CALL_Fault_MCU_Function_RET:
  
  Fault_Handle_RET:
     RET
     
  Fault_Shift:
	 LDWR 	R170,6410H ;;;;;;;移位所有行
	 LDWR 	R172,6410H ;;;;;;;移位所有行
	 LDWR 	R174,6100H		
	cycle_fault_shift:
		DEC 	R170,1,0010H
		MOV 	R170,R0,2
		MOV 	R172,R2,2
		MOVXX 	16        ;R0 R1 和R2 R3之间的数据交换
		DEC 	R172,1,0010H
		JS 		R174,R172,cycle_fault_shift     ;循环	

  Fault_Shift_RET:
     RET
       
  Fault_SAVE:;----把故障记录数据写入flash
	 LDWR 	R40,5AA5H
	 LDWR 	R0,60FFH;故障头
	 MOVXR 	R40,0,1
	 LDBR 	R4,02H,1;加载用户数据库地址02 8C 00 FF到R4、R5、R6、R7      
	 LDBR 	R5,89H,1  
	 LDBR 	R6,00H,1
	 LDBR 	R7,FFH,1;
	 LDWR 	R0,60FFH;(6100-641F:50个故障记录)
	 MOVXL 	3,801;模式3--DGUS变量到用户数据库，800个字长度	
	 LDBR 	R217,1,1;每次故障有保存，就认为新故障发生了
  Fault_SAVE_RET:
     RET;   
     
  Fault_Clean:;----故障清除  
	 LDBR 	R80,0,32;
	 LDWR 	R140,6100H;;清除所有50行故障
	 LDWR 	R176,6411H
	cycle_clean_50line:
		MOV 	R140,R0,2
		MOVXR 	R80,0,16
		INC 	R140,1,0010H
		JS 		R140,R176,cycle_clean_50line;这里是个清理循环
	 CALL 	Fault_SAVE;保存，清空存储区
	

	 LDWR 	R0,3404H;清除通讯故障标志,该标志为0，表示未报通信故障
	 MOVXR	R80,0,1
	 LDWR	R0,3400H;清除通信故障计时起始时间和计时标志
	 MOVXR	R80,0,4
	 LDBR	R80,0,32
	 LDWR	R0,3404H;清空“通讯故障是否已报”标志位
	 MOVXR	R80,0,1;
	 
	 LDWR	R0,5040H;清空“故障是否已报”标志位
	 MOVXR	R80,0,16;
	 LDWR	R0,5050H;清空“故障是否已报”标志位
	 MOVXR	R80,0,16;
	 LDWR	R0,5060H;清空“故障是否已报”标志位
	 MOVXR	R80,0,16;
	 LDWR	R0,5070H;清空“故障是否已报”标志位
	 MOVXR	R80,0,16;
	 LDWR	R0,5080H;清空“故障是否已报”标志位
	 MOVXR	R80,0,16;
	 LDWR	R0,5090H;清空“故障是否已报”标志位
	 MOVXR	R80,0,16;
	 LDWR	R0,50A0H;清空“故障是否已报”标志位
	 MOVXR	R80,0,16;
	 LDWR	R0,50B0H;清空“故障是否已报”标志位
	 MOVXR	R80,0,16;
	 
	 
	 ;LDBR   R217,0,1;新故障清零
	 LDWR	R0,0859H;清除通信故障
	 LDWR	R30,5AA5H
	 MOVXR	R30,0,1
	 LDWR	R0,0FCDH;故障图标显示地址       *******test 11-06
	 LDWR	R30,0000H
	 MOVXR	R30,0,1;无故障（无图标）   *******test 11-06
	 
  Fault_Clean_RET:;
     RET        
     
  Fault_MCU_Function:
      
       LDWR  R0,0847H
       MOVXR R30,1,1
;       LDWR  R32,FFFFH
;       AND   R30,R32,2       
       LDWR  R0,3500H
       MOVXR R30,0,1
     
       LDWR  R0,0848H
       MOVXR R30,1,1
       LDWR  R32,3FFFH
       AND   R30,R32,2       
       LDWR  R0,3501H
       MOVXR R30,0,1
       
       LDWR  R0,0849H
       MOVXR R30,1,1
       LDWR  R32,3FFFH
       AND   R30,R32,2       
       LDWR  R0,3502H
       MOVXR R30,0,1
       
       LDWR  R0,084AH
       MOVXR R30,1,1
       LDWR  R32,1FFFH
       AND   R30,R32,2       
       LDWR  R0,3503H
       MOVXR R30,0,1
  	
  	  ; 8888
;  	   LDWR   R0,03FEH;  判断系统数量
;       MOVXR  R30,1,1;
;	   IJNE   R31,3,Fault_MCU_4;为3则表示三系统
;	   LDWR   R0,047FH;判断是否启用增焓
;       MOVXR  R30,1,1;   
;       IJNE   R31,0,Fault_MCU_3;为0则表示不启用 
;    Fault_MCU_no3:;三系统不启用增焓
;       LDWR  R0,084BH
;       MOVXR R30,1,1
;       LDWR  R32,FFBBH
;       AND   R30,R32,2       
;       LDWR  R0,3504H
;       MOVXR R30,0,1
;  
;       LDWR  R0,084CH
;       MOVXR R30,1,1
;       LDWR  R32,0387H
;       AND   R30,R32,2       
;       LDWR  R0,3505H
;       MOVXR R30,0,1
;      
;       LDWR  R0,084DH
;       MOVXR R30,1,1
;       LDWR  R32,0770H
;       AND   R30,R32,2       
;       LDWR  R0,3506H
;       MOVXR R30,0,1 
;       GOTO  Fault_1
;  	Fault_MCU_3:;三系统启用增焓   	
;  	   LDWR  R0,084BH
;       MOVXR R30,1,1
;       LDWR  R32,FFBBH
;       AND   R30,R32,2       
;       LDWR  R0,3504H
;       MOVXR R30,0,1
;  
;       LDWR  R0,084CH
;       MOVXR R30,1,1
;       LDWR  R32,770FH
;       AND   R30,R32,2       
;       LDWR  R0,3505H
;       MOVXR R30,0,1
;      
;       LDWR  R0,084DH
;       MOVXR R30,1,1
;       LDWR  R32,0777H
;       AND   R30,R32,2       
;       LDWR  R0,3506H
;       MOVXR R30,0,1    
;       GOTO  Fault_1
  	Fault_MCU_4:;四系统启用增焓
;  	   LDWR   R0,047FH;判断是否启用增焓
;       MOVXR  R30,1,1;   
;       IJNE   R31,1,Fault_MCU_no4;为1则表示启用 
       LDWR  R0,084BH
       MOVXR R30,1,1
       LDWR  R32,FFFBH
       AND   R30,R32,2       
       LDWR  R0,3504H
       MOVXR R30,0,1
  
       LDWR  R0,084CH
       MOVXR R30,1,1
       LDWR  R32,FFFFH
       AND   R30,R32,2       
       LDWR  R0,3505H
       MOVXR R30,0,1
      
       LDWR  R0,084DH
       MOVXR R30,1,1
       LDWR  R32,6FFFH
       AND   R30,R32,2       
       LDWR  R0,3506H
       MOVXR R30,0,1      
 	   GOTO  Fault_1
 	   
   	Fault_MCU_no4:;四系统不启用增焓

;       LDWR  R0,084BH
;       MOVXR R30,1,1
;       LDWR  R32,FFFBH
;       AND   R30,R32,2       
;       LDWR  R0,3504H
;       MOVXR R30,0,1
;  
;       LDWR  R0,084CH
;       MOVXR R30,1,1
;       LDWR  R32,0FFFH
;       AND   R30,R32,2       
;       LDWR  R0,3505H
;       MOVXR R30,0,1
;      
;       LDWR  R0,084DH
;       MOVXR R30,1,1
;       LDWR  R32,0FF0H
;       AND   R30,R32,2       
;       LDWR  R0,3506H
;       MOVXR R30,0,1      
 	   GOTO  Fault_1
  Fault_1:;主界面故障图标显示
     
	 LDWR 	R0,3500H;  第一类故障  0847H=3500H
	 MOVXR  R74,1,1
     LDWR   R30,8000H
     AND    R74,R30,2 
	 LDWR	R110,0
	 ;JS     R110,R74,有闪烁故障发生 ;这里不知道为什么用JS做不了
	 IJNE	R74,0,有闪烁故障发生;无故障则执行下一条，否则跳转 	
	 IJNE	R75,0,有闪烁故障发生	;lsz 12.3添加
	 
	 LDWR 	R0,3501H;    0848H=3501H
	 MOVXR  R76,1,1
     LDWR   R30,2000H
     AND    R76,R30,2 
	 LDBR	R110,00H,2
	 JS		R110,R76,有闪烁故障发生;无故障则执行下一条，否则跳转 
   
     LDWR   R0,3502H;  第二类故障（三次以上故障）0849H=3502H
	 MOVXR  R78,1,1
	 LDWR   R30,3FFFH
     AND    R78,R30,2 
	 LDBR   R110,00H,2
	 JS     R110,R78,有闪烁故障发生;
	 
	 LDWR   R0,3503H;  进出水温差过大3次以上  084AH=3503H
	 MOVXR  R80,1,1
	 LDWR   R30,1FFFH
     AND    R80,R30,2 
	 LDBR   R110,00H,2
	 JS     R110,R80,有闪烁故障发生;	
	 
	 LDWR   R0,3504H;    084BH=3504H
	 MOVXR  R82,1,1
	 LDWR   R30,FF85H      ;2016-02-18
     AND    R82,R30,2         
	 LDBR   R110,00H,2
	 ;JS     R110,R82,有闪烁故障发生 ;这里不知道为什么用JS做不了
	 IJNE	R82,0,有闪烁故障发生
	; IJNE	R73,0,有闪烁故障发生	;lsz 12.3注销
	 IJNE	R83,0,有闪烁故障发生    ;lsz 12.3添加
	 
	 LDWR   R0,3505H;  进出水温差过大3次以上 084CH=3505H
	 MOVXR  R84,1,1
	 LDWR   R30,00FFH
     AND    R84,R30,2 
	 LDBR   R110,00H,2
	 JS     R110,R84,有闪烁故障发生
	
	 LDWR   R0,3506H;  进出水温差过大3次以上 084DH=3506H
	 MOVXR  R84,1,1
	 LDWR   R30,00F0H
     AND    R84,R30,2
	 LDBR   R110,00H,2
	 JS     R110,R84,有闪烁故障发生       
	 
  Fualt_off: 
	 LDWR	R0,0FCFH; 非通信故障图标显示地址       *******test 11-06
	 LDWR	R30,0000H
	 MOVXR	R30,0,1;
	 LDWR	R0,0FD8H   ;故障图标，01-14增加
	 MOVXR	R30,0,1;
	 GOTO	compare_prepare1

有闪烁故障发生:
    
	LDWR	R0,0FCFH
    LDWR	R30,0001H
	MOVXR	R30,0,1;有故障     
     
    LDWR	R30,0001H;故障图标，01-14增加
	LDWR	R0,0FD8H
	MOVXR	R30,0,1

  compare_prepare1:  	
	 LDWR	R144,0070H;预留故障标志，对应图标112(通信故障对应图标109,不在此处判断，刚好109图标是个故障预留位，懒得改了)
	 LDWR	R60,4FC0H;R11的最高位，对应预留故障
	 LDWR	R70,5030H;502FH+1,故障的最低位+1,循环到最低位判断完后退出循环	
	 LDWR	R80,5040H;用于保存“是否报故障”标志位，1表示已报故障，0表示未报故障       *****test 11-06
	 LDWR	R50,0000H
	 LDWR	R40,0000H
	
  cycle_compare1:;循环比较，逐个判断0847的各个位为0还是为1，并作出相应处理	     
	 CALL Fault_dismis 
	 MOV	R60,R0,2
	 MOVXR	R50,1,1;R51存储的是  各个位的位值
	 MOV	R80,R0,2
	 MOVXR	R40,1,1;R41为“是否报故障标志位”
	
	 IJNE	R51,01H,come_to_next2;无故障则清空故障标记并进行下一个比较
	 IJNE	R41,00H,come_to_next1;故障已报则跳转到下一个比较
	
	 LDWR	R40,0001H
	 MOV	R80,R0,2
	 MOVXR	R40,0,1;记录故障已报
	CALL   fault_para_display01
	CALL   fault_para_display02
	
	 CALL	Fault_Shift;故障移位
	 CALL	Fault_display;故障显示
	LDWR	R0,300FH
	LDWR	R30,0001H
	MOVXR	R30,0,1
;	 CALL 	Fault_SAVE;保存
	 	 	 
  come_to_next1:;故障已报则跳转到下一个比较
;     CALL   fault_para_display01
;     CALL   fault_para_display02

	
	 DEC	R144,1,0001H
	 INC	R80,1,0001H
	 INC	R60,1,0001H
	 JS		R60,R70,cycle_compare1
	LDWR	R0,300FH
	MOVXR	R30,1,1
	IJNE	R31,1,3
	LDBR	R31,0,1
	MOVXR	R30,0,1
	CALL 	Fault_SAVE;故障保存
	 GOTO	Fault_MCU_Function_RET
	
  come_to_next2:;无故障则清空“是否报故障”标记并进行下一个比较
     
     MOV	R80,R0,2
     MOVXR	R40,1,1
     IJNE	R41,1,4;若故障是否已报标志位已经清零，则不再清零，否则清零，并将对应的故障恢复显示。
     LDWR	R40,0000H
     MOVXR	R40,0,1
     CALL   nofault_para_display01;由于故障而显示“-.-”的参数恢复显示，这个只在恢复后的第一个循环才执行一次
     CALL   nofault_para_display02

	 ;IJNE	R41,01H,3

	 INC	R80,1,0001H
	 INC	R60,1,0001H
	 DEC	R144,1,0001H
	 JS		R60,R70,cycle_compare1
	LDWR	R0,300FH
	MOVXR	R30,1,1
	IJNE	R31,1,3
	LDBR	R31,0,1
	MOVXR	R30,0,1
	CALL 	Fault_SAVE;故障保存
	 GOTO	Fault_MCU_Function_RET
		
  Fault_MCU_Function_RET:
     RET;
     
  ;这里的故障是年月日时分的显示方式，现改为日月年时分
  Fault_display:;故障显示

	 LDWR 	R0,6101H;     ******** 故障显示的首地址
	 MOVXR 	R144,0,1;保存故障序号
				
	 MOVDR 	20H,R100,7;6103H-610FH保存最新故障时间
	 ;年日调换位置即可
	 MOV    R100,R30,1
	 MOV    R102,R100,1  
	 MOV    R30,R102,1   
	 ;;;;;;;;;;;;;;;;;;;
	 ;;;;;;摄氏度华氏度分别显示月日年和日月年		LSZ 12.19添加
	 LDWR	R0,040CH
	 MOVXR	R40,1,1
	 IJNE	R41,1,3
	 	MOV    R100,R30,1
	 	MOV    R101,R100,1
	 	MOV    R30,R101,1
	 ;;;;;;;;;;;;;;;;;
	 MOV 	R104,R103,1
	 MOV 	R105,R104,1
	 MOV 	R106,R105,1
	 LDWR 	R0,6103H
	 MOVXR 	R100,0,3;故障发生时间显示	 	
			
  Fault_display_RET:
     RET

  Fault_Recover:;		----上电恢复历史故障
	
	 LDBR 	R4,02H,1;加载用户数据库地址02 8C 00 FF到R4、R5、R6、R7--加一个故障头0x5A5AH
	 LDBR 	R5,89H,1
	 LDBR 	R6,00H,1
	 LDBR 	R7,FFH,1
	 LDWR 	R0,60FFH;(6100-641F:50个故障记录)    ******test 11-07
	 MOVXL 	2,801;模式2--用户数据库到DGUS变量，800个字长度:如果50条记录，占用787个字
	 LDWR 	R0,60FFH;判读故障头
	 MOVXR 	R40,1,1
	 IJNE 	R41,A5H,2;判断是否符合故障头条件，不满足就清空----去除乱码
	 IJNE 	R40,5AH,1;判断是否符合故障头条件，不满足就清空----去除乱码
	 GOTO   Fault_Recover_RET
	 CALL   Fault_Clean
  Fault_Recover_RET:
     RET;  
     
  Fault_dismis:  
     LDWR 	R74,3500H;第一类故障,(单次故障显示)
	 MOV 	R74,R0,2	   
	 MOVXR 	R11,1,1
	 BITS   R11,5020H; 高8位5020~5027H	 
	 BITS   R12,5028H; 低8位5028H~502FH
	
	 LDWR   R74,3501H;
	 MOV    R74,R0,2     
	 MOVXR  R11,1,1
	 BITS 	R11,5010H;高8位5010~5017
	 BITS 	R12,5018H;低8位5018~501F  第一类中的进出水温差过大保护
	
	 LDWR 	R74,3502H;   第二类故障,(大于3次故障的显示)
	 MOV 	R74,R0,2     
	 MOVXR 	R11,1,1
	 BITS 	R11,5000H; 高8位5000~5007
	 BITS 	R12,5008H; 低8位5008~500F
	
	 LDWR   R74,3503H; 
	 MOV    R74,R0,2   
	 MOVXR  R11,1,1
	 BITS   R11,4FF0H;高8位4FF0~4FF7
	 BITS   R12,4FF8H;低8位4FF8~4FFFH  第二类故障(进出水温差过大三次以上)
	 
	 LDWR   R74,3504H;
	 MOV    R74,R0,2
	 MOVXR  R11,1,1
	 BITS   R11,4FE0H;高8位4FE0~4FE7H)
	 BITS   R12,4FE8H;低8位4FE8~4FEFH )
	 
	 LDWR   R74,3505H;
	 MOV    R74,R0,2
	 MOVXR  R11,1,1
	 BITS   R11,4FD0H;高8位4FD0~4FD7H
	 BITS   R12,4FD8H;低8位4FD8~4FDFH  )
	 
	 LDWR   R74,3506H;
	 MOV    R74,R0,2
	 MOVXR  R11,1,1
	 BITS   R11,4FC0H;高8位4FC0~4FC7H
	 BITS   R12,4FC8H;低8位4FC8~4FCFH  )
	 
  Fault_dismis_RET:
     RET
  
  
  fault_para_display01:;有故障时的显示
	para_T01:;进水
	IJNE	R60,4FH,para_T02
	IJNE	R61,EFH,para_T02
	LDWR	R0,1601H ;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	
	LDWR	R0,1100H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	LDWR	R0,1700H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1 
	
	LDWR	R0,1640H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	LDWR	R0,1930H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
		
	LDWR	R0,1990H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	;LDWR	R0,1750H
	LDWR	R0,16D0H	;LSZ 11.22添加
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	LDWR	R0,1660H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	LDWR	R0,1780H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	para_T02:;出水
	IJNE	R60,4FH,para_T04
	IJNE	R61,EEH,para_T04
	LDWR	R0,1602H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1110H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	LDWR	R0,1710H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	LDWR	R0,1790H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	LDWR	R0,1650H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	LDWR	R0,1940H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	LDWR	R0,1980H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	;LDWR	R0,17B0H
	LDWR	R0,16E0H	;LSZ 11.22添加
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
		
	LDWR	R0,1670H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
		
	para_T04:;系统1盘管
	IJNE	R60,4FH,para_T05
	IJNE	R61,ECH,para_T05
	LDWR	R0,1604H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1130H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T05:;系统2盘管
	IJNE	R60,4FH,para_T06
	IJNE	R61,EBH,para_T06
	LDWR	R0,1605H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1140H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	para_T06:;系统3盘管
	IJNE	R60,4FH,para_T07
	IJNE	R61,EAH,para_T07
	LDWR	R0,1606H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1150H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	IJNE	R60,4FH,para_T07
	IJNE	R61,EAH,para_T07
	LDWR	R0,1606H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,15D0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	para_T07:;系统4盘管
	IJNE	R60,4FH,para_T08
	IJNE	R61,E9H,para_T08
	LDWR	R0,1607H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1160H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T08:;环境
	IJNE	R60,4FH,para_T09
	IJNE	R61,E8H,para_T09
	LDWR	R0,1608H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1170H		;74页
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	LDWR	R0,1730H		;91页
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	LDWR	R0,17C0H		;119页
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	;lsz 12.18添加
	LDWR	R0,640H			;92页
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T09:;系统1防冻感温1
	IJNE	R60,4FH,para_T10
	IJNE	R61,E7H,para_T10
	LDWR	R0,1609H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1180H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T10:;系统1防冻感温2
	IJNE	R60,4FH,para_T11
	IJNE	R61,E6H,para_T11
	LDWR	R0,160AH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1190H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T11:;系统1防冻感温3
	IJNE	R60,4FH,para_T12
	IJNE	R61,E5H,para_T12
	LDWR	R0,160BH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,11A0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T12:;系统1防冻感温4
	IJNE	R60,4FH,para_T13
	IJNE	R61,E4H,para_T13
	LDWR	R0,160CH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,11B0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T13:;系统2防冻感温1
	IJNE	R60,4FH,para_T14
	IJNE	R61,E3H,para_T14
	LDWR	R0,160DH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,11C0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	IJNE	R60,4FH,para_T14
	IJNE	R61,E3H,para_T14
	LDWR	R0,160DH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1520H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T14:;系统2防冻感温2
	IJNE	R60,4FH,para_T15
	IJNE	R61,E2H,para_T15
	LDWR	R0,160EH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,11D0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	IJNE	R60,4FH,para_T15
	IJNE	R61,E2H,para_T15
	LDWR	R0,160EH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1530H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T15:;系统2防冻感温3
	IJNE	R60,4FH,para_T16
	IJNE	R61,E1H,para_T16
	LDWR	R0,160FH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,11E0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T16:;系统2防冻感温4
	IJNE	R60,4FH,fault_para_display01_ret
	IJNE	R61,E0H,fault_para_display01_ret
	LDWR	R0,1610H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,11F0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
  fault_para_display01_ret:
    RET
    
  fault_para_display02:
	para_T17:;系统3防冻感温1
	IJNE	R60,4FH,para_T18
	IJNE	R61,DFH,para_T18
	LDWR	R0,1611H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,19A0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	IJNE	R60,4FH,para_T18
	IJNE	R61,DFH,para_T18
	LDWR	R0,1611H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1540H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	IJNE	R60,4FH,para_T18
	IJNE	R61,DFH,para_T18
	LDWR	R0,1611H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,17D0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T18:;系统3防冻感温2
	IJNE	R60,4FH,para_T19
	IJNE	R61,DEH,para_T19
	LDWR	R0,1612H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,19B0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	IJNE	R60,4FH,para_T19
	IJNE	R61,DEH,para_T19
	LDWR	R0,1612H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1550H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T19:;系统3防冻感温3
	IJNE	R60,4FH,para_T20
	IJNE	R61,DDH,para_T20
	LDWR	R0,1613H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,19C0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T20:;系统3防冻感温4
	IJNE	R60,4FH,para_T21
	IJNE	R61,DCH,para_T21
	LDWR	R0,1614H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1350H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T21:;系统4防冻感温1
	IJNE	R60,4FH,para_T22
	IJNE	R61,DBH,para_T22
	LDWR	R0,1615H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1360H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	IJNE	R60,4FH,para_T22
	IJNE	R61,DBH,para_T22
	LDWR	R0,1615H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1560H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T22:;系统4防冻感温2
	IJNE	R60,4FH,para_T23
	IJNE	R61,DAH,para_T23
	LDWR	R0,1616H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1370H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	IJNE	R60,4FH,para_T23
	IJNE	R61,DAH,para_T23
	LDWR	R0,1616H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1570H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T23:;系统4防冻感温3
	IJNE	R60,4FH,para_T24
	IJNE	R61,D9H,para_T24
	LDWR	R0,1617H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1380H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T24:;系统4防冻感温4
	IJNE	R60,4FH,para_T25
	IJNE	R61,D8H,para_T25
	LDWR	R0,1618H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1390H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	para_T25:;系统1回气感温
	IJNE	R60,4FH,para_T26
	IJNE	R61,D7H,para_T26
	LDWR	R0,1619H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,13A0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	IJNE	R60,4FH,para_T26
	IJNE	R61,D7H,para_T26
	LDWR	R0,1619H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1580H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T26:;系统2回气感温
	IJNE	R60,4FH,para_T27
	IJNE	R61,D6H,para_T27
	LDWR	R0,161AH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,13B0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	IJNE	R60,4FH,para_T27
	IJNE	R61,D6H,para_T27
	LDWR	R0,161AH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1590H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T27:;系统3回气感温
	IJNE	R60,4FH,para_T28
	IJNE	R61,D5H,para_T28
	LDWR	R0,161BH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,13C0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	IJNE	R60,4FH,para_T28
	IJNE	R61,D5H,para_T28
	LDWR	R0,161BH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,15A0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	IJNE	R60,4FH,para_T28
	IJNE	R61,D5H,para_T28
	LDWR	R0,161BH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,17E0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
		
	para_T28:;系统4回气感温
	IJNE	R60,4FH,para_T29
	IJNE	R61,D4H,para_T29
	LDWR	R0,161CH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,13D0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	IJNE	R60,4FH,para_T29
	IJNE	R61,D4H,para_T29
	LDWR	R0,161CH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,15B0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T29:;系统1增焓进温度
	IJNE	R60,4FH,para_T30
	IJNE	R61,D3H,para_T30
	LDWR	R0,161DH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,13E0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	IJNE	R60,4FH,para_T30
	IJNE	R61,D3H,para_T30
	LDWR	R0,161DH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,15C0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	IJNE	R60,4FH,para_T30
	IJNE	R61,D3H,para_T30
	LDWR	R0,161DH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,17A0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T30:;系统2增焓进感温
	IJNE	R60,4FH,para_T31
	IJNE	R61,D2H,para_T31
	LDWR	R0,161EH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,13F0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T31:;系统3增焓进感温
	IJNE	R60,4FH,para_T32
	IJNE	R61,D1H,para_T32
	LDWR	R0,161FH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1400H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	para_T32:;系统4增焓进感温
	IJNE	R60,4FH,para_T33
	IJNE	R61,D0H,para_T33
	LDWR	R0,1620H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1410H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T33:;系统1增焓出感温
	IJNE	R60,4FH,para_T34
	IJNE	R61,CFH,para_T34
	LDWR	R0,1621H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1420H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T34:;系统2增焓出感温
	IJNE	R60,4FH,para_T35
	IJNE	R61,CEH,para_T35
	LDWR	R0,1622H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1430H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T35:;系统3增焓出感温
	IJNE	R60,4FH,para_T36
	IJNE	R61,CDH,para_T36
	LDWR	R0,1623H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1440H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T36:;系统4增焓出感温
	IJNE	R60,4FH,para_T37
	IJNE	R61,CCH,para_T37
	LDWR	R0,1624H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1450H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
		
	para_T37:;系统1排气感温
	IJNE	R60,4FH,para_T38
	IJNE	R61,CBH,para_T38
	LDWR	R0,1625H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1460H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T38:;系统2排气感温
	IJNE	R60,4FH,para_T39
	IJNE	R61,CAH,para_T39
	LDWR	R0,1626H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1470H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
		
	para_T39:;系统3排气感温
	IJNE	R60,4FH,para_T40
	IJNE	R61,C9H,para_T40
	LDWR	R0,1627H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1480H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T40:;系统4排气感温
	IJNE	R60,4FH,para_T45
	IJNE	R61,C8H,para_T45
	LDWR	R0,1628H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1490H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
;
;	para_T41:;系统1压缩机电流
;	IJNE	R60,4FH,para_T42
;	IJNE	R61,C7H,para_T42
;	LDWR	R0,1629H;故障图标
;	LDWR	R30,0001H
;	MOVXR	R30,0,1
;	LDWR	R0,14A0H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
;	
;	para_T42:;系统2压缩机电流
;	IJNE	R60,4FH,para_T43
;	IJNE	R61,C6H,para_T43
;	LDWR	R0,162AH;故障图标
;	LDWR	R30,0001H
;	MOVXR	R30,0,1
;	LDWR	R0,14B0H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
;	
;	para_T43:;系统3压缩机电流
;	IJNE	R60,4FH,para_T44
;	IJNE	R61,C5H,para_T44
;	LDWR	R0,162BH;故障图标
;	LDWR	R30,0001H
;	MOVXR	R30,0,1
;	LDWR	R0,14C0H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
;		
;	para_T44:;系统4压缩机电流
;	IJNE	R60,4FH,para_T45
;	IJNE	R61,C4H,para_T45
;	LDWR	R0,162CH;故障图标
;	LDWR	R30,0001H
;	MOVXR	R30,0,1
;	LDWR	R0,14D0H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
;	
	para_T45:;系统1压力
	IJNE	R60,4FH,para_T46
	IJNE	R61,C7H,para_T46
	LDWR	R0,162DH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,14E0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
	
	para_T46:;系统2压力
	IJNE	R60,4FH,para_T47
	IJNE	R61,C6H,para_T47
	LDWR	R0,162EH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,14F0H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
		
	para_T47:;系统3压力
	IJNE	R60,4FH,para_T48
	IJNE	R61,C5H,para_T48
	LDWR	R0,162FH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1500H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1

	IJNE	R60,4FH,para_T48
	IJNE	R61,C5H,para_T48
	LDWR	R0,162FH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1740H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
		
	para_T48:;系统4压力
	IJNE	R60,4FH,fault_para_display02_ret
	IJNE	R61,C4H,fault_para_display02_ret
	LDWR	R0,1630H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
	LDWR	R0,1510H
	MOVXR	R30,1,1
	LDWR	R30,FFFFH
	MOVXR	R30,0,1
			
 fault_para_display02_ret:
    RET
  
 
 nofault_para_display01:;无故障时的显示
	nopara_T01:;进水
	IJNE	R60,4FH,nopara_T02
	IJNE	R61,EFH,nopara_T02
	LDWR	R0,1601H ;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	
	LDWR	R0,1100H
	MOVXR	R30,1,1
	;LDWR	R30,07FDH	  ;lsz 12.3注销
	LDWR	R30,05B0H	  ;lsz 12.3添加
	MOVXR	R30,0,1

	LDWR	R0,1700H
	MOVXR	R30,1,1
	;LDWR	R30,07FDH	  ;lsz 12.3注销
	LDWR	R30,05B0H	  ;lsz 12.3添加
	MOVXR	R30,0,1  
	
	LDWR	R0,1640H
	MOVXR	R30,1,1
	;LDWR	R30,07FDH	  ;lsz 12.3注销
	LDWR	R30,05B0H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	LDWR	R0,1930H
	MOVXR	R30,1,1
	;LDWR	R30,07FDH	  ;lsz 12.3注销
	LDWR	R30,05B0H	  ;lsz 12.3添加
	MOVXR	R30,0,1
		
	LDWR	R0,1990H
	MOVXR	R30,1,1
	;LDWR	R30,07FDH	  ;lsz 12.3注销
	LDWR	R30,05B0H	  ;lsz 12.3添加
	MOVXR	R30,0,1

	;LDWR	R0,1750H
	LDWR	R0,16D0H	;LSZ 11.22添加
	MOVXR	R30,1,1
	;LDWR	R30,07FDH	  ;lsz 12.3注销
	LDWR	R30,05B0H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	LDWR	R0,1660H
	MOVXR	R30,1,1
	;LDWR	R30,07FDH	  ;lsz 12.3注销
	LDWR	R30,05B0H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	LDWR	R0,1780H
	MOVXR	R30,1,1
	;LDWR	R30,07FDH	  ;lsz 12.3注销
	LDWR	R30,05B0H	  ;lsz 12.3添加
	MOVXR	R30,0,1

	nopara_T02:;出水
	IJNE	R60,4FH,nopara_T04
	IJNE	R61,EEH,nopara_T04
	LDWR	R0,1602H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1110H
	MOVXR	R30,1,1
	;LDWR	R30,07FEH	  ;lsz 12.3注销
	LDWR	R30,05B1H	  ;lsz 12.3添加
	MOVXR	R30,0,1

	LDWR	R0,1710H
	MOVXR	R30,1,1
	;LDWR	R30,07FEH	  ;lsz 12.3注销
	LDWR	R30,05B1H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	LDWR	R0,1790H
	MOVXR	R30,1,1
	;LDWR	R30,07FEH	  ;lsz 12.3注销
	LDWR	R30,05B1H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	LDWR	R0,1650H
	MOVXR	R30,1,1
	;LDWR	R30,07FEH	  ;lsz 12.3注销
	LDWR	R30,05B1H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	LDWR	R0,1940H
	MOVXR	R30,1,1
	;LDWR	R30,07FEH	  ;lsz 12.3注销
	LDWR	R30,05B1H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	LDWR	R0,1980H
	MOVXR	R30,1,1
	;LDWR	R30,07FEH	  ;lsz 12.3注销
	LDWR	R30,05B1H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	;LDWR	R0,17B0H
	LDWR	R0,16E0H ;LSZ 11.22添加
	MOVXR	R30,1,1
	;LDWR	R30,07FEH	  ;lsz 12.3注销
	LDWR	R30,05B1H	  ;lsz 12.3添加
	MOVXR	R30,0,1

	LDWR	R0,1670H
	MOVXR	R30,1,1
	;LDWR	R30,07FEH	  ;lsz 12.3注销
	LDWR	R30,05B1H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T04:;系统1盘管
	IJNE	R60,4FH,nopara_T05
	IJNE	R61,ECH,nopara_T05
	LDWR	R0,1604H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1130H
	MOVXR	R30,1,1
	;LDWR	R30,0800H	  ;lsz 12.3注销
	LDWR	R30,05B3H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T05:;系统2盘管
	IJNE	R60,4FH,nopara_T06
	IJNE	R61,EBH,nopara_T06
	LDWR	R0,1605H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1140H
	MOVXR	R30,1,1
	;LDWR	R30,0801H	  ;lsz 12.3注销
	LDWR	R30,05B4H	  ;lsz 12.3添加
	MOVXR	R30,0,1

	nopara_T06:;系统3盘管
	IJNE	R60,4FH,nopara_T07
	IJNE	R61,EAH,nopara_T07
	LDWR	R0,1606H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1150H
	MOVXR	R30,1,1
	;LDWR	R30,0802H	  ;lsz 12.3注销
	LDWR	R30,05B5H	  ;lsz 12.3添加
	MOVXR	R30,0,1

	IJNE	R60,4FH,nopara_T07
	IJNE	R61,EAH,nopara_T07
	LDWR	R0,1606H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,15D0H
	MOVXR	R30,1,1
	;LDWR	R30,0802H	  ;lsz 12.3注销
	LDWR	R30,05B5H	  ;lsz 12.3添加
	MOVXR	R30,0,1

	nopara_T07:;系统4盘管
	IJNE	R60,4FH,nopara_T08
	IJNE	R61,E9H,nopara_T08
	LDWR	R0,1607H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1160H
	MOVXR	R30,1,1
	;LDWR	R30,0803H	  ;lsz 12.3注销
	LDWR	R30,05B6H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T08:;环境
	IJNE	R60,4FH,nopara_T09
	IJNE	R61,E8H,nopara_T09
	LDWR	R0,1608H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1170H
	MOVXR	R30,1,1
	;LDWR	R30,0804H	  ;lsz 12.3注销
	LDWR	R30,05B7H	  ;lsz 12.3添加
	MOVXR	R30,0,1

	LDWR	R0,1730H
	MOVXR	R30,1,1
	;LDWR	R30,0804H	  ;lsz 12.3注销
	LDWR	R30,05B7H	  ;lsz 12.3添加
	MOVXR	R30,0,1

	LDWR	R0,17C0H
	MOVXR	R30,1,1
	;LDWR	R30,0804H	  ;lsz 12.3注销
	LDWR	R30,05B7H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	; lsz 12.18添加
	LDWR	R0,640H			;92页
	MOVXR	R30,1,1
	LDWR	R30,05B7H		
	MOVXR	R30,0,1
	
	nopara_T09:;系统1防冻感温1
	IJNE	R60,4FH,nopara_T10
	IJNE	R61,E7H,nopara_T10
	LDWR	R0,1609H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1180H
	MOVXR	R30,1,1
	;LDWR	R30,0805H	  ;lsz 12.3注销
	LDWR	R30,05B8H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T10:;系统1防冻感温2
	IJNE	R60,4FH,nopara_T11
	IJNE	R61,E6H,nopara_T11
	LDWR	R0,160AH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1190H
	MOVXR	R30,1,1
	;LDWR	R30,0806H	  ;lsz 12.3注销
	LDWR	R30,05B9H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T11:;系统1防冻感温3
	IJNE	R60,4FH,nopara_T12
	IJNE	R61,E5H,nopara_T12
	LDWR	R0,160BH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,11A0H
	MOVXR	R30,1,1
	;LDWR	R30,0807H	  ;lsz 12.3注销
	LDWR	R30,05BAH	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T12:;系统1防冻感温4
	IJNE	R60,4FH,nopara_T13
	IJNE	R61,E4H,nopara_T13
	LDWR	R0,160CH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,11B0H
	MOVXR	R30,1,1
	;LDWR	R30,0808H	  ;lsz 12.3注销
	LDWR	R30,05BBH	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T13:;系统2防冻感温1
	IJNE	R60,4FH,nopara_T14
	IJNE	R61,E3H,nopara_T14
	LDWR	R0,160DH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,11C0H
	MOVXR	R30,1,1
	;LDWR	R30,0809H	  ;lsz 12.3注销
	LDWR	R30,05BCH	  ;lsz 12.3添加
	MOVXR	R30,0,1

	IJNE	R60,4FH,nopara_T14
	IJNE	R61,E3H,nopara_T14
	LDWR	R0,160DH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1520H
	MOVXR	R30,1,1
	;LDWR	R30,0809H	  ;lsz 12.3注销
	LDWR	R30,05BCH	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T14:;系统2防冻感温2
	IJNE	R60,4FH,nopara_T15
	IJNE	R61,E2H,nopara_T15
	LDWR	R0,160EH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,11D0H
	MOVXR	R30,1,1
	;LDWR	R30,080AH	  ;lsz 12.3注销
	LDWR	R30,05BDH	  ;lsz 12.3添加
	MOVXR	R30,0,1

	IJNE	R60,4FH,nopara_T15
	IJNE	R61,E2H,nopara_T15
	LDWR	R0,160EH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1530H
	MOVXR	R30,1,1
	;LDWR	R30,080AH	  ;lsz 12.3注销
	LDWR	R30,05BDH	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T15:;系统2防冻感温3
	IJNE	R60,4FH,nopara_T16
	IJNE	R61,E1H,nopara_T16
	LDWR	R0,160FH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,11E0H
	MOVXR	R30,1,1
	;LDWR	R30,080BH	  ;lsz 12.3注销
	LDWR	R30,05BEH	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T16:;系统2防冻感温4
	IJNE	R60,4FH,nofault_para_display01_ret
	IJNE	R61,E0H,nofault_para_display01_ret
	LDWR	R0,1610H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,11F0H
	MOVXR	R30,1,1
	;LDWR	R30,080CH	  ;lsz 12.3注销
	LDWR	R30,05BFH	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
  nofault_para_display01_ret:
    RET
    
  nofault_para_display02:
	nopara_T17:;系统3防冻感温1
	IJNE	R60,4FH,nopara_T18
	IJNE	R61,DFH,nopara_T18
	LDWR	R0,1611H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,19A0H
	MOVXR	R30,1,1
	;LDWR	R30,080DH	  ;lsz 12.3注销
	LDWR	R30,05C0H	  ;lsz 12.3添加
	MOVXR	R30,0,1

	IJNE	R60,4FH,nopara_T18
	IJNE	R61,DFH,nopara_T18
	LDWR	R0,1611H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1540H
	MOVXR	R30,1,1
	;LDWR	R30,080DH	  ;lsz 12.3注销
	LDWR	R30,05C0H	  ;lsz 12.3添加
	MOVXR	R30,0,1

	IJNE	R60,4FH,nopara_T18
	IJNE	R61,DFH,nopara_T18
	LDWR	R0,1611H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,17D0H
	MOVXR	R30,1,1
	;LDWR	R30,080DH	  ;lsz 12.3注销
	LDWR	R30,05C0H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T18:;系统3防冻感温2
	IJNE	R60,4FH,nopara_T19
	IJNE	R61,DEH,nopara_T19
	LDWR	R0,1612H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,19B0H
	MOVXR	R30,1,1
	;LDWR	R30,080EH	  ;lsz 12.3注销
	LDWR	R30,05C1H	  ;lsz 12.3添加
	MOVXR	R30,0,1

	IJNE	R60,4FH,nopara_T19
	IJNE	R61,DEH,nopara_T19
	LDWR	R0,1612H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1550H
	MOVXR	R30,1,1
	;LDWR	R30,080EH	  ;lsz 12.3注销
	LDWR	R30,05C1H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T19:;系统3防冻感温3
	IJNE	R60,4FH,nopara_T20
	IJNE	R61,DDH,nopara_T20
	LDWR	R0,1613H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,19C0H
	MOVXR	R30,1,1
	;LDWR	R30,080FH	  ;lsz 12.3注销
	LDWR	R30,05C2H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T20:;系统3防冻感温4
	IJNE	R60,4FH,nopara_T21
	IJNE	R61,DCH,nopara_T21
	LDWR	R0,1614H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1350H
	MOVXR	R30,1,1
	;LDWR	R30,0810H	  ;lsz 12.3注销
	LDWR	R30,05C3H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T21:;系统4防冻感温1
	IJNE	R60,4FH,nopara_T22
	IJNE	R61,DBH,nopara_T22
	LDWR	R0,1615H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1360H
	MOVXR	R30,1,1
	;LDWR	R30,0811H	  ;lsz 12.3注销
	LDWR	R30,05C4H	  ;lsz 12.3添加
	MOVXR	R30,0,1

	IJNE	R60,4FH,nopara_T22
	IJNE	R61,DBH,nopara_T22
	LDWR	R0,1615H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1560H
	MOVXR	R30,1,1
	;LDWR	R30,0811H	  ;lsz 12.3注销
	LDWR	R30,05C4H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T22:;系统4防冻感温2
	IJNE	R60,4FH,nopara_T23
	IJNE	R61,DAH,nopara_T23
	LDWR	R0,1616H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1370H
	MOVXR	R30,1,1
	;LDWR	R30,0812H	  ;lsz 12.3注销
	LDWR	R30,05C5H	  ;lsz 12.3添加
	MOVXR	R30,0,1

	IJNE	R60,4FH,nopara_T23
	IJNE	R61,DAH,nopara_T23
	LDWR	R0,1616H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1570H
	MOVXR	R30,1,1
	;LDWR	R30,0812H	  ;lsz 12.3注销
	LDWR	R30,05C5H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T23:;系统4防冻感温3
	IJNE	R60,4FH,nopara_T24
	IJNE	R61,D9H,nopara_T24
	LDWR	R0,1617H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1380H
	MOVXR	R30,1,1
	;LDWR	R30,0813H	  ;lsz 12.3注销
	LDWR	R30,05C6H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T24:;系统4防冻感温4
	IJNE	R60,4FH,nopara_T25
	IJNE	R61,D8H,nopara_T25
	LDWR	R0,1618H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1390H
	MOVXR	R30,1,1
	;LDWR	R30,0814H	  ;lsz 12.3注销
	LDWR	R30,05C7H	  ;lsz 12.3添加
	MOVXR	R30,0,1

	nopara_T25:;系统1回气感温
	IJNE	R60,4FH,nopara_T26
	IJNE	R61,D7H,nopara_T26
	LDWR	R0,1619H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,13A0H
	MOVXR	R30,1,1
	;LDWR	R30,0815H	  ;lsz 12.3注销
	LDWR	R30,05C8H	  ;lsz 12.3添加
	MOVXR	R30,0,1

	IJNE	R60,4FH,nopara_T26
	IJNE	R61,D7H,nopara_T26
	LDWR	R0,1619H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1580H
	MOVXR	R30,1,1
	;LDWR	R30,0815H	  ;lsz 12.3注销
	LDWR	R30,05C8H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T26:;系统2回气感温
	IJNE	R60,4FH,nopara_T27
	IJNE	R61,D6H,nopara_T27
	LDWR	R0,161AH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,13B0H
	MOVXR	R30,1,1
	;LDWR	R30,0816H	  ;lsz 12.3注销
	LDWR	R30,05C9H	  ;lsz 12.3添加
	MOVXR	R30,0,1

	IJNE	R60,4FH,nopara_T27
	IJNE	R61,D6H,nopara_T27
	LDWR	R0,161AH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1590H
	MOVXR	R30,1,1
	;LDWR	R30,0816H	  ;lsz 12.3注销
	LDWR	R30,05C9H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T27:;系统3回气感温
	IJNE	R60,4FH,nopara_T28
	IJNE	R61,D5H,nopara_T28
	LDWR	R0,161BH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,13C0H
	MOVXR	R30,1,1
	;LDWR	R30,0817H	  ;lsz 12.3注销
	LDWR	R30,05CAH	  ;lsz 12.3添加
	MOVXR	R30,0,1

	IJNE	R60,4FH,nopara_T28
	IJNE	R61,D5H,nopara_T28
	LDWR	R0,161BH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,15A0H
	MOVXR	R30,1,1
	;LDWR	R30,0817H	  ;lsz 12.3注销
	LDWR	R30,05CAH	  ;lsz 12.3添加
	MOVXR	R30,0,1

	IJNE	R60,4FH,nopara_T28
	IJNE	R61,D5H,nopara_T28
	LDWR	R0,161BH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,17E0H
	MOVXR	R30,1,1
	;LDWR	R30,0817H	  ;lsz 12.3注销
	LDWR	R30,05CAH	  ;lsz 12.3添加
	MOVXR	R30,0,1
		
	nopara_T28:;系统4回气感温
	IJNE	R60,4FH,nopara_T29
	IJNE	R61,D4H,nopara_T29
	LDWR	R0,161CH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,13D0H
	MOVXR	R30,1,1
	;LDWR	R30,0818H	  ;lsz 12.3注销
	LDWR	R30,05CBH	  ;lsz 12.3添加
	MOVXR	R30,0,1

	IJNE	R60,4FH,nopara_T29
	IJNE	R61,D4H,nopara_T29
	LDWR	R0,161CH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,15B0H
	MOVXR	R30,1,1
	;LDWR	R30,0818H	  ;lsz 12.3注销
	LDWR	R30,05CBH	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T29:;系统1增焓进温度
	IJNE	R60,4FH,nopara_T30
	IJNE	R61,D3H,nopara_T30
	LDWR	R0,161DH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,13E0H
	MOVXR	R30,1,1
	;LDWR	R30,0819H	  ;lsz 12.3注销
	LDWR	R30,05CCH	  ;lsz 12.3添加
	MOVXR	R30,0,1

	IJNE	R60,4FH,nopara_T30
	IJNE	R61,D3H,nopara_T30
	LDWR	R0,161DH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,15C0H
	MOVXR	R30,1,1
	;LDWR	R30,0819H	  ;lsz 12.3注销
	LDWR	R30,05CCH	  ;lsz 12.3添加
	MOVXR	R30,0,1

	IJNE	R60,4FH,nopara_T30
	IJNE	R61,D3H,nopara_T30
	LDWR	R0,161DH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,17A0H
	MOVXR	R30,1,1
	;LDWR	R30,0819H	  ;lsz 12.3注销
	LDWR	R30,05CCH	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T30:;系统2增焓进感温
	IJNE	R60,4FH,nopara_T31
	IJNE	R61,D2H,nopara_T31
	LDWR	R0,161EH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,13F0H
	MOVXR	R30,1,1
	;LDWR	R30,081AH	  ;lsz 12.3注销
	LDWR	R30,05CDH	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T31:;系统3增焓进感温
	IJNE	R60,4FH,nopara_T32
	IJNE	R61,D1H,nopara_T32
	LDWR	R0,161FH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1400H
	MOVXR	R30,1,1
	;LDWR	R30,081BH	  ;lsz 12.3注销
	LDWR	R30,05CEH	  ;lsz 12.3添加
	MOVXR	R30,0,1

	nopara_T32:;系统4增焓进感温
	IJNE	R60,4FH,nopara_T33
	IJNE	R61,D0H,nopara_T33
	LDWR	R0,1620H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1410H
	MOVXR	R30,1,1
	;LDWR	R30,081CH	  ;lsz 12.3注销
	LDWR	R30,05CFH	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T33:;系统1增焓出感温
	IJNE	R60,4FH,nopara_T34
	IJNE	R61,CFH,nopara_T34
	LDWR	R0,1621H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1420H
	MOVXR	R30,1,1
	;LDWR	R30,081DH	  ;lsz 12.3注销
	LDWR	R30,05D0H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T34:;系统2增焓出感温
	IJNE	R60,4FH,nopara_T35
	IJNE	R61,CEH,nopara_T35
	LDWR	R0,1622H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1430H
	MOVXR	R30,1,1
	;LDWR	R30,081EH	  ;lsz 12.3注销
	LDWR	R30,05D1H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T35:;系统3增焓出感温
	IJNE	R60,4FH,nopara_T36
	IJNE	R61,CDH,nopara_T36
	LDWR	R0,1623H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1440H
	MOVXR	R30,1,1
	;LDWR	R30,081FH	  ;lsz 12.3注销
	LDWR	R30,05D2H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T36:;系统4增焓出感温
	IJNE	R60,4FH,nopara_T37
	IJNE	R61,CCH,nopara_T37
	LDWR	R0,1624H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1450H
	MOVXR	R30,1,1
	;LDWR	R30,0820H	  ;lsz 12.3注销
	LDWR	R30,05D3H	  ;lsz 12.3添加
	MOVXR	R30,0,1
		
	nopara_T37:;系统1排气感温
	IJNE	R60,4FH,nopara_T38
	IJNE	R61,CBH,nopara_T38
	LDWR	R0,1625H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1460H
	MOVXR	R30,1,1
	;LDWR	R30,0821H	  ;lsz 12.3注销
	LDWR	R30,05D4H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T38:;系统2排气感温
	IJNE	R60,4FH,nopara_T39
	IJNE	R61,CAH,nopara_T39
	LDWR	R0,1626H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1470H
	MOVXR	R30,1,1
	;LDWR	R30,0822H	  ;lsz 12.3注销
	LDWR	R30,05D5H	  ;lsz 12.3添加
	MOVXR	R30,0,1
		
	nopara_T39:;系统3排气感温
	IJNE	R60,4FH,nopara_T40
	IJNE	R61,C9H,nopara_T40
	LDWR	R0,1627H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1480H
	MOVXR	R30,1,1
	;LDWR	R30,0823H	  ;lsz 12.3注销
	LDWR	R30,05D6H	  ;lsz 12.3添加
	MOVXR	R30,0,1
	
	nopara_T40:;系统4排气感温
	IJNE	R60,4FH,nopara_T45
	IJNE	R61,C8H,nopara_T45
	LDWR	R0,1628H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1490H
	MOVXR	R30,1,1
	;LDWR	R30,0824H	  ;lsz 12.3注销
	LDWR	R30,05D7H	  ;lsz 12.3添加
	MOVXR	R30,0,1
;
;	para_T41:;系统1压缩机电流
;	IJNE	R60,4FH,para_T42
;	IJNE	R61,C7H,para_T42
;	LDWR	R0,1629H;故障图标
;	LDWR	R30,0001H
;	MOVXR	R30,0,1
;	LDWR	R0,14A0H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
;	
;	para_T42:;系统2压缩机电流
;	IJNE	R60,4FH,para_T43
;	IJNE	R61,C6H,para_T43
;	LDWR	R0,162AH;故障图标
;	LDWR	R30,0001H
;	MOVXR	R30,0,1
;	LDWR	R0,14B0H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
;	
;	para_T43:;系统3压缩机电流
;	IJNE	R60,4FH,para_T44
;	IJNE	R61,C5H,para_T44
;	LDWR	R0,162BH;故障图标
;	LDWR	R30,0001H
;	MOVXR	R30,0,1
;	LDWR	R0,14C0H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
;		
;	para_T44:;系统4压缩机电流
;	IJNE	R60,4FH,para_T45
;	IJNE	R61,C4H,para_T45
;	LDWR	R0,162CH;故障图标
;	LDWR	R30,0001H
;	MOVXR	R30,0,1
;	LDWR	R0,14D0H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
;	
	nopara_T45:;系统1压力
	IJNE	R60,4FH,nopara_T46
	IJNE	R61,C7H,nopara_T46
	LDWR	R0,162DH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,14E0H
	MOVXR	R30,1,1
	LDWR	R30,0829H
	MOVXR	R30,0,1
	
	nopara_T46:;系统2压力
	IJNE	R60,4FH,nopara_T47
	IJNE	R61,C6H,nopara_T47
	LDWR	R0,162EH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,14F0H
	MOVXR	R30,1,1
	LDWR	R30,082AH
	MOVXR	R30,0,1
		
	nopara_T47:;系统3压力
	IJNE	R60,4FH,nopara_T48
	IJNE	R61,C5H,nopara_T48
	LDWR	R0,162FH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1500H
	MOVXR	R30,1,1
	LDWR	R30,0835H
	MOVXR	R30,0,1

	IJNE	R60,4FH,nopara_T48
	IJNE	R61,C5H,nopara_T48
	LDWR	R0,162FH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1740H
	MOVXR	R30,1,1
	LDWR	R30,0835H
	MOVXR	R30,0,1
		
	nopara_T48:;系统4压力
	IJNE	R60,4FH,nofault_para_display02_ret
	IJNE	R61,C4H,nofault_para_display02_ret
	LDWR	R0,1630H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
	LDWR	R0,1510H
	MOVXR	R30,1,1
	LDWR	R30,0836H
	MOVXR	R30,0,1
  nofault_para_display02_ret:
    RET 
    
	S09_display:
;	LDWR	R0,0415H;A14
;	MOVXR	R30,1,1
;	IJNE	R31,1,S09_NOT_DISPLAY
;	LDWR	R0,161EH
;	LDWR	R30,0
;	MOVXR	R30,0,1;161EH不显示图标
;	LDWR	R0,1900H
;	LDWR	R30,07E8H
;	MOVXR	R30,0,1;"断开"/"闭合"显示
;	LDWR	R0,1680H
;	MOVXR	R30,0,1
;	GOTO	S09_display_RET
;		
;	S09_NOT_DISPLAY:;S09需要显示”断开/闭合“
;	LDWR	R0,161EH
;	LDWR	R30,1
;	MOVXR	R30,0,1;161EH显示”无“
;	LDWR	R0,1900H
;	MOVXR	R30,1,1
;	LDBR	R30,FFH,1
;	MOVXR	R30,0,1;"断开"/"闭合"不显示
;	LDWR	R0,1680H
;	MOVXR	R30,0,1
;	S09_display_RET:
	RET
    
  
  MUTE_SET_CONTROL:    ;静音定时
	LDBR	R35,24,1
	LDBR	R36,0,1
	LDWR	R0,0430H
	MOVXR	R30,1,1
	LDWR	R0,0431H
	MOVXR	R32,1,1
	MOVXR	R36,1,1    
	
	CJNE	R30,R32,mute_picture;如果两个相等，那么不用管显示的事。
	CJNE	R31,R33,mute_picture
	
	GOTO	MUTE_SET_CONTROL_RET
	mute_picture:
	JS		R33,R31,mute_cycle_picture2
	
	mute_cycle_picture1:;   结束时间大于开始时间
	LDBR	R40,38H,1
	MOV  	R31,R41,1
	MOV		R40,R0,2
	LDWR	R42,0001H
	MOVXR	R42,0,1
	
	INC		R31,0,1
	
	JS		R31,R33,mute_cycle_picture1
	
	GOTO	MUTE_SET_CONTROL_RET
	
	mute_cycle_picture2: ;结束时间小于开始时间
	LDBR	R40,38H,1
	MOV  	R31,R41,1
	MOV		R40,R0,2
	LDWR	R42,0001H
	MOVXR	R42,0,1
	
	INC		R31,0,1
	
	JS		R31,R35,mute_cycle_picture2
	JS		R36,R33,mute_cycle_picture3
	
	mute_cycle_picture3:
	IJNE	R33,00H,1
	GOTO	MUTE_SET_CONTROL_RET;如果终止时间刚好在0点，那么0点对应的方块自然不会显示(按照我的排版这个方块一旦显示即表示从0到1点都是静音状态)。
	LDBR	R40,38H,1
	MOV  	R36,R41,1
	MOV		R40,R0,2
	LDWR	R42,0001H
	MOVXR	R42,0,1
	
	INC		R36,0,1
	
	JS		R36,R33,mute_cycle_picture3
	
	GOTO	MUTE_SET_CONTROL_RET
    
 MUTE_SET_CONTROL_RET:
    RET 
       
 
 MUTE_SET_CONTROL02:    ;静音定时
	LDBR	R35,24,1
	LDBR	R36,0,1
	LDWR	R0,04BFH   ; ******地址
	MOVXR	R30,1,1
	LDWR	R0,04C0H   ; ******地址  
	MOVXR	R32,1,1
	MOVXR	R36,1,1

	CJNE	R30,R32,mute_picture02;如果两个相等，那么不用管显示的事。
	CJNE	R31,R33,mute_picture02
	
	GOTO	MUTE_SET_CONTROL02_RET
	mute_picture02:
	JS		R33,R31,mute_cycle_picture02
	mute_cycle_picture01:        ;结束时间大于开始时间
	LDBR	R40,38H,1
	MOV  	R31,R41,1
	MOV		R40,R0,2
	LDWR	R42,0001H
	MOVXR	R42,0,1
	
	INC		R31,0,1
	
	JS		R31,R33,mute_cycle_picture01
	GOTO	MUTE_SET_CONTROL02_RET
	
	mute_cycle_picture02:   ;结束时间小于开始时间
	LDBR	R40,38H,1
	MOV  	R31,R41,1
	MOV		R40,R0,2
	LDWR	R42,0001H
	MOVXR	R42,0,1
	
	MOV     R33,R41,1
	LDWR	R42,0002H
	MOVXR	R42,0,1
	
	
	INC		R31,0,1
	INC     R33,0,1
	
	JS		R31,R35,mute_cycle_picture02
	JS		R36,R33,mute_cycle_picture03
		
	mute_cycle_picture03:
	IJNE	R33,00H,1
	GOTO	MUTE_SET_CONTROL02_RET;如果终止时间刚好在0点，那么0点对应的方块自然不会显示
	LDBR	R40,38H,1
	MOV  	R36,R41,1
	MOV		R40,R0,2
	LDWR	R42,0001H
	MOVXR	R42,0,1
	
	INC		R36,0,1
	
	JS		R36,R33,mute_cycle_picture03
	GOTO	MUTE_SET_CONTROL02_RET

 MUTE_SET_CONTROL02_RET:
    RET 
 
 
 
 
 
  Key_Handle:
     ;CALL Key_Clock_Return;
  	 CALL Key_Clear_Fault	
  	 CALL Key_Upload	
  	 CALL Key_Download 
  Key_Handle_RET:
     RET
     
  Key_Clock_Return:
     LDWR 	R0,171FH;   ********171FH为时钟界面返回保存按键地址
	 MOVXR 	R30,1,1
	 IJNE 	R31,1,Key_Clock_Return_RET;
	 LDWR 	R30,0
	 LDWR 	R0,171FH
	 MOVXR 	R30,0,1
	 CALL 	Clock_Save
  Key_Clock_Return_RET: 
     RET
     
  Clock_Save:;时钟设定保存0FFFH--101FH
	 LDWR 	R40,5AA5H
	 LDWR 	R0,0FFFH;故障头
	 MOVXR 	R40,0,1

	 LDBR 	R4,02H,1;加载用户数据库地址02 86 00 00到R4、R5、R6、R7:预留到02 86 00 FF
	 LDBR 	R5,86H,1  
	 LDBR 	R6,00H,1
	 LDBR 	R7,00H,1;
	 LDWR 	R0,0FFFH;(0FFFH-101FH)
	 MOVXL 	3,0022H;模式3--DGUS变量到用户数据库，22H个字长度,多覆盖几个,防止没保存	
 Clock_Save_RET:
    RET;   
     
 
 Clock_Recover:;上电恢复时钟设置0FFFH--101FH
	 LDBR 	R4,02H,1;加载用户数据库地址02 86 00 00到R4、R5、R6、R7--加一个故障头0x5A5AH
	 LDBR 	R5,86H,1
	 LDBR 	R6,00H,1
	 LDBR 	R7,00H,1
	 LDWR 	R0,0FFFH;(0FFFH--101FH)
	 MOVXL 	2,0022H;模式2--用户数据库到DGUS变量，22H个字长度

	 LDWR 	R0,0FFFH;判读故障头   ******test 11-07
	 MOVXR 	R40,1,1 
	 IJNE 	R41,A5H,Clock_Clean;判断是否符合故障头条件，不满足就清空----去除乱码
	 IJNE 	R40,5AH,Clock_Clean;判断是否符合故障头条件，不满足就清空----去除乱码
	
  Clock_Recover_RET:
     RET;
     
  Clock_Clean:
	LDBR 	R80,0,32;
	LDWR 	R140,0FFFH;;清除所有    ******test 11-07
	LDWR 	R176,1010H    
	cycle_clean_clock:
		MOV 	R140,R0,2
		MOVXR 	R80,0,16
		INC 	R140,1,0010H;一直到102E都被清空了
		JS 		R140,R176,cycle_clean_clock;这里是个清理循环
	CALL 	Clock_SAVE;保存
	
  Clock_Clean_RET:
     RET;
     
     
  Key_Clear_Fault:
     LDWR 	R0,0217H;    ********0271H为故障界面清除按键地址
	 MOVXR 	R30,1,1
	 IJNE 	R31,1,Key_Clear_Fault_Ret;判断键值，清空故障  
	 LDWR 	R30,0
	 LDWR 	R0,0217H
	 MOVXR 	R30,0,1
	 CALL 	Fault_Clean
  Key_Clear_Fault_Ret:
     RET;                  
     
  Key_Upload:
	LDWR	R0,0500H
	MOVXR	R30,1,1 
	IJNE	R31,01H,Key_Upload_RET;判断上传按键是否按下	
	
	;LDWR    R0,050AH
	LDWR    R0,05D8H		;LSZ 11.22改
	LDWR    R44,0001H
	MOVXR   R44,0,1    ;上传开始图标
		
	LDWR	R0,0BC3H
	MOVXR	R30,1,1
	IJNE	R31,00H,Upload_failed_timer;在主板完成读取所有参数之前不命令主板写参数过来
	
	IJNE	R238,0,timing1   ;如果没有下达过写命令，则先下达写命令，若已经下达，则计时
	LDWR	R0,0BC3H
	MOVXR	R32,1,1
	LDWR	R30,8000H
	OR      R32,R30,2
	MOVXR	R32,0,1      ;上电标志位置1，即让主板写过来
	LDBR	R238,1,1;已下达命令，不用 重复下达
		
	timing1:
	LDWR	R0,0BC3H
	MOVXR	R30,1,1
	LDWR	R34,0000H
	CJNE	R34,R30,Upload_failed_timer
	CJNE	R35,R31,Upload_failed_timer;如果标志位被清0，那么立即判断上传成功，如果标志位没有被清零，那么开始计时，计时满30s则判断失败
	CALL	Upload_Save
	
	GOTO	Key_Upload_RET	
	
	Upload_failed_timer:
	INC     R239,0,1
	IJNE	R239,150,Key_Upload_RET;延时30s，如果计时满30s标志位仍未清零，那么就宣告失败
	LDBR	R239,0,1
	;LDWR	R0,050AH     ;    宣告失败，调用上传失败图标显示 ****test12.03
	LDWR    R0,05D8H		;lsz  11.22改
	LDWR	R30,0003H
	MOVXR	R30,0,1
	
	LDBR	R30,59H,1;由不可操作的界面跳回可操作的界面   **************12.26  
	MOVRD	R30,04H,1
	                                                                                                                                                                                                                                                                 
	LDWR	R0,0500H      ;清除上传按键键值
	LDWR	R30,0000H
	MOVXR	R30,0,1
	
	LDBR	R238,00H,1;清除
    ;LDBR	R239,0,1
  Key_Upload_RET:
    RET 
  
  Upload_Save:;上传参数保存;没上传成功，这个函数是不会被调用的	    
	LDBR 	R4,02H,1;加载用户数据库地址02 87 00 00到R4、R5、R6、R7:预留到02 87 01 00
	LDBR 	R5,87H,1;用于通信部分的系统           参数保存 
	LDBR 	R6,00H,1
	LDBR 	R7,00H,1;
	LDWR 	R0,03F2H;ZSW/20160604;(03FAH;ZSW/20160604-04AEH;ZSW/20160604:每类参数预留20H)
	MOVXL 	3,1;20160617 模式3--DGUS变量到用户数据库，1个字长度:  *******test 11-07	。‘’‘’‘’‘’‘从未上传过的彩屏，这个地方的值肯定不是1001，只要连接了主板，03F2H的值必然为1001
	
	
	LDBR 	R4,02H,1;加载用户数据库地址02 87 00 00到R4、R5、R6、R7:预留到02 87 01 00
	LDBR 	R5,87H,1;用于通信部分的系统           参数保存 
	LDBR 	R6,00H,1
	LDBR 	R7,01H,1;
	LDWR 	R0,03FAH;ZSW/20160604;(03FAH;ZSW/20160604-04AEH;ZSW/20160604:每类参数预留20H)
	MOVXL 	3,73;20160617 模式3--DGUS变量到用户数据库，100H个字长度:  *******test 11-07
	
	LDBR 	R4,02H,1;加载用户数据库地址02 87 00 00到R4、R5、R6、R7:预留到02 87 01 00
	LDBR 	R5,87H,1;用于通信部分的系统           参数保存 
	LDBR 	R6,00H,1
	LDBR 	R7,4AH,1;
	LDWR 	R0,044DH;ZSW/20160604;(03FAH;ZSW/20160604-04AEH;ZSW/20160604:每类参数预留20H)
	MOVXL 	3,80;20160617 模式3--DGUS变量到用户数据库，100H个字长度:  *******test 11-07
	
	LDBR 	R4,02H,1;加载用户数据库地址02 87 00 00到R4、R5、R6、R7:预留到02 87 01 00
	LDBR 	R5,87H,1;用于通信部分的系统           参数保存 
	LDBR 	R6,00H,1
	LDBR 	R7,F4H,1;
	LDWR 	R0,04A7H;ZSW/20160604;(03FAH;ZSW/20160604-04AEH;ZSW/20160604:每类参数预留20H)
	MOVXL 	3,80;20160617 模式3--DGUS变量到用户数据库，100H个字长度:  *******test 11-07
	
	Upload_success:	
	LDBR	R40,10H,1;蜂鸣器
	MOVRD	R40,02H,1
	
	LDWR	R0,0500H;清除上传按键键值
	LDWR	R30,0000H   
	MOVXR	R30,0,1
;	LDWR	R0,050AH;根据此变量判断是否成功
	LDWR    R0,05D8H				;lsz  11.22 修改
	LDWR	R30,0002H
	MOVXR	R30,0,1
	
	LDBR	R238,00H,1;清除判断标志位
	
	LDBR	R239,0,1;清除计时
	
	LDBR	R30,59H,1;由不可操作的界面跳回可操作的界面   **************12.26
	MOVRD	R30,04H,1
 Upload_Save_RET:
    RET    
  
 Key_Download:
	LDWR	R0,0501H
	MOVXR	R30,1,1
	IJNE	R31,01H,Key_Download_RET;判断下载按键是否按下	
	
	LDWR    R0,050BH
	LDWR    R44,0001H
	MOVXR   R44,0,1 
	
	IJNE	R237,00H,timing2;如果未要求主板读参数，
	;<-20160617
	LDBR 	R4,02H,1;加载用户数据库地址02 87 00 00到R4、R5、R6、R7
	LDBR 	R5,87H,1
	LDBR 	R6,00H,1
	LDBR 	R7,00H,1
	LDWR 	R0,03F2H;(03F0H-04F0H:每类参数预留20H,预留8类参数的空间)
	MOVXL 	2,0001H;读取03EF的值，用于校验
	
	LDWR	R0,03F2H
	MOVXR	R30,1,1
	IJNE	R30,03H,2
	IJNE	R31,E9H,1
	GOTO	CRC_correct
	
	CALL	DOWNLOAD_FAILED;从未上传过就下载，校验错误，直接报失败。
	GOTO	Key_Download_RET
	
	CRC_correct:		
	CALL	Read_Uploaded_Date;在这里测出，当接两个彩屏时，下载触发后，偶而会在读数据库时导致彩屏重启,最后发现是这个函数中有连续两次读数据库的操作，所以后来把这两次操作拆分到两个函数中了。

;	LDBR	R20,20H,1;
;	MOVRD	R20,02H,1
;	
	LDWR  	R0,0BC3H;参数 改动标志位,标志位置1，
	LDWR  	R30,000EH ;           ********test 12.03
	MOVXR  	R30,0,1
	LDBR	R237,01H,1
	
	timing2:
	LDWR  	R0,0BC3H ; 参数改动标志位    
	MOVXR  	R30,1,1
	LDWR	R32,0000H
	CJNE	R31,R33,Download_fault_timer1;参数改动标志位全为0，代表主板已经读完，主板有65s的时间来完成读操作，如果65s内没完成读，那么就判断下载失败
	IJNE	R236,00H,timing3
	
	CALL	SYSTEM_PARA_CLEAN  ;先清除所有系统参数，接下来再置上电标志位为1，等着主板重新写回来。
	
	LDWR	R0,0BC3H
	MOVXR	R30,1,1
	LDWR	R34,8000H;上电标志位置1，要求主板写回来
	OR	    R30,R34,2
	MOVXR	R30,0,1
	LDBR	R236,01H,1	
	
	;CALL	SYSTEM_PARA_CLEAN
	
	timing3:
	LDWR  	R0,0BC3H  ;参数改动标志位
	MOVXR  	R30,1,1
	LDWR	R32,0000H
	CJNE	R30,R32,Download_fault_timer2;主板有20s的时间写回来，写不回来那么就判断失败
	
	CALL	SYSTEM_PARA_COMPARE
	
	LDBR	R236,00H,2;清除所有的判断标志位
	LDWR	R0,6FFAH;清除65s计时的值
	MOVXR	R236,0,1
	LDWR	R0,1311H;清除20s计时的值
	MOVXR	R236,0,1
	LDWR	R0,0501H
	MOVXR	R236,0,1;清除按键键值
	LDWR    R0,0506H
	MOVXR   R236,0,1
    
	GOTO	Key_Download_RET
	
	Download_fault_timer1:
	LDWR	R0,6FFAH
	MOVXR	R30,1,1
	INC	    R30,1,1
	MOVXR	R30,0,1
	LDWR	R32,0145H;325计数上限，对应65s
	JS	    R30,R32,Key_Download_RET
	
	CALL	DOWNLOAD_FAILED
	GOTO	Key_Download_RET
	
	Download_fault_timer2:
	LDWR	R0,1311H
	MOVXR	R30,1,1
	INC	    R30,1,1
	MOVXR	R30,0,1
	LDWR	R32,0064H   ;100计数上限，对应20s
	JS	    R30,R32,Key_Download_RET
	CALL	DOWNLOAD_FAILED	
	GOTO	Key_Download_RET
	
  Key_Download_RET:
    RET;  
  
  
  Read_Uploaded_Date:          ;读取已上传参数
	LDBR 	R4,02H,1;加载用户数据库地址02 87 00 00到R4、R5、R6、R7
	LDBR 	R5,87H,1
	LDBR 	R6,00H,1
	LDBR 	R7,01H,1
	LDWR 	R0,03FAH;ZSW/20160604;(03FAH;ZSW/20160604-04F0H:每类参数预留20H,预留8类参数的空间)
	MOVXL 	2,73;模式2--用户数据库到DGUS变量，
		;如果这里连续进行两次以上的操作，在连接两个彩屏时，可能会导致彩屏重启
	LDBR 	R4,02H,1;加载用户数据库地址02 87 00 00到R4、R5、R6、R7
	LDBR 	R5,87H,1
	LDBR 	R6,00H,1
	LDBR 	R7,4AH,1
	LDWR 	R0,044DH;ZSW/20160604;(03FAH;ZSW/20160604-04F0H:每类参数预留20H,预留8类参数的空间)
	MOVXL 	2,80;模式2--用户数据库到DGUS变量，
	
	LDBR 	R4,02H,1;加载用户数据库地址02 87 00 00到R4、R5、R6、R7
	LDBR 	R5,87H,1
	LDBR 	R6,00H,1
	LDBR 	R7,F4H,1
	LDWR 	R0,04A7H;ZSW/20160604;(03FAH;ZSW/20160604-04F0H:每类参数预留20H,预留8类参数的空间)
	MOVXL 	2,80;模式2--用户数据库到DGUS变量，
 Read_Uploaded_Date_RET:
    RET;

 SYSTEM_PARA_COMPARE:;比较主板写回来的值是否与数据库的值相同，相同则成功，不同则失败
 	LDBR 	R4,02H,1;加载用户数据库地址02 87 00 01到R4、R5、R6、R7
	LDBR 	R5,87H,1
	LDBR 	R6,00H,1
	LDBR 	R7,01H,1
	LDWR	R0,1200H
	MOVXL	2,73;数据库中的值转移到1200~1300中，用于后面和主板传递回来的值比较是否一致。

 	LDBR 	R4,02H,1;加载用户数据库地址02 87 00 01到R4、R5、R6、R7
	LDBR 	R5,87H,1
	LDBR 	R6,00H,1
	LDBR 	R7,4AH,1
	LDWR	R0,124AH
	MOVXL	2,80;数据库中的值转移到1200~1300中，用于后面和主板传递回来的值比较是否一致。

 	LDBR 	R4,02H,1;加载用户数据库地址02 87 00 01到R4、R5、R6、R7
	LDBR 	R5,87H,1
	LDBR 	R6,00H,1
	LDBR 	R7,F4H,1
	LDWR	R0,12F4H
	MOVXL	2,80;数据库中的值转移到1200~1300中，用于后面和主板传递回来的值比较是否一致。
	
	LDWR	R80,1200H;数据库中的值存储的变量地址
	LDWR	R82,1249H;
	LDWR	R84,03FAH;ZSW/20160604;主板写过来的值存储的变量地址
	LDWR	R86,0443H;ZSW/20160604
	para_cycle_compare:
	MOV		R80,R0,2
	MOVXR	R50,1,1 
	MOV		R84,R0,2
	MOVXR	R52,1,1
	CJNE	R50,R52,download_faild 
	CJNE	R51,R53,download_faild

	INC		R80,1,1
	INC		R84,1,1
	JS		R84,R86,para_cycle_compare
	
	LDWR	R80,124AH;数据库中的值存储的变量地址
	LDWR	R82,129AH;
	LDWR	R84,044DH;ZSW/20160604;主板写过来的值存储的变量地址
	LDWR	R86,049DH;ZSW/20160604
	para_cycle_compare1:
	MOV		R80,R0,2
	MOVXR	R50,1,1 
	MOV		R84,R0,2
	MOVXR	R52,1,1
	CJNE	R50,R52,download_faild 
	CJNE	R51,R53,download_faild

	INC		R80,1,1
	INC		R84,1,1
	JS		R84,R86,para_cycle_compare1	
	
	LDWR	R80,12F4H;数据库中的值存储的变量地址
	LDWR	R82,1344H;
	LDWR	R84,04A7H;ZSW/20160604;主板写过来的值存储的变量地址
	LDWR	R86,04F7H;ZSW/20160604
	para_cycle_compare2:
	MOV		R80,R0,2
	MOVXR	R50,1,1 
	MOV		R84,R0,2
	MOVXR	R52,1,1
	CJNE	R50,R52,download_faild
	CJNE	R51,R53,download_faild

	INC		R80,1,1
	INC		R84,1,1
	JS		R84,R86,para_cycle_compare2
	
	CALL	DOWNLOAD_SUCCEED
	GOTO	SYSTEM_PARA_COMPARE_RET
	
	download_faild:
	LDWR	R0,4000H;测试变量,一旦下载失败，可以读取4002和4001这两个变量，里面保存的是比较不相等的那两个变量
	MOVXR	R80,0,1
	LDWR	R0,4001H
	MOVXR	R84,0,1
	CALL    SYSTEM_PARA_RECOVER  ;系统参数恢复。如果下载失败，则恢复数据库保存的参数到系统参数中
	CALL	DOWNLOAD_FAILED 
	;GOTO	SYSTEM_PARA_COMPARE_RET
 SYSTEM_PARA_COMPARE_RET:
    RET
  
 DOWNLOAD_FAILED:  
	LDWR	R0,050BH
	LDWR	R44,0003H;3号图标，对应下载失败
	MOVXR	R44,0,1 
		
	LDBR	R236,00H,2;清除所有的判断标志位
	LDWR	R0,6FFAH;清除65s计时的值
	MOVXR	R236,0,1  
	LDWR	R0,1311H;清除20s计时的值
	MOVXR	R236,0,1
	LDWR	R0,0501H
	MOVXR	R236,0,1;清除按键键值
	
	LDWR	R80,0000H
	LDWR	R84,0000H
	
	LDBR	R30,5AH,1;由不可操作的界面跳回可操作的界面
	MOVRD	R30,04H,1
DOWNLOAD_FAILED_RET:
    RET

DOWNLOAD_SUCCEED:
	LDBR	R40,10H,1;蜂鸣器
	MOVRD	R40,02H,1

	LDWR	R0,050BH
	LDWR	R44,0002H;2号图标，对应下载成功
	MOVXR	R44,0,1
	
	LDBR	R236,00H,2;清除所有的判断标志位
	LDWR	R0,6FFAH;清除65s计时的值
	MOVXR	R236,0,1
	LDWR	R0,1311H;清除20s计时的值
	MOVXR	R236,0,1
	LDWR	R0,0501H
	MOVXR	R236,0,1;清除按键键值
	
	LDWR	R80,0000H
	LDWR	R84,0000H
	
	LDBR	R30,5AH,1;由不可操作的界面跳回可操作的界面
	MOVRD	R30,04H,1
	
	LDWR	R0,0BC3H;这是为了让主板广播到另一个屏，主板读了所有参数之后就会广播所有参数。
	LDWR	R30,000EH
	MOVXR	R30,0,1
 DOWNLOAD_SUCCEED_RET:
    RET  
  
 SYSTEM_PARA_CLEAN:;清空03F0H~04F0H
	LDBR	R50,00H,64       
	LDWR	R0,03FAH;
	MOVXR	R50,0,32
	LDWR	R0,041AH;
	MOVXR	R50,0,32
	LDWR	R0,043AH;
	MOVXR	R50,0,32
	LDWR	R0,0464H;
	MOVXR	R50,0,32
	LDWR	R0,0484H;
	MOVXR	R50,0,32
	LDWR	R0,04AEH;
   	MOVXR	R50,0,32
	LDWR	R0,04B0H
	MOVXR	R50,0,32
	LDWR	R0,04C0H
	MOVXR	R50,0,32
	LDWR	R0,04E0H
	MOVXR	R50,0,17
	
SYSTEM_PARA_CLEAN_RET:
    RET

SYSTEM_PARA_RECOVER:
	LDWR	R80,1200H;数据库中的值存储的变量地址
	LDWR	R82,1249H;
	LDWR	R84,03FAH;ZSW/20160604;主板写过来的值存储的变量地址
	LDWR	R86,0443H;ZSW/20160604
	para_cycle_recover:;循环语句执行赋值
	MOV		R80,R0,2
	MOVXR	R50,1,1
	MOV		R84,R0,2
	MOVXR	R50,0,1
	
	INC		R80,1,1
	INC		R84,1,1
	JS		R84,R86,para_cycle_recover
	
	LDWR	R80,124AH;数据库中的值存储的变量地址
	LDWR	R82,129AH;
	LDWR	R84,044DH;ZSW/20160604;主板写过来的值存储的变量地址
	LDWR	R86,049DH;ZSW/20160604
	para_cycle_recover1:;循环语句执行赋值
	MOV		R80,R0,2
	MOVXR	R50,1,1
	MOV		R84,R0,2
	MOVXR	R50,0,1
	
	INC		R80,1,1
	INC		R84,1,1
	JS		R84,R86,para_cycle_recover1	
	
	LDWR	R80,12F4H;数据库中的值存储的变量地址
	LDWR	R82,1344H;
	LDWR	R84,04A7H;ZSW/20160604;主板写过来的值存储的变量地址
	LDWR	R86,04F7H;ZSW/20160604
	para_cycle_recover2:;循环语句执行赋值
	MOV		R80,R0,2
	MOVXR	R50,1,1
	MOV		R84,R0,2
	MOVXR	R50,0,1
	
	INC		R80,1,1
	INC		R84,1,1
	JS		R84,R86,para_cycle_recover2
SYSTEM_PARA_RECOVER_RET:
    RET
        
  PageID_Handle:
     ;CALL Mode_Judge       ;主界面跳转  jh 20160408注销
     ;CALL Return_Judge    ;返回主界面跳转jh 2016040B注销
     ;CALL Curve_Judge		;jh 2016040B注销jh 2016040B注销
     ;CALL Fault_return		;jh 2016040B注销

     CALL Judge_Pressure   ;判断显示压力值界面
     CALL Judge_Defor
     CALL Judge_Fan        ;判断风机当前显示是交流或直流 
     CALL Judge_Fan1
     CALL Judge_EEV        ; 判断电子膨胀阀规格
     CALL Judge_EEV4
     CALL Judge_EEV5
     CALL Judge_Out1       ;判断状态输出显示
     CALL Judge_Out2
     CALL Judge_Out3
     CALL Judge_Out4
     CALL Judge_Out5
     CALL Judge_Out6
     CALL Judge_Out7
     CALL Judge_Out8
     CALL Judge_Out9
     CALL Judge_Out10
     CALL Judge_Out11
     CALL Judge_Out12
     CALL Judge_H06
     CALL TIMER1_jumping
  
  PageID_Handle_RET:
  RET					;lsz   11.22添加
  
  
;  Mode_Judge:
;     LDWR	R0,03F4H;当前模式
;  	 MOVXR	R30,1,1
;  	 MOVDR	04H,R40,1
;  	
;  	 IJNE   R31,00H,Hot_page
;     IJNE   R40,07H,3
;     LDBR   R44,05H,1
;     MOVRD  R44,04H,1 
;     GOTO   Mode_Judge_RET
;     
;     IJNE   R40,08H,Mode_Judge_RET
;     LDBR   R44,06H,1
;     MOVRD  R44,04H,1
;     GOTO   Mode_Judge_RET
;     
;  Hot_page:
;  	 IJNE   R31,01H,Mode_Judge_RET
;  	 IJNE   R40,05H,3
;  	 LDBR   R44,07H,1
;  	 MOVRD  R44,04H,1        
;     GOTO   Mode_Judge_RET
;     
;     IJNE   R40,06H,Mode_Judge_RET
;     LDBR   R44,08H,1
;     MOVRD  R44,04H,1     
;     GOTO   Mode_Judge_RET
;  Mode_Judge_RET:
;     RET
;  
;  Return_Judge:
;    MOVDR  04H,R40,1
;    
;    IJNE   R40,14,Return_Judge_RET
;    LDWR   R0,0304H
;    MOVXR  R38,1,1
;    
;    IJNE   R39,01,Return_Judge_RET   
;    LDWR   R0,0300H
;    MOVXR  R30,1,1; 1-第5页   2-第6页 3-第7页   4-第8页
;    LDWR   R0,0301H
;    MOVXR  R32,1,1; 第6页
;    LDWR   R0,0302H
;    MOVXR  R34,1,1; 第7页
;    LDWR   R0,0303H        
;    MOVXR  R36,1,1; 第8页
;    
;    IJNE   R31,01,next_page01
;    LDBR   R44,05H,1
;    MOVRD  R44,04H,1
;    LDWR   R46,0000H
;    LDWR   R0,0300H
;    MOVXR  R46,0,1
;    LDWR   R0,0304H
;    MOVXR  R46,0,1
;    GOTO   Return_Judge_RET
;    
;    next_page01:
;    IJNE   R33,01,next_page02
;    LDBR   R44,06H,1
;    MOVRD  R44,04H,1
;    LDWR   R46,0000H
;    LDWR   R0,0301H
;    MOVXR  R46,0,1
;    LDWR   R0,0304H
;    MOVXR  R46,0,1
;    GOTO   Return_Judge_RET
;    
;    next_page02:
;    
;    IJNE   R35,01,next_page03
;    LDBR   R44,07H,1
;    MOVRD  R44,04H,1
;    LDWR   R46,0000H
;    LDWR   R0,0302H
;    MOVXR  R46,0,1
;    LDWR   R0,0304H
;    MOVXR  R46,0,1
;    GOTO   Return_Judge_RET
;      
;    next_page03: 
;    IJNE   R37,01,Return_Judge_RET    
;    LDBR   R44,08H,1
;    MOVRD  R44,04H,1    
;    LDWR   R46,0000H
;    LDWR   R0,0303H
;    MOVXR  R46,0,1
;    LDWR   R0,0304H
;    MOVXR  R46,0,1
;    
;  Return_Judge_RET:
;    RET
;   
;  Curve_Judge:;从曲线界面跳回主界面
;    MOVDR  04H,R40,1
;    LDWR   R0,0306H
;    MOVXR  R30,1,1; 1-第5页   2-第6页 3-第7页   4-第8页
;    LDWR   R0,03F4H
;    MOVXR  R32,1,1
;    LDWR   R0,2060H
;    MOVXR  R34,1,1
;    
;;   IJNE   R40,05H,Curve_Judge_RET
;    IJNE   R35,3DH,Curve_Judge_RET
;    LDWR   R36,0001H
;    LDWR   R0,2060H
;    MOVXR  R36,0,1
;    
;    IJNE   R33,0,Hot_Judge    
;    IJNE   R31,00,1
;    GOTO   curve_page01
;    IJNE   R31,01,1
;    GOTO   curve_page02
;    
;    Hot_Judge:
;    IJNE   R31,00,1
;    GOTO   curve_page03
;    IJNE   R31,01,1
;    GOTO   curve_page04  
;    
;    GOTO   Curve_Judge_RET
;    
;    curve_page01: 
;    LDBR   R44,05H,1
;    MOVRD  R44,04H,1      
;    GOTO   Curve_Judge_RET
;    
;    curve_page02: 
;    LDBR   R44,06H,1
;    MOVRD  R44,04H,1
;    GOTO   Curve_Judge_RET
;    
;    curve_page03: 
;    LDBR   R44,07H,1
;    MOVRD  R44,04H,1 
;
;    GOTO   Curve_Judge_RET
;      
;    curve_page04:   
;    LDBR   R44,08H,1
;    MOVRD  R44,04H,1 
;    
;  Curve_Judge_RET:
;    RET 
;   
;  Fault_return:
;    MOVDR  04H,R40,1
;   
;    IJNE   R40,14,Fault_return_RET
;    LDWR   R0,0304H
;    MOVXR  R38,1,1
;    
;    IJNE   R39,01,Fault_return_RET
;    LDWR   R0,030BH
;    MOVXR  R30,1,1; 1-第5页   2-第6页 3-第7页   4-第8页
;    LDWR   R0,030CH
;    MOVXR  R32,1,1; 第6页
;    LDWR   R0,030DH
;    MOVXR  R34,1,1; 第7页
;    LDWR   R0,030EH
;    MOVXR  R36,1,1; 第8页
;    
;    IJNE   R31,01,fault_page01
;    LDWR   R46,0000H
;    LDWR   R0,030BH
;    MOVXR  R46,0,1
;    LDWR   R0,0304H
;    MOVXR  R46,0,1
;    LDBR   R44,05H,1
;    MOVRD  R44,04H,1    
;    GOTO   Fault_return_RET
;    
;    fault_page01:
;    IJNE   R33,01,fault_page02 
;    LDWR   R46,0000H
;    LDWR   R0,030CH
;    MOVXR  R46,0,1
;    LDWR   R0,0304H
;    MOVXR  R46,0,1
;    LDBR   R44,06H,1
;    MOVRD  R44,04H,1
;    
;    GOTO   Fault_return_RET
;    
;    fault_page02:    
;    IJNE   R35,01,fault_page03
;    LDWR   R46,0000H
;    LDWR   R0,030DH
;    MOVXR  R46,0,1
;    LDWR   R0,0304H
;    MOVXR  R46,0,1
;    LDBR   R44,07H,1
;    MOVRD  R44,04H,1    
;    GOTO   Fault_return_RET
;      
;    fault_page03: 
;    IJNE   R37,01,Fault_return_RET  
;    LDWR   R46,0000H
;    LDWR   R0,030EH
;    MOVXR  R46,0,1
;    LDWR   R0,0304H
;    MOVXR  R46,0,1
;    LDBR   R44,08H,1
;    MOVRD  R44,04H,1 
;  
;  Fault_return_RET:
;     RET 
     
 主界面开关机:
	 MOVDR	04H,R40,1;只要在主界面，就会判断8个主界面到底该显示哪一个
	 IJNE	R40,5,1
	 GOTO	在主界面
	 IJNE	R40,6,1
	 GOTO	在主界面
	 IJNE	R40,7,1
	 GOTO	在主界面
	 IJNE	R40,8,1
	 GOTO	在主界面
	 IJNE	R40,108,1
	 GOTO	在主界面
	 IJNE	R40,109,1
	 GOTO	在主界面
	 IJNE	R40,110,1
	 GOTO	在主界面
	 IJNE	R40,111,主界面开关机_RET
	 GOTO	在主界面
	 
	 在主界面:
	 LDWR	R0,03F3H
	 MOVXR	R30,1,1
	 IJNE	R31,0,开机状态
	 ;关机状态:
	 LDWR	R0,03F4H
	 MOVXR	R30,1,1
	 IJNE	R31,0,制热_关
	 ;制冷_关:
	 LDWR	R0,0306H
	 MOVXR	R30,1,1
	 IJNE	R31,1,回水_关
	 ;供水_关:
	 LDBR	R40,109,1
	 MOVRD	R40,04H,1
	 GOTO	主界面开关机_RET
	 回水_关:
	 LDBR	R40,108,1
	 MOVRD	R40,04H,1
	 GOTO	主界面开关机_RET
	 
	 制热_关:
	 LDWR	R0,0306H
	 MOVXR	R30,1,1
	 IJNE	R31,1,制热回水_关
	 ;供水:
	 LDBR	R40,111,1
	 MOVRD	R40,04H,1
	 GOTO	主界面开关机_RET
	 制热回水_关:
	 LDBR	R40,110,1
	 MOVRD	R40,04H,1
	 GOTO	主界面开关机_RET
	 
	 
	 开机状态:
	 LDWR	R0,03F4H
	 MOVXR	R30,1,1
	 IJNE	R31,0,制热
	 ;制冷:
	 LDWR	R0,0306H
	 MOVXR	R30,1,1
	 IJNE	R31,1,回水
	 ;供水:
	 LDBR	R40,6,1
	 MOVRD	R40,04H,1
	 GOTO	主界面开关机_RET
	 回水:
	 LDBR	R40,5,1
	 MOVRD	R40,04H,1
	 GOTO	主界面开关机_RET
	 
	 制热:
	 LDWR	R0,0306H
	 MOVXR	R30,1,1
	 IJNE	R31,1,制热回水
	 ;供水:
	 LDBR	R40,8,1
	 MOVRD	R40,04H,1
	 GOTO	主界面开关机_RET
	 制热回水:
	 LDBR	R40,7,1
	 MOVRD	R40,04H,1
	 GOTO	主界面开关机_RET
	 
 
 主界面开关机_RET:
 	RET
     
    
   Judge_Pressure:            ;*********TEST 11.20 wxm  
    LDWR   R0,0419H;判断是否启用压力传感器    A11参数
    MOVXR  R30,1,1;
    MOVDR  04H,R40,1;判断当前页面  
    
    IJNE   R31,1,Judge_Pressure_RET;为1则显示压力界面   ************wxm   2015-12-16 
    IJNE   R40,96,Judge_Pressure_RET
    LDBR   R44,25,1
    MOVRD  R44,04H,1
    
  Judge_Pressure_RET:
     RET
     
  Judge_Defor:
    LDWR   R0,0419H;判断是否启用压力传感器    A11参数
    MOVXR  R30,1,1
    MOVDR  04H,R40,1;判断当前页面
    
    IJNE   R31,01H,Judge_Defor_RET;为1则显示压力界面
    IJNE   R40,42,2;除霜参数
    LDBR   R44,43,1
    MOVRD  R44,04H,1
    
    ;next_Def1:
    IJNE   R40,44,2;除霜参数
    LDBR   R44,45,1
    MOVRD  R44,04H,1
    ;GOTO   Judge_Defor_RET
        
    IJNE   R40,61,Judge_Defor_RET; 客户参数
    LDBR   R44,62,1
    MOVRD  R44,04H,1
    
  Judge_Defor_RET:
     RET
    
  Judge_Fan:
    LDWR   R0,043AH;判断风机调速方式
    MOVXR  R30,1,1;
    LDWR   R0,0419H;压力传感器
    MOVXR  R32,1,1;
    MOVDR  04H,R40,1;判断当前页面
   
   	IJNE   R33,1,Judge_Fan_out;为1则启用压力传感器
    IJNE   R31,1,Judge_Fan_next;为1则显示压力调速
    IJNE   R40,30,Judge_Fan_RET
    LDBR   R44,31,1
    MOVRD  R44,04H,1
    GOTO   Judge_Fan_RET
    
  Judge_Fan_next:
  	IJNE   R40,31,Judge_Fan_RET
    LDBR   R44,30,1
    MOVRD  R44,04H,1
    
  Judge_Fan_RET:
    RET   
 
 Judge_Fan_out:
 	LDWR   R0,043AH;判断风机调速方式
 	LDWR   R30,0000H
    MOVXR  R30,0,1;
	RET 
	
;  Judge_Fan1: 
;  	MOVDR  04H,R40,1
;  	IJNE   R40,32,Judge_Fan1_RET;判断当前页面，在32页才进行判断
;  	
;    LDWR   R0,03F4H;判断是否卸载
;    MOVXR  R30,1,1;  
;    IJNE   R31,0,风机卸载;为0则表示不卸载
;    
;    LDWR   R0,042DH;判断风机参数
;    MOVXR  R30,1,1;
;    IJNE   R31,0,直流风机不卸载;为0则表示单速风机
;    
;    IJNE   R40,32,Judge_Fan1_RET;
;    
;    LDWR   R0,043AH;判断风机调速方式
;    MOVXR  R30,1,1;
;    IJNE   R31,1,3;为1则显示压力调速
;    LDBR   R44,31,1
;    MOVRD  R44,04H,1;
;    GOTO   Judge_Fan1_RET
;    
;    LDBR   R44,124,1
;    MOVRD  R44,04H,1;单速风机不卸载跳转124
;    GOTO   Judge_Fan1_RET
; 
; 直流风机不卸载:
; 	GOTO   Judge_Fan1_RET
; 	
; 风机卸载:
; 	LDWR   R0,0419H;判断启用压力传感器
;    MOVXR  R30,1,1;
; 	IJNE   R31,1,环温卸载;为1则显示压力调速
; 	
;    LDWR   R0,042DH;判断风机参数
;    MOVXR  R30,1,1; 
;    IJNE   R31,0,直流风机压力卸载;为0则表示单速风机
;    
;    IJNE   R40,32,Judge_Fan1_RET;
;    LDBR   R44,113,1
;    MOVRD  R44,04H,1;单速风机压力卸载跳转113页
;    GOTO   Judge_Fan1_RET 	
;    
;直流风机压力卸载:
;	IJNE   R40,32,Judge_Fan1_RET;
;    LDBR   R44,33,1
;    MOVRD  R44,04H,1;直流风机压力卸载跳转33页
;    GOTO   Judge_Fan1_RET 	
;	    
;环温卸载:
;    LDWR   R0,042DH;判断风机参数
;    MOVXR  R30,1,1;   
;    IJNE   R31,0,直流风机环温卸载;为0则表示单速风机
;    
;    IJNE   R40,32,Judge_Fan1_RET;
;    LDBR   R44,112,1
;    MOVRD  R44,04H,1;单速风机环温卸载跳转112页
;    GOTO   Judge_Fan1_RET 	    
;    
;直流风机环温卸载:
;    IJNE   R40,32,Judge_Fan1_RET
;    LDBR   R44,34,1
;    MOVRD  R44,04H,1;直流风机环温卸载跳转34页
;    GOTO   Judge_Fan1_RET 	
;    
; Judge_Fan1_RET:
;    RET 
  
Judge_Fan1:
	MOVDR	04H,R40,1
	IJNE	R40,32,Judge_Fan1_RET;在32页才判断是否跳转
	LDWR	R0,042DH;F01
	MOVXR	R30,1,1
	IJNE	R31,0,是否交流风机;单速风机有卸载
	LDWR	R0,0419H;A11
	MOVXR	R32,1,1
	IJNE	R33,0,压力卸载;为1则是压力卸载，为0是环温卸载
	LDBR	R40,112,1
	MOVRD	R40,04H,1
	GOTO	Judge_Fan1_RET
	
	压力卸载:
	LDBR	R40,113,1
	MOVRD	R40,04H,1	
	GOTO	Judge_Fan1_RET
   	
	是否交流风机:
	IJNE	R31,2,Judge_Fan1_RET;是则调到交流风机参数页，否则为直流风机不跳转
   	LDBR	R40,33,1
   	MOVRD	R40,04H,1
   	
Judge_Fan1_RET:
    RET 
    
  
Judge_EEV:
 	MOVDR  04H,R40,1
  	IJNE   R40,47,Judge_EEV1;判断当前页面，在47页才进行判断
  	LDWR   R0,0483H;判断电子膨胀阀规格
    MOVXR  R30,1,1;   
    IJNE   R31,1,Judge_EEV_RET;为1则表示2000N
    LDBR   R44,48,1
    MOVRD  R44,04H,1;2000N在48页
    GOTO	Judge_EEV_RET
Judge_EEV_RET:

Judge_EEV1:

Judge_EEV1_RET:

Judge_EEV2:
	MOVDR  04H,R40,1  
;   	IJNE   R40,50,Judge_EEV2_RET;判断当前页面，在50页才进行判断
;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;lsz 12.21 注销
;	IJNE   R40,52,Judge_EEV2_RET;判断当前页面，在52页才进行判断
;   	LDWR   R0,047FH;判断是否启用增焓
;    MOVXR  R30,1,1;   
;    IJNE   R31,0,Judge_EEV2_NEXT;为0则表示不启用  
;    LDBR   R44,49,1
;    MOVRD  R44,04H,1;不启用不允许跳转
;;;;;;;;;;;;;;;;;;;;;

;;;;lsz 12.21 添加
	IJNE	R40,49,Judge_EEV2_RET;判断当前页面，在52页才进行判断
	    LDWR    R0,047FH;判断是否启用增焓
	    MOVXR   R30,1,1
	    IJNE    R31,0,1;为0表示不启用
	        GOTO    clearFlag49
	    LDWR    R0,0655H	;52下一页标志位
	   	MOVXR	R32,1,1
	    IJNE	R33,1,Judge_EEV2_NEXT
	        LDWR	R44,52
	        MOVRD	R44,03H,2
	    	clearFlag49:
	    	LDWR    R34,0000H
	    	LDWR    R0,0655H		;52下一页标志位
	   		MOVXR   R34,0,1	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    GOTO	Judge_EEV2_RET 
Judge_EEV2_NEXT:   
;   	LDWR   R0,0483H;判断电子膨胀阀规格
;    MOVXR  R30,1,1;   
;    IJNE   R31,1,Judge_EEV2_RET;为1则表示2000N
;    LDBR   R44,50,1
;    MOVRD  R44,04H,1;2000N在50页
    GOTO	Judge_EEV2_RET  
Judge_EEV2_RET:
 	
Judge_EEV3:
	MOVDR  04H,R40,1
   	IJNE   R40,114,Judge_EEV3_RET;判断当前页面，在114页才进行判断
;Judge_EEV3_CHECK:  	
   	LDWR   R0,047FH;判断是否启用增焓
    MOVXR  R30,1,1;   
    IJNE   R31,0,Judge_EEV3_NEXT;为0则表示不启用  
    LDBR   R44,64,1
    MOVRD  R44,04H,1;不启用不允许跳转
    GOTO   Judge_EEV3_RET 
Judge_EEV3_NEXT:    
;   	LDWR   R0,0483H;判断电子膨胀阀规格
;    MOVXR  R30,1,1;   
;    IJNE   R31,1,Judge_EEV3_RET;为1则表示2000N
;    LDBR   R44,115,1
;    MOVRD  R44,04H,1;2000N在115页
    GOTO	Judge_EEV3_RET  
;Judge_EEV3_NEXT: 
;   	IJNE   R40,115,Judge_EEV3_RET;判断当前页面，在115页才进行判断
;  	GOTO   Judge_EEV3_CHECK 
Judge_EEV3_RET:
 	RET	
 	
Judge_EEV4:
    LDWR   R0,16A0H;判断是否在64页返回
    MOVXR  R30,1,1;   
    IJNE   R31,1,Judge_EEV4_RET;为1则表示正在返回  	
    
   	LDWR   R0,047FH;判断是否启用增焓
    MOVXR  R30,1,1;   
    IJNE   R31,0,Judge_EEV4_NEXT;为0则表示不启用    
    LDBR   R44,63,1
    MOVRD  R44,04H,1;不启用增焓返回63页
    LDWR   R0,16A0H;
    LDWR   R30,0000H;
    MOVXR  R30,0,1;
    GOTO	Judge_EEV4_RET  
    
Judge_EEV4_NEXT:
   	LDWR   R0,0483H;判断电子膨胀阀规格
    MOVXR  R30,1,1;   
    IJNE   R31,0,3;为0则表示500N   
	LDBR   R44,114,1
    MOVRD  R44,04H,1;500N启用增焓返回114页
    CALL   Judge_EEV4_NEXT1
 	LDBR   R44,114,1
    MOVRD  R44,04H,1;2000N启用增焓返回115页   
Judge_EEV4_NEXT1:    
    LDWR   R0,16A0H;
    LDWR   R30,0000H;
    MOVXR  R30,0,1;
Judge_EEV4_RET:
 	RET		

Judge_EEV5:
   	LDWR   R0,047FH;判断是否启用增焓
    MOVXR  R30,1,1;   
    IJNE   R31,0,Judge_EEV5_NEXT;为0则表示不启用 	 
    
    MOVDR  04H,R40,1
   	IJNE   R40,69,2;判断当前页面，在69页才进行判断  
   	LDBR   R44,70,1
    MOVRD  R44,04H,1;不启用增焓返回70页
    
    LDWR   R0,0314H;判断是否已屏蔽
    MOVXR  R30,1,1;   
    IJNE   R31,0,Judge_EEV4_RET;为0则表示未屏蔽    
    LDWR   R30,0001H;
    MOVXR  R30,0,1;     
    
    ;系统1增焓进温度
	LDWR	R0,401DH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
;	LDWR	R0,161DH;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,13E0H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
;
;	LDWR	R0,401DH;故障图标
;	LDWR	R30,0001H
;	MOVXR	R30,0,1
;	LDWR	R0,15C0H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1

;	LDWR	R0,401DH;故障图标
;	LDWR	R30,0001H
;	MOVXR	R30,0,1
;	LDWR	R0,17A0H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
	
	;系统2增焓进感温
	LDWR	R0,401EH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
;	LDWR	R0,161EH;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,13F0H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
	
	:;系统3增焓进感温
	LDWR	R0,401FH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
;	LDWR	R0,161FH;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,1400H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1

	;系统4增焓进感温
	LDWR	R0,4020H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
;	LDWR	R0,1620H;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,1410H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
	
	;系统1增焓出感温
	LDWR	R0,4021H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
;	LDWR	R0,1621H;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,1420H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
	
	;系统2增焓出感温
	LDWR	R0,4022H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
;	LDWR	R0,1622H;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,1430H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
	
	;系统3增焓出感温
	LDWR	R0,4023H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
;	LDWR	R0,1623H;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,1440H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
	
	;系统4增焓出感温
	LDWR	R0,4024H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
;	LDWR	R0,1624H;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,1450H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1

	GOTO 	Judge_EEV5_RET
Judge_EEV5_NEXT:
	LDWR   R0,0314H;判断是否已屏蔽
    MOVXR  R30,1,1;   
    IJNE   R31,1,Judge_EEV5_RET;为1则表示已屏蔽    
    LDWR   R30,0000H;
    MOVXR  R30,0,1;  
    ;系统1增焓进温度
	LDWR	R0,401DH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
;	LDWR	R0,13E0H
;	MOVXR	R30,1,1
;	LDWR	R30,0819H
;	MOVXR	R30,0,1
;
;	LDWR	R0,401DH;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,15C0H
;	MOVXR	R30,1,1
;	LDWR	R30,0819H
;	MOVXR	R30,0,1
;
;	LDWR	R0,401DH;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,17A0H
;	MOVXR	R30,1,1
;	LDWR	R30,0819H
;	MOVXR	R30,0,1
	
	;系统2增焓进感温
	LDWR	R0,401EH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
;	LDWR	R0,13F0H
;	MOVXR	R30,1,1
;	LDWR	R30,081AH
;	MOVXR	R30,0,1
	
	;系统3增焓进感温
	LDWR	R0,401FH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
;	LDWR	R0,1400H
;	MOVXR	R30,1,1
;	LDWR	R30,081BH
;	MOVXR	R30,0,1

	;系统4增焓进感温
	LDWR	R0,4020H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
;	LDWR	R0,1410H
;	MOVXR	R30,1,1
;	LDWR	R30,081CH
;	MOVXR	R30,0,1
	
	;系统1增焓出感温
	LDWR	R0,4021H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
;	LDWR	R0,1420H
;	MOVXR	R30,1,1
;	LDWR	R30,081DH
;	MOVXR	R30,0,1
	
	;系统2增焓出感温
	LDWR	R0,4022H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
;	LDWR	R0,1430H
;	MOVXR	R30,1,1
;	LDWR	R30,081EH
;	MOVXR	R30,0,1
	
	;系统3增焓出感温
	LDWR	R0,4023H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
;	LDWR	R0,1440H
;	MOVXR	R30,1,1
;	LDWR	R30,081FH
;	MOVXR	R30,0,1
	
	;系统4增焓出感温
	LDWR	R0,4024H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
;	LDWR	R0,1450H
;	MOVXR	R30,1,1
;	LDWR	R30,0820H
;	MOVXR	R30,0,1
	
Judge_EEV5_RET:
 	RET	
 	
  Judge_Out1:
    MOVDR  04H,R40,1
    IJNE   R40,65,Judge_Out1_RET;是否在65页
    
    LDWR   R0,0401H;  判断机型参数
    MOVXR  R30,1,1;
	IJNE   R31,0,Judge_Out1_RET;为0则表示冷热水机
	
    LDBR   R44,66,1
    MOVRD  R44,04H,1;冷热水机显示热源侧水泵
    GOTO   Judge_Out1_RET 
  Judge_Out1_RET:
     RET             
   
  Judge_Out2:
    LDWR   R0,0400H;  判断模式参数
    MOVXR  R30,1,1;
	IJNE   R31,0,Judge_Out2_NEXT;为0则表示单冷 
	LDWR   R0,03F4H;
	LDWR   R30,0000H;
	MOVXR  R30,0,1;
	GOTO   Judge_Out2_RET
  Judge_Out2_NEXT:
  	IJNE   R31,2,Judge_Out2_RET
	LDWR   R0,03F4H;
	LDWR   R30,0001H;
	MOVXR  R30,0,1;
  Judge_Out2_RET:
    RET
    
  Judge_Out3:         
    LDWR   R0,0401H;  判断机型参数
    MOVXR  R30,1,1;
	IJNE   R31,1,Judge_Out3_RET;为1则表示北极星
	MOVDR  04H,R40,1
    IJNE   R40,75,3;是否在75页
    LDBR   R44,116,1
    MOVRD  R44,04H,1;
    GOTO   Judge_Out3_RET  
    
    IJNE   R40,77,3;是否在77页
    LDBR   R44,117,1
    MOVRD  R44,04H,1;
    GOTO   Judge_Out3_RET 
    IJNE   R40,76,Judge_Out3_RET;是否在77页
    LDBR   R44,117,1
    MOVRD  R44,04H,1;
    GOTO   Judge_Out3_RET    
  Judge_Out3_RET:
    RET
    
   Judge_H06:         
    LDWR   R0,0401H;  判断机型参数H06
    MOVXR  R30,1,1;
	IJNE   R31,1,Judge_H06_NEXT1;为1则表示北极星
	Judge_H06_EEV:
    LDWR   R0,047FH;  判断增焓调节模式
    MOVXR  R30,1,1;
	IJNE   R31,0,2 ;0则表示不启用
	LDWR   R30,0002H
	MOVXR  R30,0,1;北极星增焓不可设为不启用
	
    LDWR   R0,0401H;  判断机型参数H06
    MOVXR  R30,1,1;	
	IJNE   R31,2,Judge_H06_RET;;为2则表示并联
  	LDWR   R0,03FEH
  	LDWR   R30,0004H;并联不可设置为三系统
  	MOVXR  R30,0,1;
    GOTO   Judge_H06_RET    
  Judge_H06_NEXT1:
  	IJNE   R31,2,Judge_H06_NEXT2;为2则表示北极星
  	GOTO   Judge_H06_EEV
  Judge_H06_NEXT2:
  	IJNE   R31,3,Judge_H06_RET;;为3代表并联
  	LDWR   R0,03FEH
  	LDWR   R30,0004H;并联不可设置为三系统
  	MOVXR  R30,0,1;
  	GOTO   Judge_H06_RET  
  Judge_H06_RET:
    RET
 
 
  Judge_Out8:
    LDWR   R0,0401H;  判断机型参数
    MOVXR  R30,1,1;
	IJNE   R31,2,Judge_Out8_NEXT1;为2则表示并联北极星
Judge_Out8_NEXT:	
	MOVDR  04H,R40,1
    IJNE   R40,72,3;是否在72页
    LDBR   R44,123,1
    MOVRD  R44,04H,1;
    GOTO   Judge_Out8_RET 
    IJNE   R40,74,3;是否在74页
    LDBR   R44,119,1
    MOVRD  R44,04H,1;
    GOTO   Judge_Out8_RET  
    IJNE   R40,77,3;是否在77页
 ;   LDBR   R44,120,1 					;lsz 2016.12.18注销
     LDBR	R44,117,1					;lsz 2016.12.18添加
    MOVRD  R44,04H,1;	
    GOTO   Judge_Out3_RET 
    IJNE   R40,76,3;是否在77页
    LDBR   R44,120,1
    MOVRD  R44,04H,1
    GOTO   Judge_Out3_RET 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;			lsz 2016.12.18添加    
    IJNE   R40,120,3;是否在120页			
    LDBR   R44,116,1 
    MOVRD  R44,04H,1;
    GOTO   Judge_Out3_RET     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;    
    IJNE   R40,80,Judge_Out8_RET;是否在80页
    LDBR   R44,121,1
    MOVRD  R44,04H,1;        
    GOTO   Judge_Out8_RET     
Judge_Out8_NEXT1:
	IJNE   R31,3,Judge_Out8_RET;为3则表示并联普通  
	GOTO   Judge_Out8_NEXT	
  Judge_Out8_RET:
    RET 
     
  Judge_O4_NEXT:   
   GOTO Judge_Out4_NEXT
   
  Judge_Out4:    
	LDWR   R0,03FEH;  判断系统数量
    MOVXR  R30,1,1;
	IJNE   R31,3,Judge_O4_NEXT;为3则表示三系统
	
	LDWR   R0,1639H;  判断是否已屏蔽
    MOVXR  R30,1,1;
	IJNE   R31,0,Judge_O4_NEXT;为0则表示未屏蔽
	
	LDWR   R30,0001H;  
    MOVXR  R30,0,1;
    ;系统4盘管
	LDWR	R0,4007H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
;	LDWR	R0,1607H;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,1160H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
	
	;系统4防冻感温1
	LDWR	R0,4015H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
;	LDWR	R0,1615H;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,1360H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1

;	LDWR	R0,4015H;故障图标
;	LDWR	R30,0001H
;	MOVXR	R30,0,1
;	LDWR	R0,1560H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
	
	;系统4防冻感温2
	LDWR	R0,4016H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
;	LDWR	R0,1616H;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,1370H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1

;	LDWR	R0,4016H;故障图标
;	LDWR	R30,0001H
;	MOVXR	R30,0,1
;	LDWR	R0,1570H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
	
	;系统4防冻感温3
	LDWR	R0,4017H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
;	LDWR	R0,1617H;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,1380H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
	
	;系统4防冻感温4
	LDWR	R0,4018H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
;	LDWR	R0,1618H;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,1390H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
	
	;系统4回气感温
	LDWR	R0,401CH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
;	LDWR	R0,161CH;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,13D0H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
;
;	LDWR	R0,401CH;故障图标
;	LDWR	R30,0001H
;	MOVXR	R30,0,1
;	LDWR	R0,15B0H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
	
	;系统4增焓出感温
	LDWR	R0,4024H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
;	LDWR	R0,1624H;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,1450H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
	
	;系统4增焓进感温
	LDWR	R0,4020H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
;	LDWR	R0,1620H;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,1410H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
	
	;系统4排气感温
	LDWR	R0,4028H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
;	LDWR	R0,1628H;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,1490H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
	
	;系统4压缩机电流
	LDWR	R0,402CH;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
;	LDWR	R0,162CH;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,14D0H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
	
	;系统4压力
	LDWR	R0,4030H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
;	LDWR	R0,1630H;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,1510H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
   
   	;系统4电子膨胀阀
	LDWR	R0,4034H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
;	LDWR	R0,1680H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1

    ;系统4增焓电子膨胀阀
	LDWR	R0,4038H;故障图标
	LDWR	R30,0001H
	MOVXR	R30,0,1
;	LDWR	R0,1690H
;	MOVXR	R30,1,1
;	LDWR	R30,FFFFH
;	MOVXR	R30,0,1
	
  Judge_Out4_NEXT:
  	LDWR   R0,03FEH;  判断系统数量
    MOVXR  R30,1,1;
	IJNE   R31,4,Judge_Out4_RET;为3则表示三系统
	
	LDWR   R0,1639H;  判断是否已屏蔽
    MOVXR  R30,1,1;
	IJNE   R31,1,Judge_Out4_RET;为1则表示已屏蔽
	LDWR   R30,0000H;  
    MOVXR  R30,0,1;
    
	;系统4盘管
	LDWR	R0,4007H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
;	LDWR	R0,1160H
;	MOVXR	R30,1,1
;	LDWR	R30,0803H
;	MOVXR	R30,0,1
	
	;系统4防冻感温1
	LDWR	R0,4015H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
;	LDWR	R0,1360H
;	MOVXR	R30,1,1
;	LDWR	R30,0811H
;	MOVXR	R30,0,1

;	LDWR	R0,4015H;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,1560H
;	MOVXR	R30,1,1
;	LDWR	R30,0811H
;	MOVXR	R30,0,1
	
	;系统4防冻感温2
	LDWR	R0,4016H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
;	LDWR	R0,1370H
;	MOVXR	R30,1,1
;	LDWR	R30,0812H
;	MOVXR	R30,0,1
;
;	LDWR	R0,4016H;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,1570H
;	MOVXR	R30,1,1
;	LDWR	R30,0812H
;	MOVXR	R30,0,1
;	
	;系统4防冻感温3
	LDWR	R0,4017H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
;	LDWR	R0,1380H
;	MOVXR	R30,1,1
;	LDWR	R30,0813H
;	MOVXR	R30,0,1
	
	;系统4防冻感温4
	LDWR	R0,4018H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
;	LDWR	R0,1390H
;	MOVXR	R30,1,1
;	LDWR	R30,0814H
;	MOVXR	R30,0,1
	
	;系统4回气感温
	LDWR	R0,401CH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
;	LDWR	R0,13D0H
;	MOVXR	R30,1,1
;	LDWR	R30,0818H
;	MOVXR	R30,0,1
;
;	LDWR	R0,401CH;故障图标
;	LDWR	R30,0000H
;	MOVXR	R30,0,1
;	LDWR	R0,15B0H
;	MOVXR	R30,1,1
;	LDWR	R30,0818H
;	MOVXR	R30,0,1
	
	;系统4增焓出感温
	LDWR	R0,4024H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
;	LDWR	R0,1450H
;	MOVXR	R30,1,1
;	LDWR	R30,0820H
;	MOVXR	R30,0,1
	
	;系统4增焓进感温
	LDWR	R0,4020H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
;	LDWR	R0,1410H
;	MOVXR	R30,1,1
;	LDWR	R30,081CH
;	MOVXR	R30,0,1
	
	;系统4排气感温
	LDWR	R0,4028H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
;	LDWR	R0,1490H
;	MOVXR	R30,1,1
;	LDWR	R30,0824H
;	MOVXR	R30,0,1
	
	;系统4压缩机电流
	LDWR	R0,402CH;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
;	LDWR	R0,14D0H
;	MOVXR	R30,1,1
;	LDWR	R30,0828H
;	MOVXR	R30,0,1

   	;系统4压力
	LDWR	R0,4030H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
;	LDWR	R0,1510H
;	MOVXR	R30,1,1
;	LDWR	R30,0836H
;	MOVXR	R30,0,1
	
   	;系统4电子膨胀阀
	LDWR	R0,4034H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
;	LDWR	R0,1680H
;	MOVXR	R30,1,1
;	LDWR	R30,07E8H
;	MOVXR	R30,0,1

   
    ;系统4增焓电子膨胀阀
	LDWR	R0,4038H;故障图标
	LDWR	R30,0000H
	MOVXR	R30,0,1
;	LDWR	R0,1690H
;	MOVXR	R30,1,1
;	LDWR	R30,07ECH
;	MOVXR	R30,0,1
	
  Judge_Out4_RET: 
    RET
   
  Judge_Out5:
;  LDWR   R0,0401H;  判断机型参数
;  MOVXR  R30,1,1;
;  IJNE   R31,2,Judge_Out5_NEXT;为2则表示并联
;  Judge_Out5_change:
;  LDWR   R0,0451H
;  LDWR   R30,0002H
;  MOVXR  R30,0,1;
;  GOTO	Judge_Out5_RET
;  Judge_Out5_NEXT:
;  IJNE   R31,3,Judge_Out5_RET;为3则表示并联
;  GOTO   Judge_Out5_change
;     

	LDWR	R0,0453H;F27>=F26+40
	MOVXR	R30,1,1
	INC		R30,1,40
	LDWR	R0,0454H
	MOVXR	R32,1,1
	JS		R30,R32,1
	MOVXR	R30,0,1
	
	LDWR	R0,0401H;控制F15的遮挡图标是否显示
	MOVXR	R30,1,1
	LDWR	R32,2
	JS		R30,R32,遮挡图标不显示
	LDWR	R0,0451H
	MOVXR	R30,1,1
	IJNE	R31,1,遮挡图标不显示
	LDWR	R0,0003H
	LDWR	R30,1
	MOVXR	R30,0,1
	GOTO	Judge_Out5_RET
	
	遮挡图标不显示:
	LDWR	R0,0003H
	LDWR	R30,0
	MOVXR	R30,0,1
	GOTO	Judge_Out5_RET
	
  Judge_Out5_RET:
     RET
   
  Judge_Out6: 

;     MOVDR  04H,R40,1
;          
;     IJNE   R40,72,Judge_Out6_COMPARE
;     LDWR   R0,03F1H;       H02参数
;     MOVXR  R30,1,1
;     LDWR   R0,03FEH;       H06参数
;     MOVXR  R32,1,1 
;     IJNE   R31,02H,Judge_Out6_COMPARE
;     IJNE   R33,0,1;不是并联机型，则跳转
;     GOTO	jump_to_double_system_S
;     IJNE   R33,1,Judge_Out6_COMPARE  
;
;     jump_to_double_system_S:
;
;     LDBR   R44,93,1
;     MOVRD  R44,04H,1
;     GOTO   Judge_Out6_COMPARE
    
;     IJNE   R33,0,3
;     LDBR   R44,5DH,1
;     MOVRD  R44,04H,1
;     GOTO   Judge_Out6_COMPARE
;     
;     IJNE   R33,1,Judge_Out6_COMPARE
;     LDBR   R44,5DH,1  
;     MOVRD  R44,04H,1
;     GOTO   Judge_Out6_COMPARE
  
  Judge_Out6_COMPARE:
;     IJNE   R40,77,Judge_Out6_RET
;     LDWR   R0,03F1H;       H02参数
;     MOVXR  R30,1,1
;     LDWR   R0,03FEH;       H06参数
;     MOVXR  R32,1,1
;     IJNE   R31,02H,Judge_Out6_RET;双系统
;     IJNE   R33,0,1;不是并联机型，则跳转
;     GOTO	jump_to_double_system_T
;     IJNE   R33,1,Judge_Out6_RET
;     
;     jump_to_double_system_T:
;     LDBR   R44,78,1
;     MOVRD  R44,04H,1
;     GOTO   Judge_Out6_RET
     
;     IJNE   R33,0,3
;     LDBR   R44,78,1
;     MOVRD  R44,04H,1
;     GOTO   Judge_Out6_RET
;     
;     IJNE   R33,1,Judge_Out6_RET
;     LDBR   R44,78,1
;     MOVRD  R44,04H,1
;     GOTO   Judge_Out6_RET     
   
  Judge_Out6_RET:
     RET
    
  Judge_Out7:;判断设置的运行天数是否为0，如果为0，则运行模式界面不显示“运行天数”项
     LDWR  R0,040BH
     MOVXR R30,1,1
     LDBR  R32,0,2     

     
     CJNE  R32,R30,Judge_Out7_COMPARE
     CJNE  R33,R31,Judge_Out7_COMPARE
     GOTO  Judge_Out7_RET
     
   Judge_Out7_COMPARE:  
     MOVDR 04H,R40,1
     IJNE  R40,5BH,Judge_Out7_RET
     LDBR  R44,5CH,1
     MOVRD R44,04H,1
     GOTO  Judge_Out7_RET
     
  Judge_Out7_RET:
     RET
     
  Judge_Out9:
    LDWR  R0,050CH
    MOVXR R30,1,1
    
    IJNE  R31,01H,next_dowland
  ;  LDWR  R0,050AH
  	LDWR   R0,05D8H		;lsz 11.22修改
  	LDWR  R40,0000H
    MOVXR R40,0,1
    
    LDWR  R42,0000H
    LDWR  R0,050CH
    MOVXR R42,0,1    
    GOTO  Judge_Out9_RET
    
    next_dowland:
    IJNE R31,02H,Judge_Out9_RET
    LDWR  R0,050BH
    LDWR  R40,0000H
    MOVXR R40,0,1
    
    LDWR  R42,0000H
    LDWR  R0,050CH
    MOVXR R42,0,1
    
  Judge_Out9_RET:
     RET
  
  Judge_Out10:
  
;    LDWR  R0,0415H
;    MOVXR R30,1,1
;
;    
;    IJNE  R31,0,1
;    GOTO  Judge_Out10_RET
;    MOVDR 04H,R40,1
;    IJNE  R40,91,3
;    LDBR  R44,103,1
;    MOVRD R44,04H,1
;    GOTO  Judge_Out10_RET
;    
;    IJNE  R40,92,Judge_Out10_RET
;    LDBR  R44,104,1
;    MOVRD R44,04H,1
;  
;  Judge_Out10_RET:
     RET
  
  Judge_Out11:
;    LDWR  R0,0415H ;A14参数
;    MOVXR R30,1,1
;    LDWR  R0,03FEH    ;机型参数
;    MOVXR R32,1,1
;    LDWR  R0,0478H;    E21参数
;    MOVXR R34,1,1
;    
;    IJNE  R33,01H,next_compara  ;E21显示自动  
;    IJNE  R35,0,3
;    LDWR  R36,0002H
;    LDWR  R0,0478H
;    MOVXR R36,0,1
;    GOTO  Judge_Out11_RET
;    
;    next_compara:
;    IJNE  R33,02H,next_compara1
;    LDWR  R0,03F1H
;    LDWR  R40,0002H
;    MOVXR R40,0,1
;    GOTO  Judge_Out11_RET
;    
;    next_compara1:
;    IJNE  R33,03H,Judge_Out11_RET
;    LDWR  R0,03F1H
;    LDWR  R40,0002H
;    MOVXR R40,0,1
;    GOTO  Judge_Out11_RET
;    
;  Judge_Out11_RET:
      RET

	Judge_Out12:
;	MOVDR	04H,R40,1
;	IJNE	R40,77,IF_A14=1
;	
;	LDWR	R0,03F1H
;	MOVXR	R30,1,1
;	IJNE	R31,1,双系统或并联机T24_T25
;	单系统_T24_T25:
;	LDBR	R40,105,1
;	MOVRD	R40,04H,1
;	GOTO	Judge_Out12_RET
;	
;	双系统或并联机T24_T25:
;
;	GOTO	Judge_Out12_RET
;	
;	IF_A14=1:
;	IJNE	R40,75,6
;	LDWR	R0,0415H
;	MOVXR	R30,1,1	
;	IJNE	R31,1,Judge_Out12_RET
;	LDBR	R40,107,1
;	MOVRD	R40,04H,1
;	GOTO	Judge_Out12_RET
;	
;	IJNE	R40,76,Judge_Out12_RET
;	LDWR	R0,0415H
;	MOVXR	R30,1,1
;	IJNE	R31,1,Judge_Out12_RET
;	LDBR	R40,106,1
;	MOVRD	R40,04H,1	
;	GOTO	Judge_Out12_RET
;	Judge_Out12_RET:
	RET

  
  TIMER1_jumping:;       定时界面跳转01-11
	MOVDR	04H,R40,1
	IJNE	R40,100,1
	GOTO	在定时界面
	IJNE	R40,99,1	
	GOTO	在定时界面
	IJNE	R40,98,1	
	GOTO	在定时界面	
	IJNE	R40,97,TIMER1_jumping_RET	
	GOTO	在定时界面
	
在定时界面:	
	LDWR	R0,04CBH;开始使能
	MOVXR	R30,1,1
	LDWR	R0,04CDH;结束使能				
	MOVXR	R32,1,1
	IJNE	R31,1,timer1_only_end
	IJNE	R33,1,timer1_only_start
	
	all_timer1_start:	
	LDWR	R0,04CCH;0499H;开始时间
	MOVXR	R30,1,1
	LDWR	R0,04CEH;049BH;结束时间
	MOVXR	R32,1,1

	CJNE	R30,R32,7;如果两个相等，那么只让开始的点亮起来，并且跳转为“结束不使能”。
	CJNE	R31,R33,6
	LDWR	R0,04CDH;049AH
	LDWR	R40,0000H
	MOVXR	R40,0,1
	LDBR	R43,97,1
	MOVRD	R43,04H,1
	GOTO	TIMER1_jumping_RET
	
;	LDWR	R0,101AH;定时器1开启指示-亮
;	LDWR	R36,0001H
;	MOVXR	R36,0,1
	
	MOVDR	04H,R40,1;开始和结束都使能
	IJNE	R40,100,1
	GOTO	TIMER1_jumping_RET
	LDBR	R40,100,1
	MOVRD	R40,04H,1
	GOTO	TIMER1_jumping_RET
	
	timer1_only_end:
	IJNE	R33,1,timer1_off
	LDWR	R0,101AH;定时器1开启指示-亮
	LDWR	R36,0001H
	MOVXR	R36,0,1	
	
	MOVDR	04H,R40,1;仅结束使能
	IJNE	R40,98,1
	GOTO	TIMER1_jumping_RET
	LDBR	R40,98,1
	MOVRD	R40,04H,1
	GOTO	TIMER1_jumping_RET
	
	timer1_only_start:
	LDWR	R0,101AH;定时器1开启指示-亮
	LDWR	R36,0001H
	MOVXR	R36,0,1	
	
	MOVDR	04H,R40,1
	IJNE	R40,97,1
	GOTO	TIMER1_jumping_RET	
	LDBR	R40,97,1
	MOVRD	R40,04H,1
	GOTO	TIMER1_jumping_RET
	timer1_off:
	LDWR	R0,101AH;定时器1开启指示-灭
	LDWR	R36,0000H
	MOVXR	R36,0,1	
	
	MOVDR	04H,R40,1;仅结束使能
	IJNE	R40,99,1
	GOTO	TIMER1_jumping_RET
	LDBR	R40,99,1
	MOVRD	R40,04H,1	
	GOTO	TIMER1_jumping_RET
  
  TIMER1_jumping_RET:
     RET
  
  
  Quit_dispaly:
  
    fault_if_readed:;故障是否已读,已读则红色图标消失    
	LDWR 	R0,0FD8H;		非通信故障
    MOVXR   R30,1,1;传给R30
    LDWR    R0,0FD4H;公共寄存器++，
    MOVXR   R32,1,1;传给R32
    CJNE 	R30,R32,fault_changed1;++
    CJNE 	R31,R33,fault_changed1;;++
    GOTO 	communicate_if_readed;++
 
    fault_changed1:;++
	LDWR 	R0,0FD4H;++取出参数当前值，用于下一轮比较
    MOVXR   R30,0,1
	IJNE	R31,00H,if_new_fault_happend
	LDWR	R0,0FCDH;是否还存在通信故障
	MOVXR	R30,1,1
	IJNE	R31,00,if_new_fault_happend
	LDWR	R0,0FD0H;非通信故障是否已读，状态显示
	LDWR	R40,0001H;未读
	MOVXR	R40,0,1
   
	communicate_if_readed:;++
	LDWR 	R0,0FCDH       ;通信故障
    MOVXR   R30,1,1;传给R30
    LDWR    R0,0FD6H;公共寄存器++，
    MOVXR   R32,1,1;传给R32
    CJNE 	R30,R32,fault_changed2;++
    CJNE 	R31,R33,fault_changed2;;++    
    GOTO 	if_readed_compare
    
    fault_changed2:;++
	LDWR 	R0,0FD6H;++取出参数当前值，用于下一轮比较
    MOVXR   R30,0,1	
	IJNE	R31,00H,if_new_fault_happend;1E表示故障已经恢复
	LDWR	R0,0FD8H;是否还存在非通信故障
	MOVXR	R30,1,1
	IJNE	R31,00,if_new_fault_happend
	LDWR	R0,0FD2H;通信故障是否已读，状态显示
	LDWR	R40,0001H;未读
	MOVXR	R40,0,1
	
	if_readed_compare:;故障是否已读
	MOVDR	04H,R30,1;如果页面跳转到第81页，说明已经查看了故障
	IJNE	R30,51H,Quit_dispaly_RET
	LDWR	R0,0FD0H;非通信故障是否已读，状态显示
	LDWR	R40,0000H
	MOVXR	R40,0,1;已读，不显示
	LDWR	R0,0FD2H;通信故障是否已读，状态显示
	MOVXR	R40,0,1;已读，不显示
	GOTO	Quit_dispaly_RET
	
	if_new_fault_happend:;新故障发生,静态图标都不能显示
	LDWR	R0,0FD0H;非通信故障是否已读，状态显示
	LDWR	R40,0000H
	MOVXR	R40,0,1;已读，不显示
	LDWR	R0,0FD2H;通信故障是否已读，状态显示
	MOVXR	R40,0,1;已读，不显示
	GOTO	Quit_dispaly_RET  
  
  Quit_dispaly_RET:
    RET
  
  main_page_jumping:
  main_page_jumping_ret:
     RET
  
   SYSTEM_PAGE_JUMPING:
     LDBR	R30,0,2	    ;读页码
	 MOVDR 	04H,R31,1

     LDBR	R50,0,2	    ;读输入状态
	 MOVDR 	E9H,R51,1

	 IJNE	R31,0DH,main_page_jumping  ;13页是系统参数键盘所在页
	 LDWR	R0,0502H
 	 MOVXR	R54,1,1
 	 LDBR	R54,0,1
 	 LDWR	R0,0504H
 	 MOVXR	R54,0,1
	 IJNE	R51,01H,jumping_back;如果光标在闪烁，那么就保存0502H的值到0503，如果光标不闪烁，那么就根据0503的值控制页面跳转回对应的系统参数页
 	  	IJNE	R219,0,main_page_jumping;只赋值一次，不会反复赋值。可以有效避免：退出键盘时，录入过程中加载的数据1040H被清零那一刻光标还在闪，0就会被赋给1041H，导致后面页面跳转判断时跳回主界面
 	LDBR	R219,1,1
 	 LDWR	R0,0502H
 	 MOVXR	R34,1,1
 	 LDWR	R0,0503H
 	 MOVXR	R34,0,1
 	 GOTO	main_page_jumping
 	 
  	 jumping_back:       ;如果光标不闪烁了，但是页面停留在键盘页，回不去系统参数页了，那么就需要根据0503的值来控制页面跳转回去了
	   
  CALL SYSTEM_PARA_JUMPING_BACK
  
  SYSTEM_PARA_JUMPING_BACK:

 	 LDWR	R0,0503H
 	 MOVXR	R54,1,1;R55	保存的是系统参数图标对应的值
 	 MOVRD	R54,04H,1
 	 
 	 LDBR	R219,0,1
    SYSTEM_PARA_JUMPING_BACK_RET:
      RET
      
  TIMER1_IF_SET:;判断定时器是否使能
	 LDWR	R0,04CBH;开始使能
	 MOVXR	R30,1,1
	 LDWR	R0,04CDH;结束使能				
	 MOVXR	R32,1,1
	 IJNE	R31,1,3
	 IJNE	R33,1,5
	 CALL	TIMER1_SET_CONTROL;开始和结束都使能
	 GOTO	TIMER1_IF_SET_RET
	 IJNE	R33,1,2
	 CALL	TIMER1_SET_END;仅结束使能
	 GOTO	TIMER1_IF_SET_RET
	 CALL	TIMER1_SET_START;仅开始使能
	 GOTO	TIMER1_IF_SET_RET
  TIMER1_IF_SET_RET:
    RET


	TIMER1_SET_START:;仅开始使能
		LDWR	R0,04CCH;0499H;开始时间
		MOVXR	R40,1,1
		LDWR	R42,3900H;显示的起始地址
		MOV		R41,R43,1;开始时间决定了显示的地址
		MOV		R42,R0,2;
		LDWR	R44,0001H;给要显示的地址赋值为1
		MOVXR	R44,0,1
	TIMER1_SET_START_RET:
	RET
	
	TIMER1_SET_END:;仅结束使能
		LDWR	R0,04CEH;049BH;结束时间
		MOVXR	R40,1,1
		LDWR	R42,3900H;显示的起始地址
		MOV		R41,R43,1;结束时间决定了显示的地址
		MOV		R42,R0,2;
		LDWR	R44,0001H;给要显示的地址赋值为1
		MOVXR	R44,0,1
	TIMER1_SET_END_RET:
	RET
	
	
	TIMER1_SET_CONTROL:;开机和关机全部使能
		LDBR	R35,24,1;代表24h
		LDBR	R36,0,1;代表0h
		LDWR	R0,04CCH;0499H;开始时间
		MOVXR	R30,1,1
		LDWR	R0,04CEH;049BH;结束时间
		MOVXR	R32,1,1
		MOVXR	R36,1,1
	
		CJNE	R30,R32,timer1_picture;如果两个相等，那么只让开始的点亮起来，并且跳转为“结束不使能”。
		CJNE	R31,R33,timer1_picture
		LDWR	R0,04CDH;049AH
		LDWR	R40,0000H
		MOVXR	R40,0,1
		LDBR	R43,97,1
		MOVRD	R43,04H,1
		GOTO	TIMER1_SET_CONTROL_RET
		timer1_picture:
		JS		R33,R31,timer1_cycle_picture2;比较开始时间和结束时间哪一个大
		timer1_cycle_picture1:;开始时间小于结束时间，从开始到结束段亮，一个循环可以搞定
		LDBR	R40,39H,1
		MOV  	R31,R41,1
		MOV		R40,R0,2
		LDWR	R42,0001H;给对应地址赋值为1，即让对应图标亮起来。
		MOVXR	R42,0,1
		INC		R31,0,1
		JS		R31,R33,timer1_cycle_picture1
		GOTO	TIMER1_SET_CONTROL_RET
		
		timer1_cycle_picture2:;开始时间大于结束时间，开始到24h点亮
		LDBR	R40,39H,1
		MOV  	R31,R41,1
		MOV		R40,R0,2
		LDWR	R42,0001H
		MOVXR	R42,0,1
		INC		R31,0,1
		JS		R31,R35,timer1_cycle_picture2
		JS		R36,R33,timer1_cycle_picture3
		
		timer1_cycle_picture3:;开始时间大于结束时间，0h到结束时间点亮
		IJNE	R33,00H,1
		GOTO	TIMER1_SET_CONTROL_RET;如果终止时间刚好在0点，那么0点对应的方块自然不会显示(按照我的排版这个方块一旦显示即表示从0到1点都是静音状态)。
		LDBR	R40,39H,1
		MOV  	R36,R41,1
		MOV		R40,R0,2
		LDWR	R42,0001H
		MOVXR	R42,0,1
		INC		R36,0,1
		JS		R36,R33,timer1_cycle_picture3
		GOTO	TIMER1_SET_CONTROL_RET
	
	TIMER1_SET_CONTROL_RET:
	RET
     
  SsyClock_Set: ;                系统时间设置****01-11    1600H替换成1800H
	MOVDR 	04H,R50,1
	IJNE 	R50,87,isnot_page_27;page_ID是不是第27页，
		LDWR 	R0,17FFH
		MOVXR 	R30,1,1
		IJNE 	R31,01H,isnot_first_comein_page_27	
		
		LDWR 	R30,0
		LDWR 	R0,17FFH;首次进入本页地址清零
		MOVXR	R30,0,1	
		
		LDWR 	R30,1
		LDWR 	R0,1800H;首次进入本页1600H赋值为1-序号
		MOVXR	R30,0,1	
		
		LDWR 	R30,00FFH
		LDWR 	R0,1820H;首次进入本页1620H赋值为FFH--用户数据录入
		MOVXR	R30,0,1	
		
		LDWR 	R30,10
		LDWR 	R0,1821H;首次进入本页1621H赋值为10
		MOVXR	R30,0,1	
		
		LDWR 	R80,11;循环处理1622H-162CH赋值为11
		LDWR 	R140,1822H;;
		LDWR 	R176,182DH
		
		cycle_set_value_11:
			MOV 	R140,R0,2
			MOVXR 	R80,0,1
			INC 	R140,1,0001H
			JS 		R140,R176,cycle_set_value_11;这里是个清理循环


		isnot_first_comein_page_27:
		;光标闪动处理:根据序号位置来闪动
		LDWR 	R0,1800H
		MOVXR 	R30,1,1;  获取序号放在R30 R31
		LDWR 	R40,0001H;序号自加：符合该序号才赋值为1，其他赋值为0
		LDWR 	R80,0000H;循环处理1622H-162CH赋值0或者1
		LDWR 	R82,0001H;循环处理1622H-162CH赋值0或者1
		LDWR 	R140,1801H;;注意一个动态图标显示变量占了32位-2个16为变量
		LDWR 	R176,1819H
		cycle_cursor_flash:
			MOV 	R140,R0,2
			CJNE	R31,R41,2;这里要用cjne不是ijne
			MOVXR 	R82,0,1;赋值为1
			GOTO	cursor_inc
			MOVXR 	R80,0,1;赋值为0
			cursor_inc:
				INC 	R140,1,0002H;16位
				INC 	R40,1,0001H;16位
			    JS 		R140,R176,cycle_cursor_flash;这里是个清理循环		

		;数据录入：如果1620H的值是FFH说明该值无效
		LDWR 	R0,1820H
		MOVXR 	R30,1,1
		IJNE 	R31,FFH,1			
		GOTO	input_unavailable
		;有效数据处理
		LDWR 	R0,1800H
		MOVXR 	R30,1,1;  获取序号放在R30 R31
		LDWR 	R0,1820H
		MOVXR 	R32,1,1;  获取录入值放在R32 R33		
		LDWR 	R40,0001H;序号自加：符合该序号才赋值的162?H,就赋值为1620H
		LDWR 	R140,1821H;;注意一个动态图标显示变量占了32位-2个16为变量
		LDWR 	R176,182DH
		cycle_input_data:
			MOV 	R140,R0,2
			CJNE	R31,R41,input_inc;这里要用cjne不是ijne
			MOVXR 	R32,0,1;赋值
			input_inc:
				INC 	R140,1,0001H;16位
				INC 	R40,1,0001H;16位
			    JS 		R140,R176,cycle_input_data;这里是个清理循环	
			
		LDWR	R40,000DH;13	
		JS	 	R30,R40,1;序号小于13才加
		GOTO	input_unavailable
		INC 	R30,1,0001H;16位
		LDWR 	R0,1800H;序号值加1
		MOVXR 	R30,0,1;
		
		LDWR	R32,1820H
		LDWR	R34,10;再把此序号下的162?H赋值为10-显示空
		OR		R30,R32,2
		MOV 	R30,R0,2
		MOVXR 	R34,0,1;赋值
		
		LDWR 	R30,00FFH
		LDWR 	R0,1820H;1620H赋值为FFH--用户数据可重新录入
		MOVXR	R30,0,1		
		input_unavailable:
		
		;删除上一个数据处理
		LDWR 	R0,182EH
		MOVXR 	R30,1,1
		IJNE 	R31,01H,isnot_delete_the_last			
		LDWR 	R30,0000H
		LDWR 	R0,182EH;162EH赋值为0000H--用户可以再一次删除上一个已输入的数据
		MOVXR	R30,0,1	
		LDWR 	R40,0002H
		LDWR 	R0,1800H
		MOVXR 	R30,1,1;  获取序号放在R30 R31		
		JS	 	R30,R40,isnot_delete_the_last;序号大于1才可以删除	
		
		MOV 	R30,R40,2;同时把序号也给到R40
		LDWR	R32,1820H
		LDWR	R34,11;再把此R30序号下的162?H赋值为11-显示?
		OR		R30,R32,2
		MOV 	R30,R0,2
		MOVXR 	R34,0,1;赋值			

		DEC 	R40,1,0001H;16位
		LDWR 	R0,1800H;序号值减1
		MOVXR 	R40,0,1;			
		LDWR	R32,1820H
		LDWR	R34,10;再把此R40序号下的162?H赋值为10-显示空
		OR		R40,R32,2
		MOV 	R40,R0,2
		MOVXR 	R34,0,1;赋值		
		
		isnot_delete_the_last:
		;
		
	isnot_page_27:;清零和其他一些处理
	;返回按钮别按下	
	LDWR 	R0,182DH
	MOVXR 	R30,1,1;  获取确认键返回值放在R30 R31	
	IJNE 	R31,01H,isnot_back;
	LDWR 	R30,000H;清零
	LDWR 	R0,182DH;back键值
	MOVXR	R30,0,1	
		LDWR 	R30,000H;清零操作
		LDWR 	R0,1800H;序号
		MOVXR	R30,0,1				
	isnot_back:
	
	
	;确认按钮被按下
	LDWR 	R0,182FH
	MOVXR 	R30,1,1;  获取确认键返回值放在R30 R31	
	IJNE 	R31,01H,isnot_enter;
	LDWR 	R30,000H;清零
	LDWR 	R0,182FH;enter键值
	MOVXR	R30,0,1			
		LDWR 	R40,000DH
		LDWR 	R0,1800H
		MOVXR 	R30,1,1;  获取序号放在R30 R31		
		JS	 	R30,R40,isnot_delete_the_last;序号大于13才写入RTC
		CALL 	Write_to_RTC;将录入的数据实时的写入时钟--test	
		
		LDWR 	R30,000H;清零操作
		LDWR 	R0,1800H;序号
		MOVXR	R30,0,1		
		
		LDBR 	R32,14,1
		MOVRD 	R32,04H,1;跳到18页时钟页		
	isnot_enter:	

SsyClock_Set_RET:
RET;

Write_to_RTC:
				 				 ;R100		R103	   R106
	;MOVDR 	20H,R100,7;获取当前时间-只进来一次 年 月 日 星期 时 分  秒	
	LDWR	R40,0010H;将1621H*16 + 1622H的值给到R100--年	
	LDBR	R50,00H,4
	LDWR 	R0,1821H;
	MOVXR 	R30,1,1;高位给到R31
	LDWR 	R0,1822H;
	MOVXR 	R52,1,1;低位给到R53	
	SMAC	R30,R40,R50;
	MOV 	R53,R100,1
;	LDWR 	R0,1650H--test
;	MOVXR 	R50,0,2;
	
	LDWR	R40,0010H;将1623H*16 + 1624H的值给到R101--月	
	LDBR	R50,00H,4
	LDWR 	R0,1823H;
	MOVXR 	R30,1,1;高位给到R31
	LDWR 	R0,1824H;
	MOVXR 	R52,1,1;低位给到R53	
	SMAC	R30,R40,R50;
	MOV 	R53,R101,1
;	LDWR 	R0,1650H--test
;	MOVXR 	R50,0,2;

	LDWR	R40,0010H;将1625H*16 + 1626H的值给到R102--日	
	LDBR	R50,00H,4
	LDWR 	R0,1825H;
	MOVXR 	R30,1,1;高位给到R31
	LDWR 	R0,1826H;
	MOVXR 	R52,1,1;低位给到R53	
	SMAC	R30,R40,R50;
	MOV 	R53,R102,1
;	LDWR 	R0,1650H--test
;	MOVXR 	R50,0,2;	

	LDBR	R103,00H,1;星期

	LDWR	R40,0010H;将1627H*16 + 1628H的值给到R104--时	
	LDBR	R50,00H,4
	LDWR 	R0,1827H;
	MOVXR 	R30,1,1;高位给到R31
	LDWR 	R0,1828H;
	MOVXR 	R52,1,1;低位给到R53	
	SMAC	R30,R40,R50;
	MOV 	R53,R104,1
;	LDWR 	R0,1650H--test
;	MOVXR 	R50,0,2;	

	LDWR	R40,0010H;将1629H*16 + 162AH的值给到R105--分
	LDBR	R50,00H,4
	LDWR 	R0,1829H;
	MOVXR 	R30,1,1;高位给到R31
	LDWR 	R0,182AH;
	MOVXR 	R52,1,1;低位给到R53	
	SMAC	R30,R40,R50;
	MOV 	R53,R105,1
;	LDWR 	R0,1650H--test
;	MOVXR 	R50,0,2;	

	LDWR	R40,0010H;将162BH*16 + 162CH的值给到R106--秒
	LDBR	R50,00H,4
	LDWR 	R0,182BH;
	MOVXR 	R30,1,1;高位给到R31
	LDWR 	R0,182CH;
	MOVXR 	R52,1,1;低位给到R53	
	SMAC	R30,R40,R50;
	MOV 	R53,R106,1
;	LDWR 	R0,1650H--test
;	MOVXR 	R50,0,2;	
	
	LDBR	R99,5AH,1;
	MOVRD 	R99,1FH,1;写入RTC之前要给1FH赋值为5A
	MOVRD 	R100,20H,7;将时间写入RTC

Write_to_RTC_RET:
    RET;    
    
    
      
      
 ;===========曲线
5分钟数据保存:
       LDWR   R0,M_PULS
       MOVXR  R10,1,1
       LDWR   R12,1
       AND    R10,R12,2      ;屏蔽小时位
       MOV    R11,R10,1      ;判断上跳变
       XOR    R11,R231,1     ;判断上跳变
       AND    R11,R10,1      ;判断上跳变
       MOV    R10,R231,1     ;判断上跳变
       IJNE   R11,1,FZBCRET  ;5分钟到
       LDWR   R0,INPUT1 
       MOVXR  R20,1,1
       LDWR   R0,INPUT2 
       MOVXR  R22,1,1
       LDWR   R0,INPUT3 
       MOVXR  R24,1,1
       LDWR   R0,INPUT4 
       MOVXR  R26,1,1        ;数据读入
       LDBR   R10,0,6
       LDWR   R10,4
       SMAC   R232,R10,R12   ;计算在内存中的存放地址
       MOV    R15,R1,1       ;计算在内存中的存放地址
       LDBR   R0,0X20,1      ;计算在内存中的存放地址
       MOVXR  R20,0,4        ;数据保存到内存
       
       LDBR    R12,1,1       ;画当前的曲线
       LDWR    R13,0
       WRLINE  R20,R12,0
       WRLINE  R22,R12,1
       WRLINE  R24,R12,2
       WRLINE  R26,R12,3     ;画电量的曲线 
       
       INC    R232,1,1       ;存放地址指针+1
       IJNE   R233,12,FZBCRET;地址指针=12,
       LDWR   R232,0         ;地址指针=0
一小时到:
       LDWR   R4,0X028A      ;保存着待存入数据的数据库起始地址
       LDWR   R6,0X0001      ;保存着待存入数据的数据库起始地址
       LDWR   R0,0X2040      ;读入待存入数据的数据库起始地址
       MOVXL  2,2            ;读入待存入数据的数据库起始地址
       MOVXR  R4,1,2         ;读入待存入数据的数据库起始地址
       LDWR   R0,0X2000      ;待存入数据的dgus起始地址
       MOVXL  3,48           ;存入数据库
       LDBR   R10,0,12
       LDWR   R12,48
       ADD    R4,R10,R14     ;存放地址指针+48
       LDWR   R10,0X028B
       LDWR   R12,0X0E03     ;比对60天的最大存放地址
       TESTS  R10,R18,4
       IJNE   R0,0,WRIR_NEW_ADDER
       LDWR   R18,0X028A
       LDWR   R20,0X0003
WRIR_NEW_ADDER:       
       LDWR   R0,0X2040     ;保存数据库地址指针
       MOVXR  R18,0,2
       LDWR   R4,0X028A
       LDWR   R6,0X0001     ;保存数据库地址指针
       MOVXL  3,2
FZBCRET:
       RET
;=========== 
翻页键功能:
		LDWR	R0,250EH;JH:为了让每次进入曲线界面时都能刷新历时曲线
		MOVXR	R30,1,1
		IJNE	R31,1,7
		LDWR	R0,250EH
		LDWR	R30,0000H
		MOVXR	R30,0,1
		LDWR	R0,2060H
		MOVXR	R30,1,1
		INC		R31,0,1
		MOV		R31,R234,1	
		
		MOVDR	04H,R30,1;JH:没有进入历史曲线界面就不需要做复杂的调用数据库的工作。
		IJNE	R30,101,1
		GOTO	在历史曲线页
		IJNE	R30,125,UDWNRET
		
		在历史曲线页:
       LDWR   R0,0X2060
       MOVXR  R10,1,1
       CJNE   R11,R234,UPDZX
       GOTO   UDWNRET
UPDZX: 

		MOV    R11,R234,1 
       CALL   CLRLINE 
       LDBR   R225,1,1
UDWNRET:
       RET       
;===========================       
翻页画历史曲线:       
       IJNE   R225,1,UPDOWNRET
       LDBR   R225,0,1
       LDWR   R4,0X028A      ;保存着待存入数据的数据库起始地址
       LDWR   R6,0X0001      ;保存着待存入数据的数据库起始地址
       LDWR   R0,0X2050
       MOVXL  2,2
       MOVXR  R10,1,2
       LDBR   R14,0,12
       LDWR   R16,1
       SUB    R10,R14,R18
       MOV    R22,R10,4       ;地址-1，R10R11R12R13指向最后一个有效数据
       LDBR   R230,1,1        ;准备对号
进入对号:
       CJNE   R230,R234,对号过程数据准备  
       CALL   画历史曲线过程
       GOTO   UPDOWNRET
对号过程数据准备: 
       LDWR   R228,24     ;24X48=1152  
对号过程:       
       LDBR   R14,0,12
       LDWR   R16,48;24X48=1152
       SUB    R10,R14,R18
       MOV    R22,R10,4
       IJNE   R10,0X02,LADDER--
       IJNE   R11,0X8A,LADDER--
       IJNE   R12,0X00,LADDER--
       IJNE   R13,0X02,LADDER--
       LDWR   R10,0X028B
       LDWR   R12,0X0E02
LADDER--:
       DEC    R228,1,1          
       IJNE   R228,0,对号过程
       IJNE   R229,0,对号过程
       INC    R230,0,1
       GOTO   进入对号
UPDOWNRET:
      RET
 ;====================== 
 CLRLINE:
       LDBR   R10,0X55,1
       MOVRD  R10,0XEB,1
       ;LDBR   R10,0X5B,1
       ;MOVRD  R10,0XEB,1
       ;LDBR   R10,0X5C,1
       ;MOVRD  R10,0XEB,1
       ;LDBR   R10,0X5D,1
      ; MOVRD  R10,0XEB,1
       RET
 ;======================
画历史曲线过程:
       LDWR   R228,288  ;画288点 
       MOV    R10,R4,4   ;对号好的地址载入
       IJNE   R4,0X02,画电量的曲线
       IJNE   R5,0X8A,画电量的曲线
       IJNE   R6,0X00,画电量的曲线
       IJNE   R7,0X02,画电量的曲线
       LDWR   R4,0X028B
       LDWR   R6,0X0E02    ;地址过零  
       
画电量的曲线:
       LDWR   R0,0X2050
       MOVXL  2,1 
       MOVXR  R20,1,1
       ;LDWR	  R30,80;jh 超过80就不显示，新屏的数据库值远远超出80了，如果显示出来会看到曲线从天上掉下来
       ;JS	R30,R20,画曲线3 
       LDBR    R22,1,1
       LDWR    R23,0
       WRLINE  R20,R22,7
       CALL    计算下一数据地址
画曲线3: 
       LDWR   R0,0X2050
       MOVXL  2,1 
       MOVXR  R20,1,1
       ;LDWR		R30,400;jh
       ;JS		R30,R20,画曲线2
       LDBR    R22,1,1
       LDWR    R23,0
       WRLINE  R20,R22,6  ;画曲线3
       CALL    计算下一数据地址
画曲线2: 
       LDWR   R0,0X2050
       MOVXL  2,1 
       MOVXR  R20,1,1
       ;LDWR		R30,400;jh
       ;JS		R30,R20,画曲线1 
       LDBR    R22,1,1
       LDWR    R23,0
       WRLINE  R20,R22,5  ;画曲线2
       CALL    计算下一数据地址       
画曲线1: 
       LDWR   R0,0X2050
       MOVXL  2,1 
       MOVXR  R20,1,1
       ;LDWR		R30,400;jh
       ;JS		R30,R20,WRLSRET
       LDBR    R22,1,1
       LDWR    R23,0
       WRLINE  R20,R22,4  ;画曲线1
       CALL    计算下一数据地址 
       DEC     R228,1,1 
       IJNE    R228,0,画电量的曲线 
       IJNE    R229,0,画电量的曲线 
 WRLSRET:
       RET
;=============      
计算下一数据地址:
       LDBR   R10,0,12
       LDWR   R12,1
       SUB    R4,R10,R14   ;地址-1
       MOV    R18,R4,4
       IJNE   R4,0X02,JSDZRET
       IJNE   R5,0X8A,JSDZRET
       IJNE   R6,0X00,JSDZRET
       IJNE   R7,0X02,JSDZRET
       LDWR   R4,0X028B
       LDWR   R6,0X0E02    ;地址过零   
JSDZRET:       
       RET
;==============
清除数据库:
       LDWR   R0,0X205F
       MOVXR  R10,1,1
       IJNE   R11,1,CLRSQLRET
       LDWR   R10,0
       MOVXR  R10,0,1
       LDWR   R226,0
       LDWR   R4,0X028A      
       LDWR   R6,0X0000
       LDBR   R10,0X55,1
       MOVRD  R10,0XEB,1
CLRSQLRET:
       RET     
;==============       
CLRSQL:
       IJNE  R227,99,CLRDATA
       GOTO  CLRET
CLRDATA:      
       LDWR   R0,0X2070
       MOVXL  3,700
       INC    R226,1,1
       LDBR   R10,0,12
       LDWR   R12,700
       ADD    R4,R10,R14
       MOV    R18,R4,4 
      
CLRET:
       RET      
;===============
CS:
       LDWR   R0,3030H
       MOVXR  R10,1,1
       IJNE   R11,1,CSRET
       LDWR   R10,0
       MOVXR  R10,0,1
       LDWR   R4,0X028A
       LDWR   R6,0XF302
       LDWR   R0,0X2080
       MOVXL  2,6912
CSRET:
       RET     
       
       
横坐标显示:
	LDWR	R0,2060H
	MOVXR	R30,1,1
	MOVXR	R32,1,1
	MOVXR	R34,1,1
	MOVXR	R36,1,1
	MOVXR	R38,1,1
	LDWR	R0,1060H
	MOVXR	R30,0,5
横坐标显示_RET:
RET    

曲线等级选择:;A19
	MOVDR	04H,R40,1
	IJNE	R40,101,曲线等级保存
	LDWR	R0,0421H
	MOVXR	R30,1,1
	IJNE	R31,1,曲线等级保存
	LDBR	R40,125,1
	MOVRD	R40,04H,1

	
	曲线等级保存:
	LDWR 	R0,0421H;		
    MOVXR   R30,1,1;传给R30
    LDWR    R0,6FFDH;公共寄存器++，
    MOVXR   R32,1,1;传给R32
    CJNE 	R30,R32,曲线等级保存_RET;++
    CJNE 	R31,R33,曲线等级保存_RET;++
    GOTO 	曲线等级选择_RET;++
 
    曲线等级保存_RET:;++
	LDWR 	R0,6FFDH;++取出参数当前值，用于下一轮比较
    MOVXR   R30,0,1
 
	 LDWR  R0,0BC3H
	 MOVXR R30,1,1
	 LDWR  R32,0002H;
	 OR    R30,R32,2;  0BC3的第1位为1，则参数发生变化
	 MOVXR R30,0,1
	 
;    LDBR 	R4,02H,1;加载用户数据库地址02 87 01 10到R4、R5、R6、R7
;	LDBR 	R5,87H,1
;	LDBR 	R6,01H,1
;	LDBR 	R7,0FH,1
;	LDWR 	R0,0421H
;	MOVXL 	3,01H;存储本次的设定值，下次上电时启用

曲线等级选择_RET:
RET  
      
;********************首页面中文星期*************************************
星期一:
	MOVDR 	20H,R100,7;获取当前时间- 年 月 日 星期 时 分  秒
	LDWR	R0,3100H;首页中文星期图标地址
	LDWR	R30,0
	MOV		R103,R31,1
	MOVXR	R30,0,1
	RET
;*****************************************************************      

;********************500N-2000N电子膨胀阀转换****************************
EEV_2000N:
	LDWR	R0,0BC3H;上电标志
	MOVXR	R30,1,1
	LDWR	R32,8000H
	AND		R30,R32,2
	IJNE	R30,80H,1
	GOTO	EEV_2000N_Ret
	
	LDWR	R0,0315H	;是否转换过标志
	MOVXR	R30,1,1	
	IJNE	R31,1,EEV_N_Ret;等于0代表没有转换过
	
	LDWR	R0,0C6FH	;电子膨胀阀规格
	MOVXR	R32,1,1	
	LDWR	R0,0483H	;电子膨胀阀规格
	MOVXR	R30,1,1	
	CJNE  	R30,R32,EEV_2000N_Change;
	CJNE  	R31,R33,EEV_2000N_Change;
	GOTO	EEV_2000N_Ret
EEV_2000N_Change:	
	IJNE	R31,1,EEV_500N	;等于1代表2000N

	;**********参数*4
	LDWR	R34,0004H;倍数
	LDWR	R30,0474H;源变量
	CALL	乘法
	LDWR	R30,0475H;源变量
	CALL	乘法	
	LDWR	R30,0476H;源变量
	CALL	乘法
	LDWR	R30,0478H;源变量
	CALL	乘法
	LDWR	R30,0479H;源变量
	CALL	乘法
;	LDWR	R30,0482H;源变量
;	CALL	乘法
;	LDWR	R30,0483H;源变量
;	CALL	乘法
;	LDWR	R30,0484H;源变量
;	CALL	乘法
;	LDWR	R30,0485H;源变量
;	CALL	乘法
;	LDWR	R30,0486H;源变量
;	CALL	乘法
	;置1代表已转换
	GOTO	EEV_2000N_Ret
EEV_2000N_Ret:
	RET	
	
EEV_N_Ret:
	LDWR	R0,0315H	;是否转换过标志
	LDWR	R30,0001H
	MOVXR	R30,0,1	
	RET	
	
EEV_500N:
;	LDWR	R0,0315H	;是否转换过标志
;	MOVXR	R30,1,1	
;	IJNE	R31,1,EEV_N_Ret;等于1代表转换过
	;**************参数/4
	LDWR	R36,0474H;源变量
	CALL	除法
	LDWR	R36,0475H;源变量
	CALL	除法
	LDWR	R36,0476H;源变量
	CALL	除法
	LDWR	R36,0478H;源变量
	CALL	除法
	LDWR	R36,0479H;源变量
	CALL	除法
;	LDWR	R36,0482H;源变量
;	CALL	除法
;	LDWR	R36,0483H;源变量
;	CALL	除法
;	LDWR	R36,0484H;源变量
;	CALL	除法
;	LDWR	R36,0485H;源变量
;	CALL	除法
;	LDWR	R36,0486H;源变量
;	CALL	除法
;	LDWR	R0,0315H	;是否转换过标志
;	LDWR	R30,0000H
;	MOVXR	R30,0,1		;置0代表未转换	
EEV_500N_Ret:

	RET		
;*****************************************************************   


;*****************乘法函数*********************************************
	;LDWR	R30,;源变量
	;LDWR	R32,;倍数
乘法:
	MOV		R30,R0,2
	MOVXR	R32,1,1
	LDBR	R36,0,4
	SMAC	R32,R34,R36
	MOVXR	R38,0,1
	RET
;********************************************************************

;*****************除法函数*********************************************
	;LDWR	R36,;源变量 30 31 32 33 34 35 36 37
	;LDWR	R46,;倍数
除法:
	MOV		R36,R0,2
	MOVXR	R36,1,1
	LDBR	R30,0,6
	LDWR	R46,0004H;倍数
	LDBR	R40,0,6
	DIV		R30,R40,1
	MOVXR	R36,0,1
	RET
;********************************************************************



;;;;;;;;;;;;;;;;;;;;
;系统时间设置
;;;;;;;;;;;;
;600H -年 
;601H - 月
;602H - 日
;603H - 星期
;604H - 时
;605H - 分
;606H - 秒
;182FH - 确认键
R30R35modR40R45:
	LDBR	R40,0,6
	LDBR	R30,0,6
	DIV		R30,R40,0
R30R35modR40R45_RET:	
	RET
	
reCombine:
	LDWR 	R40,0010H
	LDBR 	R44,00H,2
	SMAC	R36,R40,R44
reCombine_RET:
	RET
		
systClock:

LDWR	R0,0600H	;--年
MOVXR	R36,1,1
LDWR	R46,100


CALL	R30R35modR40R45
MOV		R46,R36,2
LDWR	R46,10
CALL	R30R35modR40R45
CALL	reCombine
MOV		R47,R100,1

LDWR	R0,0601H	;--月
MOVXR	R36,1,1
LDWR	R46,10
CALL	R30R35modR40R45
CALL	reCombine
MOV		R47,R101,1

LDWR	R0,0602H	;--日
MOVXR	R36,1,1
LDWR	R46,10
CALL	R30R35modR40R45
CALL	reCombine
MOV		R47,R102,1

LDWR	R0,0604H	;--时
MOVXR	R36,1,1
LDWR	R46,10
CALL	R30R35modR40R45
CALL	reCombine
MOV		R47,R104,1

LDWR	R0,0605H	;--分
MOVXR	R36,1,1
LDWR	R46,10
CALL	R30R35modR40R45
CALL	reCombine
MOV		R47,R105,1
;	LDWR	R107,0600H;年对应地址
;	LDWR	R0,0606H;秒对应地址
;	LDBR	R2,47,1 ;此处将设置为R47的地址
;	LDBR	R3,106,1;此处为R106的地址,对应年
;	LDBR	R9,1,1 ;MOVA赋值的字节数
;	
;dateTimeGetNext:
;	MOVXR	R36,1,1
;	LDWR	R46,10
;	CALL	R30R35modR40R45
;	CALL	reCombine
;	
;	MOVA;
;	DEC		R0,1,1
;	DEC		R3,0,1
;	JS		R107,R0,dateTimeGetNext
;	
;	MOVXR	R36,1,1
;	LDWR	R46,100
;	CALL	R30R35modR40R45
;	MOV		R46,R36,2
;	LDWR	R46,10
;	CALL	R30R35modR40R45
;	CALL	reCombine
;	MOV		R47,R100,1 	;年R100要做特殊处理，因为年是2000开始的所以除100后取两位余数后，再除10
	
	CALL 	RTC_SET

systClock_RET:
RET

RTC_SET:
	LDBR	R99,5AH,1
	MOVRD	R99,1FH,8
RTC_SET_RET:
RET

systTimeSet:
	MOVDR	04H,R30,1
	IJNE	R30,141,1
		GOTO	enterClockSet
	IJNE	R30,150,clearFlag0607H	
	enterClockSet:	
		CALL	initSystTime
		LDWR	R0,182FH ; 	确认按钮被按下
		MOVXR	R120,1,1
		IJNE	R121,01H,systTimeSetCancel
		IJNE	R120,00H,systTimeSetCancel
			CALL	systClock
			LDWR	R0,182FH 
			LDWR	R120,0000H
			MOVXR	R120,0,1
		GOTO	systTimeSet_RET
	initSystTime:
	;;;;;;;LSZ 12.27添加
		LDWR	R0,0607H        ;是否已经初始化标志
		MOVXR	R30,1,1
		IJNE	R31,0,systTimeSet_RET
		LDWR	R30,0001H
		MOVXR	R30,0,1
	    MOVDR	20H,R100,7   ;年月日时分秒
	    ;;;;;;;;;;;年
	    MOV		R100,R37,1
	    LDBR	R30,0,7
		LDWR	R46,0010H
		CALL	R30R35modR40R45
		CALL	reCombineA
;		LDWR	R30,0000H
;		LDWR	R32,0064H
;		LDWR	R34,0000H
;		LDWR	R36,000AH
;		LDBR	R40,0,6
;		SMAC	R30,R34,R40
		LDWR	R30,0000H
		LDWR	R32,07D0H
		LDWR	R34,0000H
		MOV		R46,R36,2
		ADD		R30,R34,R40
		LDWR	R0,0600H
		MOVXR	R46,0,1
		
		;;;;;;月
		MOV     R101,R37,1
		LDBR	R30,0,7
		LDWR	R46,0010H
		CALL	R30R35modR40R45
		CALL	reCombineA
		LDWR	R0,0601H
		MOVXR	R46,0,1
		
		;;;;日
		MOV     R102,R37,1
		LDBR	R30,0,7
		LDWR	R46,0010H
		CALL	R30R35modR40R45
		CALL	reCombineA
		LDWR	R0,0602H
		MOVXR	R46,0,1
		
		;;;;;时
		MOV     R104,R37,1
		LDBR	R30,0,7
		LDWR	R46,0010H
		CALL	R30R35modR40R45
		CALL	reCombineA
		LDWR	R0,0604H
		MOVXR	R46,0,1
		
		;;;;;分
		MOV     R105,R37,1
		LDBR	R30,0,7
		LDWR	R46,0010H
		CALL	R30R35modR40R45
		CALL	reCombineA
		LDWR	R0,0605H
		MOVXR	R46,0,1		
;;;;;;;;;;;;		
;;;;;;;;;;;;	LSZ  12.27注销
;		LDWR	R0,600H	;--年
;		LDWR	R36,2000
;		MOVXR	R36,0,1
;		LDWR	R0,0601H	;--月
;		LDWR	R36,0001H
;		MOVXR	R36,0,1
;		LDWR	R0,0602H	;--日
;		LDWR	R36,0001H
;		MOVXR	R36,0,1		
;		LDWR	R0,0604H	;--时
;		LDWR	R36,0000H
;		MOVXR	R36,0,1			
;		LDWR	R0,0605H	;--分
;		LDWR	R36,0000H
;		MOVXR	R36,0,1				
;;;;;;;;;;;;;;;;;;;;	
		RET
clearFlag0607H:
LDWR	R0,0607H
LDWR	R30,0000H
MOVXR	R30,0,1
systTimeSetCancel:
systTimeSet_RET:
	RET
	
reCombineA:
	LDWR 	R40,000AH
	LDBR 	R44,00H,2
	SMAC	R36,R40,R44
reCombineA_RET:
	RET	
;;;;;;;;;;;;;;;;
;;故障返回函数
;;;根据进去的页面判断该返回到哪一页
;;30BH -记录主界面页
;;30CH -记录参数页
;;30FH -记录按键返回
;;;;;;;;;;;;;;;;	
;failureReback:
;	LDWR	R0,030CH
;	MOVXR	R30,1,1
;;	LDWR	R32,0003H
;;	JS	R30,R32,threadSleep
;;	IJNE	R31,3,threadSleep
;		LDWR	R0,030FH	;故障返回键为1时候进入循环
;		MOVXR	R30,1,1
;		IJNE	R31,1,failureReback_RET
;			LDWR	R0,030BH
;			MOVXR	R32,1,1
;			IJNE	R33,1,1			;如果此时已经置0了，那就不跳转了
;				MOVRD	R33,04H,1	;切换回指定页面
;			LDWR	R30,0000H
;			LDWR	R0,030FH
;			MOVXR	R30,0,1		;将返回标志置0
;			LDWR	R0,030BH
;			MOVXR	R30,0,1		;将页面缓存置0   
;			LDWR	R0,030DH
;			MOVXR	R30,0,1		;将实时故障缓存置0 			
;			LDWR	R0,030CH
;			LDWR	R30,0000H	;3次循环后才能再次进入故障返回循环
;			MOVXR	R30,0,1
;			RET
;threadSleep:
;		INC     R31,0,1
;		LDWR    R0,030FH
;		LDWR    R32,0000H
;		MOVXR	R32,0,1
;failureReback_RET:
;RET
failureReback:
	LDWR	R0,030FH	;故障返回键为1时候进入循环
	MOVXR	R30,1,1
	IJNE	R31,1,failureReback_RET
		LDWR	R0,030BH
		MOVXR	R32,1,1
		IJNE	R33,05H,1
		MOVRD	R33,04H,1	;切换回主页面
		
		LDWR	R0,030CH
			MOVXR	R34,1,1
		IJNE	R35,13H,1
			MOVRD	R35,04H,1	;切换回19页面
			
		IJNE    R33,0,3
			IJNE	R35,0,2
			LDWR	R34,0005H
			MOVRD	R35,04H,1	;异常进入时,切换回主页面
		LDWR	R30,0000H
		LDWR	R0,030FH
		MOVXR	R30,0,1		;将返回标志置0
		LDWR	R0,030BH
		MOVXR	R30,0,1		;将页面缓存置0
		LDWR	R0,030CH
		MOVXR	R30,0,1		;将页面缓存置0

failureReback_RET:
RET

;;;;;;;;;
;;;进入故障的函数
;;;当有实时故障出现时，可以进入,否则不能从主界面进入故障
;;;0FCDH --故障动态图标 R40：R41
;;;0FCFH --故障动态图标 R42：R43
;;;0FD0H --故障静态图标
;;;0FD2H --故障静态图标
;;;030BH --进入故障的页面 R30：R31
;;;030DH --标志位，判断是否可以进入故障页 R32：R33
	
enterFalog:
	CALL	clear_030BH
	LDWR	R0,0FCDH
	MOVXR	R40,1,1
	LDWR	R0,0FCFH
	MOVXR	R42,1,1
	IJNE	R31,5,enterFalog_RET	;如果有按,就判断是否有实施故障
		IJNE	R41,0,jumpToPage81
		   	IJNE	R43,0,jumpToPage81
				RET
							
enterFalog_RET:
    RET

clear_030BH:
	LDWR	R0,030BH
	MOVXR	R30,1,1
	LDWR	R0,030DH
	MOVXR	R32,1,1
	IJNE	R31,5,clear_030BH_RET		;进入的键值有没有清零，为1表示没清零
	    IJNE	R33,0,decOne_030DH		;初始化计数
	        LDWR	R34,0004H
	        LDWR	R0,030DH
	        MOVXR	R34,0,1				
			RET
decOne_030DH:
	DEC	   R32,1,1;030D自减一
	LDWR   R0,030DH
	MOVXR  R32,0,1	
	IJNE   R33,0,clear_030BH_RET
	    LDWR	R36,0000H
	    LDWR	R0,030BH
	    MOVXR	R36,0,1
		GOTO   clear_030BH_RET
	
clear_030BH_RET:
	RET	


jumpToPage81:
	LDWR	R36,0051H	;81页
	MOVRD	R36,03H,2
jumpToPage81_RET:
RET


;;;;;;;;;;;;;;
;;主界面显示函数
;;根据状态显示当前在哪个主界面上
;;;3920H - 获取当前页
;;;03F3H - 开关机地址
;;;03F4H - 冷热模式地址
;;;;;;;;;;
inMainPage:
;;;;;测试是否页面正确
	MOVDR 	03H,R151,2
	LDWR  	R0,3920H
	MOVXR 	R151,0,1
;;;;;;;;	
	IJNE	R152,5,1
		GOTO	powerON
	IJNE	R152,6,1
		GOTO	powerON
	IJNE	R152,7,1
		GOTO	powerON
	IJNE	R152,8,inMainPage_RET
		
	;判断开关机
powerON: 
	LDWR	R0,03F3H
	MOVXR	R30,1,1
	IJNE	R31,1,powerOFF
		;判断制冷制热
		LDWR	R0,03F4H
		MOVXR	R32,1,1
		IJNE	R33,1,CoolingON
			LDWR	R30,0007H
			MOVRD	R30,03H,2 ;制热开机界面
			GOTO	inMainPage_RET
	CoolingON:
		LDWR	R30,0005H
		MOVRD	R30,03H,2
		GOTO	inMainPage_RET
powerOFF:		
	LDWR	R0,03F4H
	MOVXR	R32,1,1
	IJNE	R33,1,CoolingOFF
		LDWR	R30,0008H
		MOVRD	R30,03H,2 ;制热关机界面
		GOTO	inMainPage_RET
CoolingOFF:
	LDWR	R30,0006H
	MOVRD	R30,03H,2
			
inMainPage_RET:
	RET


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;选模式时控制显示冷热还是单冷单热的函数
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;0400H - H05地址
inModePage:
	MOVDR 	03H,R151,2
	LDWR  	R0,3920H
	MOVXR 	R151,0,1
	
	LDWR	R0,0400H
	MOVXR	R30,1,1
	IJNE	R31,1,1
		GOTO	inModePage_RET
	IJNE	R31,0,1
		GOTO	chillerMode
	IJNE	R31,2,1	
		GOTO	heatOnlyMode
	GOTO	inModePage_RET
chillerMode:		
	IJNE	R152,87H,3
		LDWR	R30,006CH
		MOVRD	R30,03H,2 ;单冷开模式选择界面
		GOTO	inModePage_RET
	IJNE	R152,88H,2
		LDWR	R30,006DH
		MOVRD	R30,03H,2 ;单冷关模式选择界面
		GOTO	inModePage_RET
heatOnlyMode:	
	IJNE	R152,89H,3
		LDWR	R30,006EH
		MOVRD	R30,03H,2 ;单热开模式选择界面
		GOTO	inModePage_RET
	IJNE	R152,8AH,3
		LDWR	R30,006FH
		MOVRD	R30,03H,2 ;单热关模式选择界面
		GOTO	inModePage_RET
inModePage_RET:
RET

LED_SET:
	MOVDR	06H,R153,1
	IJNE	R153,2,LED_SET_RET
		MOVDR	4AH,R30,2
		IJNE	R30,02EEH,LED_SET_RET	;750,单位为4ms ,共计30s
			
LED_SET_INIT:
	LDWR 	R30,0BB8H  	;3000 ,单位为4ms,共120s
	MOVRD	R30,4AH,2	;16BIT自减寄存器
LED_SET_RET:
RET
	
	
;;;;;;;;;;;;;;;;;;;
;;;并联单风腔时不显示F15
;;;;;;;;;;;;;;;;;;	
;;;********************
;;0451H	- F24风腔数量
;;0401H - H06机型
;;05E0H - 遮掩图标
	Judge_DisplayF26:
	MOVDR	04H,R40,1
	IJNE	R40,112,judgePressure	
		LDWR	R0,0451H	;F24 风腔数量
		MOVXR	R30,1,1		;单风腔才会继续判断，否则直接返回
		IJNE	R31,1,Judge_DisplayF26_RET
			LDWR	R0,0401H	;H06 机型
			MOVXR	R30,1,1
			LDWR	R32,0002H
			JS	R30,R32,Judge_DisplayF26_RET
				LDWR	R0,05E0H  ;05E0H-遮掩图标
				LDWR	R30,0001H
				MOVXR	R30,0,1
				RET
	Judge_DisplayF26_RET:
		LDWR	R0,05E0H  ;05E0H-遮掩图标
		LDWR	R30,0000H
		MOVXR	R30,0,1	
		RET
		
	judgePressure:
	IJNE	R40,113,Judge_DisplayF26_RET
		LDWR	R0,0451H	;F24 风腔数量
		MOVXR	R30,1,1		;单风腔才会继续判断，否则直接返回
			IJNE	R31,1,Judge_DisplayF26_RET
			LDWR	R0,0401H	;H06 机型
			MOVXR	R30,1,1
			LDWR	R32,0002H
			JS	R30,R32,Judge_DisplayF26_RET
				LDWR	R0,05E0H  ;05E0H-遮掩图标
				LDWR	R30,0001H
				MOVXR	R30,0,1
				RET
 ;*******************
;;;;;;;
;;主界面动画旋转函数
;;;;;;
;;05E1H~05EFH 预留转圈用
circleDisplay:
	LDWR	R0,03F3H
	MOVXR	R30,1,1
	IJNE	R31,1,circleDisplay_INIT
		LDWR	R0,05E1H	;旋转图标需要占用多个地址，否则会出现不可知的问题，此处预留15个字节给旋转图标05E1H~05EFH
		LDWR	R30,0001H
		MOVXR	R30,0,1
		GOTO	circleDisplay_RET
		
circleDisplay_INIT:
	LDWR	R0,05E1H
	LDWR	R30,0000H
	MOVXR	R30,0,1
circleDisplay_RET:
RET


;;;;;;;;;;;;;;;;;;;华氏摄氏转化;;;;;;;;;;;;;;;;;;;;;
;;;040CH - 温度单位地址
;;;0540H - 温度单位缓存地址
conversion:
	LDWR 	R0,040CH	;温度标志通讯位
	MOVXR	R30,1,1
	LDWR	R0,0540H	;上轮温度标志状态
	MOVXR	R32,1,1
	CJNE	R31,R33,changeDisplay
		IJNE	R31,00H,2	;/**判断是华氏还是摄氏,摄氏往下走，华氏跳转2行*/
			CALL	displayCAll;
			GOTO	conversion_RET;
			CALL	displayFAll;
			GOTO	conversion_RET;
			
changeDisplay:
	IJNE	R31,00H,2
		CALL	preFtoC
		GOTO	writeTempFlag
	IJNE	R31,01H,conversion_RET	
	CALL	preCtoF
	
;;;;;;;;
;;;将现在的摄氏度冲掉缓冲区，并通知主板来读040CH
;;;;;;
writeTempFlag:
	LDWR	R0,040CH
	MOVXR	R30,1,1
	LDWR	R0,0540H
	MOVXR	R30,0,1	
	LDWR	R0,0BC3H
	MOVXR	R40,1,1	
	LDWR	R42,0002H
    OR      R40,R42,2
    MOVXR   R40,0,1 
;;;;;;;;;;;;;;;;
			
conversion_RET:
RET

preCtoF:
	CALL	preCtoF_A;
	CALL	preCtoF_F;
	CALL	preCtoF_E;
	CALL	preCtoF_D;
	CALL	preCtoF_R;
;	CALL	preCtoF_T;
	
preCtoF_RET:
RET

preFtoC:
	CALL	preFtoC_A;
	CALL	preFtoC_F;
	CALL	preFtoC_E;
	CALL	preFtoC_D;
	CALL	preFtoC_R;
;	CALL	preFtoC_T;
;	
preFtoC_RET:
RET	

displayCAll:
	CALL	displayC_A;
	CALL	displayC_F;
	CALL	displayC_E;
	CALL	displayC_D;
	CALL	displayC_R;
	CALL	displayC_T;
	
displayCAll_RET:
RET

displayFAll:
	CALL	displayF_A;
	CALL	displayF_F;
	CALL	displayF_E;
	CALL	displayF_D;
	CALL	displayF_R;
	CALL	displayF_T;
	
displayFAll_RET:
RET


displayF:
    MOV		R242,R0,2
    MOVXR   R30,1,1;传给R30
    ;LDWR    R0,3AA3H;公共寄存器++，
    MOV		R244,R0,2
    MOVXR   R32,1,1;传给R32
    CJNE 	R30,R32,TEST1;++大多数情况下都是通信变量转化成华氏度再覆盖显示变量,只有显示变量发生变化时才会主动去覆盖通信变量
    CJNE 	R31,R33,TEST1;++
    GOTO 	TEST2;++
    
	TEST1:;++
	    ;LDWR    R0,0BC3H;ZSW/20160606;
	    MOV		R248,R0,2;不论是用户改的还是主板改的，都会置位参数改动标志位。
	    ;之所以改成这个逻辑，是不能排除计算误差带来的影响。主板写过来的值，经过华氏摄氏互转后可能会使通信变量产生0.1摄氏度的误差，
	    MOVXR   R30,1,1
	    ;LDWR    R32,0010H
	    MOV		R250,R32,2
	    OR      R30,R32,2  ;或逻辑运算
	    MOVXR   R30,0,1
	      
		;LDWR	R0,3AA0H;
		MOV		R240,R0,2
		MOVXR	R30,1,1
		;LDWR 	R0,3AA2H;++取出参数当前值，用于下一轮比较
		MOV		R246,R0,2
	    MOVXR   R30,0,1	
		
		;LDWR	R0,3AA1H
		MOV		R242,R0,2
		MOVXR	R30,1,1
		;LDWR 	R0,3AA3H;++取出参数当前值，用于下一轮比较
	    MOV		R244,R0,2
	    MOVXR   R30,0,1
	
		;LDWR	R0,3AA1H;
		MOV		R242,R0,2
	    MOVXR   R32,1,1
	    CALL    conversionFtoC
	    ;LDWR    R0,3AA0H
	    MOV		R240,R0,2
	    MOVXR   R46,0,1     
	
		GOTO	displayF_RET
	
	TEST2:
		MOV		R240,R0,2
	    MOVXR   R32,1,1
	    CALL    conversionCtoF	
		MOV		R242 , R0 ,2 				;CJJ  2016.11
		MOVXR	R30 , 1 , 1					;CJJ  2016.11
		INC		R30 , 1 , 1					;CJJ  2016.11
		JS		R30 , R46 , DATA_N0ERROR	;CJJ  2016.11
			DEC	   R30, 1, 2				;LSZ  2016.12.17
			JS     R46, R30, DATA_N0ERROR	;LSZ  2016.12.17
				   GOTO	    displayF_RET	;LSZ  2016.12.17
	DATA_N0ERROR:
	    MOV		R242,R0,2
	    MOVXR   R46,0,1     
	    MOV		R244,R0,2
	    MOVXR	R46,0,1
		GOTO	displayF_RET	
    
displayF_RET:
RET

displayC:
	;R240=通信变量 ,R242=用户变量 ,R244=上1个循环的用户变量 ,R246=上1个循环的通信变量，R248=用户参数改动记录变量 ,R250=用户参数改动对应标志位
	;LDWR 	R0,03AA1H;	用户变量	华氏
    MOV		R242,R0,2
    MOVXR   R30,1,1;传给R30

    MOV		R244,R0,2
    MOVXR   R32,1,1;传给R32
    CJNE 	R30,R32,TEST5;++
    CJNE 	R31,R33,TEST5;++
    GOTO 	TEST4;++

    TEST5:;++
   ;LDWR    R0,0BC3H;ZSW/20160606;
   
    MOV		R248,R0,2
    MOVXR   R30,1,1
    
   ; LDWR    R32,0010H
   
    MOV		R250,R32,2
    OR      R30,R32,2
    MOVXR   R30,0,1
    
	;LDWR	R0,3AA0H;
	MOV		R240,R0,2
	MOVXR	R30,1,1
	;LDWR 	R0,3AA2H;++取出参数当前值，用于下一轮比较
	MOV		R246,R0,2
    MOVXR   R30,0,1	
	
	;LDWR	R0,3AA1H
	MOV		R242,R0,2
	MOVXR	R30,1,1
	;LDWR 	R0,3AA3H;++取出参数当前值，用于下一轮比较
    MOV		R244,R0,2
    MOVXR   R30,0,1

	;LDWR	R0,3AA1H;
	MOV		R242,R0,2
    MOVXR   R32,1,1
 
    ;LDWR    R0,3AA0H
    MOV		R240,R0,2
    MOVXR   R32,0,1     	
	GOTO	displayC_RET
	
	TEST4:
	;LDWR	R0,3AA0H;
	MOV		R240,R0,2
    MOVXR   R32,1,1

   ; LDWR    R0,3AA1H
    MOV		R242,R0,2
    MOVXR   R32,0,1     
    MOV		R244,R0,2
    MOVXR	R32,0,1
	GOTO	displayC_RET	
displayC_RET:
	RET	

judgeHysteresis:
	MOV		R242,R0,2
    MOVXR   R30,1,1;传给R30
    MOV		R244,R0,2
    MOVXR   R32,1,1;传给R32
    CJNE 	R30,R32,TEST20;++大多数情况下都是通信变量转化成华氏度再覆盖显示变量,只有显示变量发生变化时才会主动去覆盖通信变量
    CJNE 	R31,R33,TEST20;++
    GOTO 	TEST22;++
	
	TEST20:;这条逻辑后面检测出有问题，一些处理已经注销了，TEST0这个函数可以去掉了，懒得改
    MOV		R240,R0,2
    MOVXR	R30,1,1
    MOV		R246,R0,2
    MOVXR	R32,1,1
	
    MOV		R248,R0,2;不论是用户改的还是主板改的，都会置位参数改动标志位。之所以改成这个逻辑，是不能排除计算误差带来的影响。主板写过来的值，经过华氏摄氏互转后可能会使通信变量产生0.1摄氏度的误差，
    MOVXR   R30,1,1
    MOV		R250,R32,2
    OR      R30,R32,2
    MOVXR   R30,0,1

	MOV		R240,R0,2
	MOVXR	R30,1,1
	MOV		R246,R0,2
    MOVXR   R30,0,1	

	MOV		R242,R0,2
	MOVXR	R30,1,1
    MOV		R244,R0,2
    MOVXR   R30,0,1

	MOV		R242,R0,2
    MOVXR   R32,1,1
    
    INC		R32,1,160;实际显示也就是用户设定的温度，不是真的华氏度，而是减去了32之后的华氏度，所以这里计算时要加32，再参与转换运算。
    INC		R32,1,160
    
    CALL    conversionFtoC;Calculate_F_TO_C_judge
    MOV		R240,R0,2
    MOVXR   R46,0,1     	
	GOTO	judgeHysteresis_RET

	TEST22:
	MOV		R240,R0,2
    MOVXR   R32,1,1
    CALL    conversionCtoF;Calculate_C_TO_F_judge
    DEC		R46,1,160;减去32，摄氏度转化成华氏度后，显示给用户看的不是真的华氏度，而是减去32后的假华氏度。
    DEC		R46,1,160
	MOV		R242,R0,2
	MOVXR	R30,1,1
	INC		R30,1,1        				 ;lsz  12.14添加
	JS		R30,R46,hyCorrection
			DEC	   R30, 1, 2				;LSZ  2016.12.17
			JS     R46, R30, hyCorrection	;LSZ  2016.12.17
		GOTO	judgeHysteresis_RET
hyCorrection:		
 	MOV		R242,R0,2
 	MOVXR   R46,0,1
	MOV		R244,R0,2
   	MOVXR	R46,0,1	
	GOTO	judgeHysteresis_RET
		;/**11.10更改后**/

;	MOV		R240,R0,2
;    MOVXR   R32,1,1
;    CALL    conversionCtoF;Calculate_C_TO_F_judge
;    DEC		R46,1,160;减去32，摄氏度转化成华氏度后，显示给用户看的不是真的华氏度，而是减去32后的假华氏度。
;    DEC		R46,1,160;
;    MOV		R108,R0,2	
;	MOVXR   R46,0,1
;	
;	CJNE	R108,R242,hyCorrection1	;不相等时判断是因为误差还是主板要修改
;	CJNE	R109,R243,hyCorrection1
;		MOV	R108,R242,2
;		GOTO	displayF_RET
;	hyCorrection1:
;		DEC R244,1,1
;		CJNE	R108,R244,hyCorrection2	;此时为误差
;		CJNE	R109,R245,hyCorrection2
;		;MOV		R242,R244,2
;			GOTO displayF_RET
;	hyCorrection2:
;		INC		R244,1,2
;		CJNE	R108,R244,hyOverload	;此时为误差
;		CJNE	R109,R245,hyOverload
;		;	DEC	R244,1,1		
;		;	MOV	R244,R242,2
;			GOTO displayF_RET
;	hyOverload:
;		MOV	R242,R244,2
		;/**11.10更改后**/	
	
judgeHysteresis_RET:
	RET


conversionCtoF:
        LDWR    R40,FFFFH;-0.1摄氏度
        JS      R40,R32,Calculate_C_TO_F1;正数则跳转，负数往下走.
               
        	LDBR    R30,00H,2;R30:R31:R32:R33=00 00 ** **H
        	LDBR    R40,00H,1
        	LDBR    R41,01H,1
        	LDBR    R42,00H,2;R40:R41:R42:R43=00 01 00 00H
        	LDBR    R60,00H,8
        	SUB     R40,R30,R60;R66:R67,负数被转换成了正数参与后面的运算

     		MOV     R64,R30,4;R30:R31:R32:R33=00 00 ** **H
			LDBR    R34,00H,2
			LDWR    R36,0009H;R34:R35:R36:R37=00 00 00 09H
			LDBR    R40,00H,8;
			LDBR    R50,00H,6;
			LDWR    R56,0005H
			MAC     R30,R34,R40
			DIV     R40,R50,1;R46:R47即为 摄氏度*9/5 得到的商

			MOV     R46,R62,2;转移到R62:R63
			LDWR    R60,0000H;R60:R61:R62:R63=00 00 ** **
			LDBR    R40,00H,8
			LDBR    R30,00H,8
			LDBR    R70,00H,1
       		LDBR    R71,01H,1
       		LDBR    R72,00H,2;R70:741:R72:R73=00 01 00 00H
			LDWR    R50,0000H
			LDWR    R52,0140H;加320; R50:R51:R52:R53=00 00 01 40
				
			JS      R52,R62,2
				SUB     R50,R60,R40;+R46:R47	
				GOTO	conversionCtoF_RET
   		 	SUB     R60,R50,R30;R36:R37
    		SUB     R70,R34,R40;-R46:R47		
			GOTO	conversionCtoF_RET
		
 Calculate_C_TO_F1:

         	LDBR    R30,00H,2;R30:R31:R32:R33=00 00 ** **H
			LDBR    R34,00H,2
			LDWR    R36,0009H;R34:R35:R36:R37=00 00 00 09H
			LDBR    R40,00H,8;
			LDBR    R50,00H,6;
			LDWR    R56,0005H
			MAC     R30,R34,R40
			DIV     R40,R50,1;R46:R47即为 摄氏度*9/5 得到的商
			
			MOV     R46,R62,2;转移到R62:R63
			LDWR    R60,0000H
			LDBR    R40,00H,8
			LDWR    R50,0000H
			LDWR    R52,0140H;加320
			ADD     R60,R50,R40;R46：R47即为最终得到的华氏度值
           	GOTO    conversionCtoF_RET		
conversionCtoF_RET:	
	RET
	
conversionFtoC:
       
        LDWR    R40,0140H
        JS      R40,R32,Calculate_F_TO_C1;小于320则往下走，大于320则跳转
                     
        LDWR    R40,FFFFH;-0.1华氏度
        JS      R40,R32,Calculate_F_TO_C2;正数则跳转，负数往下走.      
   
        LDBR    R30,00H,2;R30:R31:R32:R33=00 00 ** **H
        LDBR    R40,00H,1
        LDBR    R41,01H,1
        LDBR    R42,00H,2;R40:R41:R42:R43=00 01 00 00H
        LDBR    R60,00H,8
        SUB     R40,R30,R60;R66:R67,负数被转换成了正数参与后面的运算
        		
		LDBR	R40,00H,2
		LDWR	R42,0140H
		LDBR	R50,00H,8
		ADD		R40,R64,R50;R56:R57,加上320之后的值。
				
		LDBR	R60,00H,2
		LDWR	R62,0005H
		LDBR	R40,00H,8
		MAC		R54,R60,R40;R46:R47
		
		LDBR    R50,00H,6
		LDWR    R56,0009H
	    DIV     R40,R50,1;R46:R47
	    
	    MOV     R44,R64,6
		
		LDBR	R50,00H,1
		LDBR	R51,01H,1
		LDBR	R52,00H,2
		LDBR	R40,00H,8
		SUB		R50,R64,R40;R46:R47,转化成负数	
	
		GOTO	conversionFtoC_RET

Calculate_F_TO_C1:;
		LDBR    R30,00H,2;R30:R31:R32:R33=00 00 ** **H
		LDBR    R34,00H,2
		LDWR    R36,0140H;R34:R35:R36:R37=00 00 00 09H
		LDBR    R40,00H,8;
		SUB     R30,R34,R40;R46:R47
			
		LDWR	R50,0000H;实测发现，当需要对变量进行乘法和除法时，要先进行乘法再做除法才能保证得到的数据结果更加精确
		LDWR	R52,0005H
		LDBR	R60,00H,8
		MAC		R44,R50,R60;R66:R67	
	
		LDBR	R50,00H,6
		LDWR	R56,0009H
	    DIV		R60,R50,1;R66:R67
	
		LDBR	R40,00H,8
		MOV		R60,R40,8;R46,R47
	
		GOTO    conversionFtoC_RET
		
		Calculate_F_TO_C2:

		LDBR	R40,00H,2
		LDWR	R42,0140H;R40:R41:R42:R43=00 00 01 40
		LDBR	R30,00H,2;R30:R31:R32:R33=00 00 ** **
		LDBR	R50,00H,8
		SUB		R40,R30,R50;R56:0
		
		LDBR	R60,00H,2
		LDWR	R62,0005H
		LDBR	R40,00H,8
		MAC		R54,R60,R40;R46:R47
	
		LDBR    R50,00H,6
		LDWR    R56,0009H
	    DIV     R40,R50,1;R46:R47
    
	    MOV     R44,R64,6			
		
		LDBR	R50,00H,1
		LDBR	R51,01H,1
		LDBR	R52,00H,2
		LDBR	R40,00H,8
		SUB		R50,R64,R40;R46:R47,转化成负数		
		GOTO	conversionFtoC_RET
		
	conversionFtoC_RET:
	RET


displayC_A:
	;A03
	LDWR	R240,0414H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0530H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0531H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C0AH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0002H;该类参数发生更改时，给标志存储变量对应的位置位为1

	   	MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;参数发生改变才比较，否则不进行范围比较，这样是为了调控这种范围相互牵制的参数，不加这个逻辑就会有问题
				GOTO	displayC_AO3
    	
	   	LDWR	R46,0064H;100,摄氏10°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;如果用户设定变量大于摄氏10度，则改为摄氏10度。
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FED4H; -300，摄氏-30°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
		
	displayC_AO3:
		CALL 	displayC;
	
	;A04
	LDWR	R240,0415H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0532H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0533H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C0BH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0002H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
	   	MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_A04
    	
	   	LDWR	R46,0064H;100,摄氏10°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;如果用户设定变量大于摄氏10度，则改为摄氏10度。
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FF6AH; -150，摄氏-15°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	
	displayC_A04:
	CALL	displayC;
		
	;A05 回差值
    LDWR	R240,0416H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0534H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0535H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C0CH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0002H;该类参数发生更改时，给标志存储变量对应的位置位为1
		   	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_A05
    	
	   	LDWR	R46,01F4H;500,摄氏50°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;如果用户设定变量大于摄氏50度，则改为摄氏50度。
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,000AH; 10,摄氏1°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1

		displayC_A05:
		CALL 	displayC;	
	
	;A06
    LDWR	R240,0417H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0536H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0537H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C0DH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0002H;该类参数发生更改时，给标志存储变量对应的位置位为1
			   	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_A06
    	
	   	LDWR	R46,0514H;1300,摄氏130°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,0258H; 600,摄氏60°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
		
	displayC_A06:
		CALL 	displayC;	
		
	;A18
	LDWR	R240,0420H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0538H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0539H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C16H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0002H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_A18
    	
	   	LDWR	R46,00C8H;200,摄氏20°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FEA2H; -350,摄氏-35°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
		
	displayC_A18:
		CALL 	displayC;		
displayC_A_RET:
RET
displayC_F:
	;F02
	LDWR	R240,042EH;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0550H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0551H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C24H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0002H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_F02
    	
	   	LDWR	R46,0258H;600,摄氏60°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FF6AH; -150,摄氏-15°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
		
	displayC_F02:
		CALL 	displayC;			
		
		
	;F03
	LDWR	R240,0430H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0552H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0553H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C26H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0002H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_F03
    	
	   	LDWR	R46,0258H;600,摄氏60°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FF6AH; -150,摄氏-15°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
		
	displayC_F03:
		CALL 	displayC;			
			
	
	;F05
	LDWR	R240,0434H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0554H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0555H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C2AH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0002H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_F05
    	
	   	LDWR	R46,0258H;600,摄氏60°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FF6AH; -150,摄氏-15°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
		
	displayC_F05:
		CALL 	displayC;				

	;F06
	LDWR	R240,0436H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0556H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0557H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C2CH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0002H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_F06
    	
	   	LDWR	R46,0258H;600,摄氏60°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FF6AH; -150,摄氏-15°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
		
	displayC_F06:
		CALL 	displayC;				
		
	;F15
	LDWR	R240,043BH;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0558H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0559H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C31H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0002H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_F15
    	
	   	LDWR	R46,0320H;800,摄氏80°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,00C8H; 200,摄氏20°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1

	displayC_F15:
		CALL 	displayC;				
	
	;F26
	LDWR	R240,0453H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,055AH;用户设定变量 摄氏度/华氏度
    LDWR	R244,055BH;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0A6EH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_F26
				
 	   	LDWR	R46,0190H; 400,摄氏40°C   	
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,0064H;100,摄氏10°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
		
	displayC_F26:
		CALL 	displayC;				
			
	
	;F27
	LDWR	R240,0454H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,055CH;用户设定变量 摄氏度/华氏度
    LDWR	R244,055DH;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0A6FH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_F27

		LDWR	R46,01F4H; 500,摄氏50°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,00C8H;200,摄氏20°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1	
		
		;LSZ 12.21添加
		;;;
		LDWR	R0,055AH;F26
	   	MOVXR	R46,1,1
	   	INC		R46,1,40		;F26+4°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;如果用户设定变量小于R08，则改为R08。
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
		
	displayC_F27:
		CALL 	displayC;			
displayC_F_RET:
RET

displayC_E:
	;E13
	LDWR	R240,0477H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0560H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0561H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C63H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_E13
    	
	   	LDWR	R46,0320H;800,摄氏80°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FED4H; -300,摄氏-30°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1	
	
	displayC_E13:
		CALL 	displayC;		
		
	;E16
	LDWR	R240,047AH;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0562H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0563H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C66H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_E16
				
		LDWR	R0,0564H; E17
    	MOVXR	R46,1,1
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FED4H; -300,摄氏-30°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1	

	displayC_E16:
		CALL 	displayC;				
		
	;E17
    LDWR	R240,047BH;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0564H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0565H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C67H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1

		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_E17
    	
	   	LDWR	R46,0320H;800,摄氏80°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R0,0562H; E16
    	MOVXR	R46,1,1
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1		

	displayC_E17:
		CALL 	displayC;		
		
	;E18	回差值
	LDWR	R240,047CH;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0566H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0567H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C68H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1	
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_E18
    	
	   	LDWR	R46,00C8H;200,摄氏20°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FF38H; -200,摄氏-20°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1	
		
	displayC_E18:
		CALL 	displayC;		
	
	;E19	回差值
	LDWR	R240,047DH;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0568H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0569H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C69H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_E19
    	
	   	LDWR	R46,00C8H;200,摄氏20°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FF38H; -200,摄氏-20°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1	

	displayC_E19:
		CALL 	displayC;		

	;E20	回差值
	LDWR	R240,047EH;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,056AH;用户设定变量 摄氏度/华氏度
    LDWR	R244,056BH;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C6AH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_E20
    	
	   	LDWR	R46,00C8H;200,摄氏20°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FF38H; -200,摄氏-20°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1	
		
	displayC_E20:
		CALL 	displayC;		
		
	;E22
	LDWR	R240,0480H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,056CH;用户设定变量 摄氏度/华氏度
    LDWR	R244,056DH;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C6CH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_E22
    	
	   	LDWR	R46,00C8H;200,摄氏20°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FF38H; -200,摄氏-20°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1	

	displayC_E22:
		CALL 	displayC;		

	;E29
	LDWR	R240,0487H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,056EH;用户设定变量 摄氏度/华氏度
    LDWR	R244,056FH;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C73H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_E29
    	
	   	LDWR	R46,04B0H;1200,摄氏120°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,02BCH; 700,摄氏70°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1	
	
	displayC_E29:
		CALL 	displayC;	
	
	;E30
	LDWR	R240,0488H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0570H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0571H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C74H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_E30
    	
	   	LDWR	R46,03E8H;1000,摄氏100°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,01F4H; 500,摄氏50°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1		

	displayC_E30:
		CALL 	displayC;		
		
	;E31
  	LDWR	R240,0489H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0572H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0573H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C75H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_E31
    	
	   	LDWR	R46,04B0H;1200,摄氏120°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,01F4H; 500,摄氏50°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1		

	displayC_E31:
		CALL 	displayC;		
displayC_E_RET:
RET

displayC_D:
		;D01
    LDWR	R240,045CH;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0580H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0581H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C48H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1	
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_D01
    	
	   	LDWR	R46,0032H;50,摄氏5°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FED4H; -300,摄氏-30°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			

	displayC_D01:
		CALL 	displayC;		
		
	;D02
	LDWR	R240,045EH;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0582H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0583H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C4AH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_D02
    	
		LDWR	R46,012CH;300,摄氏30°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,0000H; 0,摄氏0°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			
		
	displayC_D02:
		CALL 	displayC;			
		
	;D08
    LDWR	R240,0463H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0584H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0585H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C4FH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_D08
    	
	   	LDWR	R46,0064H;100,摄氏10°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FF38H; -200,摄氏-20°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			
		
	displayC_D08:
		CALL 	displayC;				
		
	;D09	回差值
	LDWR	R240,0464H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0586H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0587H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C50H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_D09
    	
	   	LDWR	R46,01F4H;500,摄氏50°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,000AH; 10,摄氏1°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			

	displayC_D09:
		CALL 	displayC;				
	
	;D10	回差值
	LDWR	R240,0465H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0588H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0589H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C51H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_D10
    	
	   	LDWR	R46,01F4H;500,摄氏50°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,000AH; 10,摄氏1°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			

	displayC_D10:
		CALL 	displayC;				
	
	;D11
    LDWR	R240,0467H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,058AH;用户设定变量 摄氏度/华氏度
    LDWR	R244,058BH;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C53H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_D11
    	
	   	LDWR	R46,01F4H;500,摄氏50°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FED4H; -300,摄氏-30°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			

	displayC_D11:
		CALL 	displayC;		

displayC_D_RET:
RET

displayC_R:
	;R01
    LDWR	R240,0491H;通信变量 摄氏度						;lsz 2016.10.8添加
  	LDWR	R242,0590H;用户设定变量 摄氏度/华氏度
   	LDWR	R244,0591H;上个循环的用户设定变量 摄氏度/华氏度
   	LDWR	R246,0C7DH;上个循环的通信变量 摄氏度
 	LDWR	R248,0BC3H;系统参数更改标志存储变量
   	LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_R01
				
		LDWR	R0,059AH;R09
	   	MOVXR	R46,1,1
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;如果用户设定变量大于R09，则改为R09。
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R0,0598H;R08
	   	MOVXR	R46,1,1
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;如果用户设定变量小于R08，则改为R08。
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
		
	displayC_R01:
		CALL 	displayC;				
		
	;R02
     LDWR	R240,0492H;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,0592H;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,0593H;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C7EH;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_R02
				
		LDWR	R0,059EH;R11
	   	MOVXR	R46,1,1
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;如果用户设定变量大于R11，则改为R11。
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R0,059CH;R10
	   	MOVXR	R46,1,1
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;如果用户设定变量小于R10，则改为R10。
			MOV		R46,R40,2
	   	MOVXR	R40,0,1

	displayC_R02:
		CALL 	displayC;			
	
	;R04	回差值
	 LDWR	R240,0493H;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,0594H;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,0595H;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C7FH;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	 
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_R04
    	
	   	LDWR	R46,0064H;100,摄氏10°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,0000H; 0,摄氏0°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1					

	displayC_R04:
		CALL 	displayC;			
		
	;R05	回差值
	 LDWR	R240,0494H;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,0596H;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,0597H;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C80H;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	 
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_R05
    	
	   	LDWR	R46,0064H;100,摄氏10°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,0000H; 0,摄氏0°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			 

	displayC_R05:
		CALL 	displayC;		
		
	;R08
	 LDWR	R240,0495H;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,0598H;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,0599H;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C81H;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	 
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_R08
				
		LDWR	R0,059AH; R09
    	MOVXR	R46,1,1
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FED4H; -300,摄氏-30°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1		 

	displayC_R08:
		CALL 	displayC;			
		
	;R09
	 LDWR	R240,0496H;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,059AH;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,059BH;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C82H;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1

		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_R09
    	
	   	LDWR	R46,0320H;800,摄氏80°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R0,0598H; R08
    	MOVXR	R46,1,1
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			 
	
	displayC_R09:
		CALL 	displayC;		
		
	;R10
	 LDWR	R240,0497H;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,059CH;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,059DH;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C83H;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	 
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_R10
				
		LDWR	R0,059EH; R11
    	MOVXR	R46,1,1
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FED4H; -300,摄氏-30°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1		 	 
		
	displayC_R10:
		CALL 	displayC;				
		
	;R11
     LDWR	R240,0498H;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,059EH;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,059FH;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C84H;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1	
	 
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_R11
    	
	   	LDWR	R46,03DEH;990,摄氏99°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R0,059CH; R10
    	MOVXR	R46,1,1
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			 	
		
	displayC_R11:
		CALL 	displayC;				

	;R15
	 LDWR	R240,0499H;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,05A0H;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,05A1H;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C85H;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	 
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_R15
    	
	   	LDWR	R46,00C8H;200,摄氏20°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FED4H; -300，摄氏-30°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1					

	displayC_R15:
		CALL 	displayC;			
		
	;R29
     LDWR	R240,049AH;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,05A2H;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,05A3H;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C86H;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1

		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_R29
    	
	   	LDWR	R46,0000H;0,摄氏0°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R0,05A4H; R30
    	MOVXR	R46,1,1
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			 
	
	displayC_R29:
		CALL 	displayC;		
		
	;R30
	 LDWR	R240,049BH;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,05A4H;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,05A5H;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C87H;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
 
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_R30
				
		LDWR	R0,05A2H; R29
    	MOVXR	R46,1,1
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FEA2H; -350,摄氏-35°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1		 	 

	displayC_R30:
		CALL 	displayC;			
		
	;R31
     LDWR	R240,049CH;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,05A6H;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,05A7H;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C88H;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	 
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_R31
    	
	   	LDWR	R46,0258H;600,摄氏60°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,00C8H;200,摄氏20°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			

	displayC_R31:
		CALL 	displayC;			

	;R32
	 LDWR	R240,04A7H;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,05A8H;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,05A9H;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C89H;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0008H;该类参数发生更改时，给标志存储变量对应的位置位为1

		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_R32
				
		LDWR	R0,05AAH; R33
    	MOVXR	R46,1,1
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,0064H; 100,摄氏10°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1		 	 

	displayC_R32:
		CALL 	displayC;			
		
	;R33
     LDWR	R240,04A8H;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,05AAH;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,05ABH;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C8AH;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0008H;该类参数发生更改时，给标志存储变量对应的位置位为1
	 
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_R33
    	
	   	LDWR	R46,0258H;600,摄氏60°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R0,05A8H; R32
    	MOVXR	R46,1,1
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			 
		
	displayC_R33:
		CALL 	displayC;			

	;R34
     LDWR	R240,04A9H;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,05ACH;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,05ADH;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C8BH;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0008H;该类参数发生更改时，给标志存储变量对应的位置位为1
	 
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayC_R34
    	
	   	LDWR	R46,0258H;600,摄氏60°C
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,00C8H;200,摄氏20°C
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1		 
	
	displayC_R34:
		CALL 	displayC;		
displayC_R_RET:
RET

displayC_T:
		;T01
	    LDWR	R0,07FDH;
    	MOVXR	R30,1,1
    	LDWR	R0,05B0H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
		
	;T02
		LDWR	R0,07FEH;
    	MOVXR	R30,1,1
    	LDWR	R0,05B1H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
		
	;T04
		LDWR	R0,0800H;
    	MOVXR	R30,1,1
    	LDWR	R0,05B3H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T05
		LDWR	R0,0801H;
    	MOVXR	R30,1,1
    	LDWR	R0,05B4H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  		
	;T06
		LDWR	R0,0802H;
    	MOVXR	R30,1,1
    	LDWR	R0,05B5H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T07
		LDWR	R0,0803H;
    	MOVXR	R30,1,1
    	LDWR	R0,05B6H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T08
		LDWR	R0,0804H;
    	MOVXR	R30,1,1
    	LDWR	R0,05B7H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T09
		LDWR	R0,0805H;
    	MOVXR	R30,1,1
    	LDWR	R0,05B8H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T10
		LDWR	R0,0806H;
    	MOVXR	R30,1,1
    	LDWR	R0,05B9H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T11
		LDWR	R0,0807H;
    	MOVXR	R30,1,1
    	LDWR	R0,05BAH 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T12
		LDWR	R0,0808H;
    	MOVXR	R30,1,1
    	LDWR	R0,05BBH 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T13
		LDWR	R0,0809H;
    	MOVXR	R30,1,1
    	LDWR	R0,05BCH 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T14
		LDWR	R0,080AH;
    	MOVXR	R30,1,1
    	LDWR	R0,05BDH 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T15
		LDWR	R0,080BH;
    	MOVXR	R30,1,1
    	LDWR	R0,05BEH 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T16
		LDWR	R0,080CH;
    	MOVXR	R30,1,1
    	LDWR	R0,05BFH 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T17
		LDWR	R0,080DH;
    	MOVXR	R30,1,1
    	LDWR	R0,05C0H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T18
		LDWR	R0,080EH;
    	MOVXR	R30,1,1
    	LDWR	R0,5C1H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T19
		LDWR	R0,080FH;
    	MOVXR	R30,1,1
    	LDWR	R0,5C2H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T20
		LDWR	R0,0810H;
    	MOVXR	R30,1,1
    	LDWR	R0,5C3H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T21
		LDWR	R0,0811H;
    	MOVXR	R30,1,1
    	LDWR	R0,5C4H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T22
		LDWR	R0,0812H;
    	MOVXR	R30,1,1
    	LDWR	R0,5C5H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T23
		LDWR	R0,0813H;
    	MOVXR	R30,1,1
    	LDWR	R0,5C6H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T24
		LDWR	R0,0814H;
    	MOVXR	R30,1,1
    	LDWR	R0,5C7H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T25
		LDWR	R0,0815H;
    	MOVXR	R30,1,1
    	LDWR	R0,5C8H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T26
		LDWR	R0,0816H;
    	MOVXR	R30,1,1
    	LDWR	R0,5C9H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T27
		LDWR	R0,0817H;
    	MOVXR	R30,1,1
    	LDWR	R0,5CAH 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T28
		LDWR	R0,0818H;
    	MOVXR	R30,1,1
    	LDWR	R0,5CBH 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T29
		LDWR	R0,0819H;
    	MOVXR	R30,1,1
    	LDWR	R0,5CCH 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T30
		LDWR	R0,081AH;
    	MOVXR	R30,1,1
    	LDWR	R0,5CDH 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T31
		LDWR	R0,081BH;
    	MOVXR	R30,1,1
    	LDWR	R0,5CEH 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T32
		LDWR	R0,081CH;
    	MOVXR	R30,1,1
    	LDWR	R0,5CFH 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T33
		LDWR	R0,081DH;
    	MOVXR	R30,1,1
    	LDWR	R0,5D0H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T34
		LDWR	R0,081EH;
    	MOVXR	R30,1,1
    	LDWR	R0,5D1H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T35
		LDWR	R0,081FH;
    	MOVXR	R30,1,1
    	LDWR	R0,5D2H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T36
		LDWR	R0,0820H;
    	MOVXR	R30,1,1
    	LDWR	R0,5D3H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T37
		LDWR	R0,0821H;
    	MOVXR	R30,1,1
    	LDWR	R0,5D4H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T38
		LDWR	R0,0822H;
    	MOVXR	R30,1,1
    	LDWR	R0,5D5H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T39
		LDWR	R0,0823H;
    	MOVXR	R30,1,1
    	LDWR	R0,5D6H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
	;T40
		LDWR	R0,0824H;
    	MOVXR	R30,1,1
    	LDWR	R0,5D7H 
    	MOVXR	R32,1,1
    	MOV		R30,R32,2
    	MOVXR   R32,0,1  
displayC_T_RET:
RET

displayF_A:
	;A03
	LDWR	R240,0414H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0530H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0531H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C0AH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0002H;该类参数发生更改时，给标志存储变量对应的位置位为1

	   	MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;参数发生改变才比较，否则不进行范围比较，这样是为了调控这种范围相互牵制的参数，不加这个逻辑就会有问题
				GOTO	displayF_AO3
    	
	   	LDWR	R46,01F4H;500,华氏50°F
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;如果用户设定变量大于华氏度50°F，则改为华氏50度。
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FF24H; -300，摄氏-30°C(-22°F --> -220 --> FF24)
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
		
	displayF_AO3:
		CALL 	displayF;
	
	;A04
	LDWR	R240,0415H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0532H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0533H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C0BH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0002H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
	   	MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_A04
    	
		LDWR	R46,01F4H;10°C/50°F
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;如果用户设定变量大于华氏50度，则改为华氏50度。
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,0032H; -150，摄氏-15°C ;华氏5°F，显示50
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	
	displayF_A04:
	CALL	displayF;
		
	;A05 回差值
    LDWR	R240,0416H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0534H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0535H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C0CH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0002H;该类参数发生更改时，给标志存储变量对应的位置位为1
		   	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_A05
    	
	   	LDWR	R46,0384H;500,摄氏50°C/假华氏90F，0384H
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,0012H; 10,摄氏1°C/假华氏1.8F，0012H
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1

		displayF_A05:
	;	CALL 	displayF;	
		CALL	judgeHysteresis


		
	;A06
    LDWR	R240,0417H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0536H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0537H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C0DH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0002H;该类参数发生更改时，给标志存储变量对应的位置位为1
			   	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_A06
    	
	   	LDWR	R46,0A64H;1300,摄氏130°C/266F,2660,A64H
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,0578H; 600,摄氏60°C/140F,1400,578H
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
		
	displayF_A06:
		CALL 	displayF;	
		
	;A18
	LDWR	R240,0420H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0538H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0539H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C16H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0002H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_A18
    	
	   	LDWR	R46,02A8H;200,摄氏20°C/68F,680,2A8H
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FEBAH; -350,摄氏-35°C/-31F,-310,FEBAH
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
		
	displayF_A18:
		CALL 	displayF;			
displayF_A_RET:
RET
displayF_F:
	;F02
	LDWR	R240,042EH;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0550H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0551H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C24H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0002H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_F02
    	
	   	LDWR	R46,0578H;600,摄氏60°C/140F,1400,578H
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R46,0032H; -150，摄氏-15°C ;华氏5°F，显示50
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
		
	displayF_F02:
		CALL 	displayF;			
		
		
	;F03
	LDWR	R240,0430H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0552H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0553H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C26H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0002H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_F03
    	
	   	LDWR	R46,0578H;600,摄氏60°C/140F,1400,578H
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R46,0032H; -150，摄氏-15°C ;华氏5°F，显示50
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
		
	displayF_F03:
		CALL 	displayF;			
			
	
	;F05
	LDWR	R240,0434H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0554H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0555H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C2AH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0002H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_F05
    	
	   	LDWR	R46,0578H;600,摄氏60°C/140F,1400,578H
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R46,0032H; -150，摄氏-15°C ;华氏5°F，显示50
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
		
	displayF_F05:
		CALL 	displayF;				

	;F06
	LDWR	R240,0436H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0556H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0557H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C2CH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0002H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_F06
    	
	   	LDWR	R46,0578H;600,摄氏60°C/140F,1400,578H
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R46,0032H; -150，摄氏-15°C ;华氏5°F，显示50
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
		
	displayF_F06:
		CALL 	displayF;				
		
	;F15
	LDWR	R240,043BH;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0558H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0559H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C31H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0002H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_F15
    	
	   	LDWR	R46,06E0H;800,摄氏80°C/176F,1760,6E0H
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,02A8H;200,摄氏20°C/68F,680,2A8H			
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1

	displayF_F15:
		CALL 	displayF;				
	
	;F26
	LDWR	R240,0453H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,055AH;用户设定变量 摄氏度/华氏度
    LDWR	R244,055BH;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0A6EH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_F26
				
 	   	LDWR	R46,0410H; 400,摄氏40°C/104F,1040,0410H
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R46,01F4H;10°C/50°F	
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
		
	displayF_F26:
		CALL 	displayF;				
			
	
	;F27
	LDWR	R240,0454H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,055CH;用户设定变量 摄氏度/华氏度
    LDWR	R244,055DH;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0A6FH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_F27

	   	LDWR	R46,04C4H;500,摄氏50°C/122F，04C4H	
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1

	   	LDWR	R46,02A8H;200,摄氏20°C/68F,680,2A8H	
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1	
		
;;;lsz 12.21 添加
		LDWR	R0,055AH;F26
	   	MOVXR	R46,1,1
	   	INC		R46,1,72		;F26+7.2(°F)
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;如果用户设定变量小于R08，则改为R08。
			MOV		R46,R40,2
	   	MOVXR	R40,0,1		
	   	
	displayF_F27:
		CALL 	displayF;			
displayF_F_RET:
RET
displayF_E:
	;E13
	LDWR	R240,0477H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0560H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0561H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C63H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_E13
    	
	   	LDWR	R46,06E0H;800,摄氏80°C/176F,1760,6E0H	
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R46,FE24H; -300，摄氏-30°C(-22°F --> -220 --> FF24)
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1	
	
	displayF_E13:
			;TEST
;		MOV		R244,R0,2
;		MOVXR	R181,1,1
;		LDWR	R0,3920H
;		MOVXR	R181,0,1
;		MOV		R242,R0,2
;		MOVXR	R181,1,1
;		LDWR	R0,3921H
;		MOVXR	R181,0,1		
		;test 值有没有进入函数	
		CALL 	displayF;		
		
	;E16
	LDWR	R240,047AH;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0562H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0563H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C66H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_E16
				
		LDWR	R0,0564H; E17
    	MOVXR	R46,1,1
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R46,FE24H; -300，摄氏-30°C(-22°F --> -220 --> FF24)
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1	

	displayF_E16:

		CALL 	displayF;				
		
	;E17
    LDWR	R240,047BH;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0564H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0565H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C67H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1

		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_E17
    	
	   	LDWR	R46,06E0H;800,摄氏80°C/176F,1760,6E0H		
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R0,0562H; E16
    	MOVXR	R46,1,1
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1		

	displayF_E17:
		CALL 	displayF;		
		
	;E18	回差值
	LDWR	R240,047CH;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0566H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0567H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C68H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1	
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_E18
    	
	   	LDWR	R46,02A8H;200,摄氏20°C/68F,680,2A8H		
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FFD8H; -200,摄氏-20°C/-4F,-40,FFD8H
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1	
		
	displayF_E18:
	;	CALL 	displayF;		
		CALL	judgeHysteresis
		
	;E19	回差值
	LDWR	R240,047DH;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0568H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0569H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C69H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_E19
    	
	   	LDWR	R46,0168H;200,摄氏20°C/假华氏度36F,360,0168H
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FE98H; -200,摄氏-20°C/假华氏度-36F,-360,FE98H
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1	

	displayF_E19:
	;	CALL 	displayF;	
		CALL	judgeHysteresis	

	;E20	回差值
	LDWR	R240,047EH;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,056AH;用户设定变量 摄氏度/华氏度
    LDWR	R244,056BH;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C6AH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_E20
    	
	   	LDWR	R46,0168H;200,摄氏20°C/假华氏度36F,360,0168H
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FE98H; -200,摄氏-20°C/假华氏度-36F,-360,FE98H
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1	
		
	displayF_E20:
	;	CALL 	displayF;		
		CALL	judgeHysteresis
		
	;E22
	LDWR	R240,0480H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,056CH;用户设定变量 摄氏度/华氏度
    LDWR	R244,056DH;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C6CH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_E22
    	
	   	LDWR	R46,0168H;200,摄氏20°C/假华氏度36F,360,0168H
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FE98H; -200,摄氏-20°C/假华氏度-36F,-360,FE98H
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1	

	displayF_E22:
		;CALL 	displayF;
		 CALL	judgeHysteresis

	;E29
	LDWR	R240,0487H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,056EH;用户设定变量 摄氏度/华氏度
    LDWR	R244,056FH;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C73H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_E29
    	
	   	LDWR	R46,09B0H;1200,摄氏120°C/248F,2480,09B0H
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,062CH;700,摄氏70°C/158F,1580,062CH
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1	
	
	displayF_E29:
		CALL 	displayF;	
	
	;E30
	LDWR	R240,0488H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0570H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0571H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C74H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_E30
    	
	   	LDWR	R46,0848H;1000,摄氏100°C/212F,2120,0848H
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,04C4H; 500,摄氏50°C/122F,1220,04C4H
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1		

	displayF_E30:
		CALL 	displayF;		
		
	;E31
  	LDWR	R240,0489H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0572H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0573H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C75H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_E31
    	
	   	LDWR	R46,09B0H;1200,摄氏120°C/248F,2480,09B0H	
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,04C4H;500,摄氏50°C/122F,1220,04C4H		
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1		

	displayF_E31:
		CALL 	displayF;		
displayF_E_RET:
RET

displayF_D:
	;D01
    LDWR	R240,045CH;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0580H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0581H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C48H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1	
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_D01
    	
	   	LDWR	R46,019AH;50,摄氏5°C/41F,410,019AH
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R46,FE24H; -300，摄氏-30°C(-22°F --> -220 --> FF24)
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			

	displayF_D01:

		CALL 	displayF;	


		;TEST END			
		
	;D02
	LDWR	R240,045EH;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0582H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0583H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C4AH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_D02
    	
		LDWR	R46,035CH;300,摄氏30°C/86F,860,035CH
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,0140H; 0,摄氏0°C/32F,320,0140H
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			
		
	displayF_D02:
		CALL 	displayF;			
		
	;D08
    LDWR	R240,0463H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0584H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0585H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C4FH;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_D08
    	
		LDWR	R46,01F4H;10°C/50°F		
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FFD8H; -200,摄氏-20°C/-4F,-40,FFD8H	
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			
		
	displayF_D08:
		CALL 	displayF;				
		
	;D09	回差值
	LDWR	R240,0464H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0586H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0587H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C50H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_D09
    	
	   	LDWR	R46,0384H;500,摄氏50°C/假华氏90F，0384H	
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R46,0012H; 10,摄氏1°C/假华氏1.8F，0012H
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			

	displayF_D09:
		;CALL 	displayF;				
		CALL	judgeHysteresis
	
	;D10	回差值
	LDWR	R240,0465H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,0588H;用户设定变量 摄氏度/华氏度
    LDWR	R244,0589H;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C51H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_D10
    	
	   	LDWR	R46,0384H;500,摄氏50°C/假华氏90F，0384H	
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R46,0012H; 10,摄氏1°C/假华氏1.8F，0012H
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			

	displayF_D10:
		;CALL 	displayF;				
		CALL	judgeHysteresis
		
	;D11
    LDWR	R240,0467H;通信变量 摄氏度						;lsz 2016.10.8添加
    LDWR	R242,058AH;用户设定变量 摄氏度/华氏度
    LDWR	R244,058BH;上个循环的用户设定变量 摄氏度/华氏度
    LDWR	R246,0C53H;上个循环的通信变量 摄氏度
    LDWR	R248,0BC3H;系统参数更改标志存储变量
    LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_D11
    	
	   	LDWR	R46,04C4H;500,摄氏50°C/122F,1220,04C4H	
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R46,FE24H; -300，摄氏-30°C(-22°F --> -220 --> FF24)
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			

	displayF_D11:
		CALL 	displayF;			
displayF_D_RET:
RET

displayF_R:
	;R01
    LDWR	R240,0491H;通信变量 摄氏度						;lsz 2016.10.8添加
  	LDWR	R242,0590H;用户设定变量 摄氏度/华氏度
   	LDWR	R244,0591H;上个循环的用户设定变量 摄氏度/华氏度
   	LDWR	R246,0C7DH;上个循环的通信变量 摄氏度
 	LDWR	R248,0BC3H;系统参数更改标志存储变量
   	LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_R01
				
		LDWR	R0,059AH;R09
	   	MOVXR	R46,1,1
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;如果用户设定变量大于R09，则改为R09。
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R0,0598H;R08
	   	MOVXR	R46,1,1
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;如果用户设定变量小于R08，则改为R08。
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
		
	displayF_R01:
		CALL 	displayF;				
		
	;R02
     LDWR	R240,0492H;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,0592H;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,0593H;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C7EH;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_R02
				
		LDWR	R0,059EH;R11
	   	MOVXR	R46,1,1
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;如果用户设定变量大于R11，则改为R11。
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R0,059CH;R10
	   	MOVXR	R46,1,1
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;如果用户设定变量小于R10，则改为R10。
			MOV		R46,R40,2
	   	MOVXR	R40,0,1

	displayF_R02:
		CALL 	displayF;			
	
	;R04	回差值
	 LDWR	R240,0493H;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,0594H;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,0595H;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C7FH;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	 
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_R04
    	
	   	LDWR	R46,00B4H;100,摄氏10°C/假华氏18F,180,00B4H
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,0000H; 0,摄氏0°C/假华氏0F，0，0000H
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1					

	displayF_R04:
	;	CALL 	displayF;			
		CALL	judgeHysteresis	
	
	;R05	回差值
	 LDWR	R240,0494H;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,0596H;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,0597H;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C80H;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	 
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_R05
    	
	   	LDWR	R46,00B4H;100,摄氏10°C/假华氏18F,180,00B4H
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,0000H; 0,摄氏0°C/假华氏0F，0，0000H
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			 

	displayF_R05:
	;	CALL 	displayF;		
		CALL	judgeHysteresis
	
	;R08
	 LDWR	R240,0495H;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,0598H;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,0599H;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C81H;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	 
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_R08
				
		LDWR	R0,059AH; R09
    	MOVXR	R46,1,1
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R46,FE24H; -300，摄氏-30°C(-22°F --> -220 --> FF24)
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1		 

	displayF_R08:
		CALL 	displayF;			
		
	;R09
	 LDWR	R240,0496H;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,059AH;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,059BH;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C82H;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1

		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_R09
    	
	   	LDWR	R46,06E0H;800,摄氏80°C/176F,1760,6E0H	
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R0,0598H; R08
    	MOVXR	R46,1,1
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			 
	
	displayF_R09:
		CALL 	displayF;		
		
	;R10
	 LDWR	R240,0497H;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,059CH;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,059DH;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C83H;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	 
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_R10
				
		LDWR	R0,059EH; R11
    	MOVXR	R46,1,1
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R46,FE24H; -300，摄氏-30°C(-22°F --> -220 --> FF24)
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1		 	 
		
	displayF_R10:
		CALL 	displayF;				
		
	;R11
     LDWR	R240,0498H;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,059EH;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,059FH;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C84H;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1	
	 
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_R11
    	
	   	LDWR	R46,0836H;990,摄氏99°C/210.2F,2102,0836H
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R0,059CH; R10
    	MOVXR	R46,1,1
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			 	
		
	displayF_R11:
		CALL 	displayF;				

	;R15
	 LDWR	R240,0499H;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,05A0H;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,05A1H;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C85H;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	 
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_R15
    	
	   	LDWR	R46,02A8H;200,摄氏20°C/68F,680,2A8H		
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R46,FE24H;-300,摄氏-30°C(-22°F --> -220 --> FF24)
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1					

	displayF_R15:
		CALL 	displayF;			
		
	;R29
     LDWR	R240,049AH;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,05A2H;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,05A3H;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C86H;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1

		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_R29
    	
		LDWR	R46,0140H; 0,摄氏0°C/32F,320,0140H
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R0,05A4H; R30
    	MOVXR	R46,1,1
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			 
	
	displayF_R29:
		CALL 	displayF;		
		
	;R30
	 LDWR	R240,049BH;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,05A4H;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,05A5H;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C87H;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
 
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_R30
				
		LDWR	R0,05A2H; R29
    	MOVXR	R46,1,1
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,FEBAH; -350,摄氏-35°C/-31F,-310,FEBAH
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1		 	 

	displayF_R30:
		CALL 	displayF;			
		
	;R31
     LDWR	R240,049CH;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,05A6H;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,05A7H;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C88H;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0004H;该类参数发生更改时，给标志存储变量对应的位置位为1
	 
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_R31
    	
	   	LDWR	R46,0578H;600,摄氏60°C/140F,1400,578H
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,02A8H;200,摄氏20°C/68F,680,2A8H	
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			

	displayF_R31:
		CALL 	displayF;			

	;R32
	 LDWR	R240,04A7H;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,05A8H;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,05A9H;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C89H;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0008H;该类参数发生更改时，给标志存储变量对应的位置位为1

		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_R32
				
		LDWR	R0,05AAH; R33
    	MOVXR	R46,1,1
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R46,01F4H;10°C/50°F		
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1		 	 

	displayF_R32:
		CALL 	displayF;			
		
	;R33
     LDWR	R240,04A8H;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,05AAH;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,05ABH;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C8AH;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0008H;该类参数发生更改时，给标志存储变量对应的位置位为1
	 
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_R33
    	
	   	LDWR	R46,0578H;600,摄氏60°C/140F,1400,578H
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
		LDWR	R0,05A8H; R32
    	MOVXR	R46,1,1
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1			 
		
	displayF_R33:
		CALL 	displayF;			

	;R34
     LDWR	R240,04A9H;通信变量 摄氏度						;lsz 2016.10.8添加
  	 LDWR	R242,05ACH;用户设定变量 摄氏度/华氏度
   	 LDWR	R244,05ADH;上个循环的用户设定变量 摄氏度/华氏度
   	 LDWR	R246,0C8BH;上个循环的通信变量 摄氏度
 	 LDWR	R248,0BC3H;系统参数更改标志存储变量
     LDWR	R250,0008H;该类参数发生更改时，给标志存储变量对应的位置位为1
	 
		MOV		R242,R0,2
		MOVXR	R20,1,1
		MOV		R244,R0,2
		MOVXR	R22,1,1
		CJNE	R20,R22,2
			CJNE	R21,R23,1;
				GOTO	displayF_R34
    	
	   	LDWR	R46,0578H;600,摄氏60°C/140F,1400,578H
	   	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R40,R46,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1
	   	
	   	LDWR	R46,02A8H;200,摄氏20°C/68F,680,2A8H	
    	MOV		R242,R0,2
	   	MOVXR	R40,1,1
	   	JS		R46,R40,1;
			MOV		R46,R40,2
	   	MOVXR	R40,0,1		 
	
	displayF_R34:
		CALL 	displayF;		
displayF_R_RET:
RET

displayF_T:
	;T01
	    LDWR	R0,07FDH;
    	MOVXR	R32,1,1
		CALL	conversionCtoF ;Calculate_C_TO_F_judge
    	LDWR	R0,05B0H 
    	MOVXR   R46,0,1  
		
	;T02
		LDWR	R0,07FEH;
    	MOVXR	R32,1,1
		CALL	conversionCtoF ;Calculate_C_TO_F_judge		
    	LDWR	R0,05B1H 
    	MOVXR   R46,0,1  
		
	;T04
		LDWR	R0,0800H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF		
    	LDWR	R0,05B3H 
    	MOVXR   R46,0,1  
		
	;T05
		LDWR	R0,0801H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF		
    	LDWR	R0,05B4H 
    	MOVXR   R46,0,1  	
		
	;T06
		LDWR	R0,0802H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF		
    	LDWR	R0,05B5H 
    	MOVXR   R46,0,1  
		
	;T07
		LDWR	R0,0803H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF
    	LDWR	R0,05B6H 
    	MOVXR   R46,0,1  
		
	;T08
		LDWR	R0,0804H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF		
    	LDWR	R0,05B7H 
    	MOVXR   R46,0,1  
		
	;T09
		LDWR	R0,0805H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF			
    	LDWR	R0,05B8H 
    	MOVXR   R46,0,1  
	;T10
		LDWR	R0,0806H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF			
    	LDWR	R0,05B9H 
    	MOVXR   R46,0,1  
	;T11
		LDWR	R0,0807H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF			
    	LDWR	R0,05BAH 
    	MOVXR   R46,0,1  
	;T12
		LDWR	R0,0808H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF			
    	LDWR	R0,05BBH 
    	MOVXR   R46,0,1  
	;T13
		LDWR	R0,0809H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF			
    	LDWR	R0,05BCH 
    	MOVXR   R46,0,1  
	;T14
		LDWR	R0,080AH;
    	MOVXR	R32,1,1
		CALL	conversionCtoF			
    	LDWR	R0,05BDH 
    	MOVXR   R46,0,1  
	;T15
		LDWR	R0,080BH;
    	MOVXR	R32,1,1
		CALL	conversionCtoF			
    	LDWR	R0,05BEH 
    	MOVXR   R46,0,1  
	;T16
		LDWR	R0,080CH;
    	MOVXR	R32,1,1
		CALL	conversionCtoF			
    	LDWR	R0,05BFH 
    	MOVXR   R46,0,1  
	;T17
		LDWR	R0,080DH;
    	MOVXR	R32,1,1
		CALL	conversionCtoF			
    	LDWR	R0,05C0H 
    	MOVXR   R46,0,1  
	;T18
		LDWR	R0,080EH;
    	MOVXR	R32,1,1
		CALL	conversionCtoF		
    	LDWR	R0,5C1H 
    	MOVXR   R46,0,1  
	;T19
		LDWR	R0,080FH;
    	MOVXR	R32,1,1
		CALL	conversionCtoF		
    	LDWR	R0,5C2H 
    	MOVXR   R46,0,1  
	;T20
		LDWR	R0,0810H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF			
    	LDWR	R0,5C3H 
    	MOVXR   R46,0,1  
	;T21
		LDWR	R0,0811H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF			
    	LDWR	R0,5C4H 
    	MOVXR   R46,0,1  
	;T22
		LDWR	R0,0812H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF					
    	LDWR	R0,5C5H 
    	MOVXR   R46,0,1  
	;T23
		LDWR	R0,0813H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF			
    	LDWR	R0,5C6H 
    	MOVXR   R46,0,1  
	;T24
		LDWR	R0,0814H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF		
    	LDWR	R0,5C7H 
    	MOVXR   R46,0,1
	;T25
		LDWR	R0,0815H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF			
    	LDWR	R0,5C8H 
    	MOVXR   R46,0,1
	;T26
		LDWR	R0,0816H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF			
    	LDWR	R0,5C9H 
    	MOVXR   R46,0,1 
	;T27
		LDWR	R0,0817H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF					
    	LDWR	R0,5CAH 
    	MOVXR   R46,0,1 
	;T28
		LDWR	R0,0818H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF			
    	LDWR	R0,5CBH 
    	MOVXR   R46,0,1 
	;T29
		LDWR	R0,0819H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF			
    	LDWR	R0,5CCH 
    	MOVXR   R46,0,1 
	;T30
		LDWR	R0,081AH;
    	MOVXR	R32,1,1
		CALL	conversionCtoF				
    	LDWR	R0,5CDH 
    	MOVXR   R46,0,1 
	;T31
		LDWR	R0,081BH;
    	MOVXR	R32,1,1
		CALL	conversionCtoF	
    	LDWR	R0,5CEH 
		MOVXR   R46,0,1 
	;T32
		LDWR	R0,081CH;
    	MOVXR	R32,1,1
		CALL	conversionCtoF			
    	LDWR	R0,5CFH 
		MOVXR   R46,0,1 
	;T33
		LDWR	R0,081DH;
    	MOVXR	R32,1,1
		CALL	conversionCtoF					
    	LDWR	R0,5D0H 
		MOVXR   R46,0,1 
	;T34
		LDWR	R0,081EH;
    	MOVXR	R32,1,1
		CALL	conversionCtoF							
    	LDWR	R0,5D1H 
		MOVXR   R46,0,1 
	;T35
		LDWR	R0,081FH;
    	MOVXR	R32,1,1
		CALL	conversionCtoF			
    	LDWR	R0,5D2H 
		MOVXR   R46,0,1 
	;T36
		LDWR	R0,0820H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF			
    	LDWR	R0,5D3H 
		MOVXR   R46,0,1 
	;T37
		LDWR	R0,0821H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF				
    	LDWR	R0,5D4H 
		MOVXR   R46,0,1 
	;T38
		LDWR	R0,0822H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF				
    	LDWR	R0,5D5H 
		MOVXR   R46,0,1 
	;T39
		LDWR	R0,0823H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF		
    	LDWR	R0,5D6H 
		MOVXR   R46,0,1 
	;T40
		LDWR	R0,0824H;
    	MOVXR	R32,1,1
		CALL	conversionCtoF		
    	LDWR	R0,5D7H 
		MOVXR   R46,0,1 
displayF_T_RET:
RET

preCtoF_A:
;A03
	LDWR	R0,0414H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,0530H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1
	;A04
	LDWR	R0,0415H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,0532H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1
	;A05
	LDWR	R0,0416H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
	DEC		R46,1,160;特殊处理，偏差值，这里要减去32。
    DEC		R46,1,160	
    LDWR	R0,0534H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1
	;A06
	LDWR	R0,0417H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,0536H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1
	;A18		
	LDWR	R0,0420H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,0538H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1	
preCtoF_A_RET:
RET
preCtoF_F:
	;F02
	LDWR	R0,042EH;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,0550H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1
	;F03
	LDWR	R0,0430H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,0552H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1
	;F05
	LDWR	R0,0434H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,0554H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1
	;F06
	LDWR	R0,0436H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,0556H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1
	;F15
	LDWR	R0,043BH;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,0558H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1
	;F26
	LDWR	R0,0453H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,055AH;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1
	;F27
	LDWR	R0,0454H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,055CH;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1	
preCtoF_F_RET:
RET
preCtoF_E:
	;E13
	LDWR	R0,0477H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,0560H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1		
	
	;E16
	LDWR	R0,047AH;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,0562H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1
	
	;E17
	LDWR	R0,047BH;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,0564H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1
	;E18
	LDWR	R0,047CH;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
	DEC		R46,1,160;特殊处理，偏差值，这里要减去32。
    DEC		R46,1,160	
    LDWR	R0,0566H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1
	;E19
	LDWR	R0,047DH;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
	DEC		R46,1,160;特殊处理，偏差值，这里要减去32。
    DEC		R46,1,160	
    LDWR	R0,0568H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1
	;E20
	LDWR	R0,047EH;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
	DEC		R46,1,160;特殊处理，偏差值，这里要减去32。
    DEC		R46,1,160	
    LDWR	R0,056AH;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1
	;E22
	LDWR	R0,0480H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
	DEC		R46,1,160;特殊处理，偏差值，这里要减去32。
    DEC		R46,1,160
    LDWR	R0,056CH;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1
	;E29
	LDWR	R0,0487H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,056EH;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1
	;E30
	LDWR	R0,0488H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,0570H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1
	;E31
	LDWR	R0,0489H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,0572H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1
	;;;tEST
		LDWR	R0,047AH
		MOVXR	R160,1,1
		LDWR	R0,3922H
		MOVXR	R160,0,1
		
		LDWR	R0,0562H
		MOVXR	R162,1,1
		LDWR	R0,3923H
		MOVXR	R162,0,1
;TEST		
preCtoF_E_RET:
RET
preCtoF_D:
;D01
	LDWR	R0,045CH;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,0580H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1
	;D02
	LDWR	R0,045EH;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,0582H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1	
	;D08
	LDWR	R0,0463H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,0584H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1	
	;D09
	LDWR	R0,0464H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
	DEC		R46,1,160;特殊处理，偏差值，这里要减去32。
    DEC		R46,1,160
    LDWR	R0,0586H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1		
	;D10	
	LDWR	R0,0465H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
	DEC		R46,1,160;特殊处理，偏差值，这里要减去32。
    DEC		R46,1,160	
    LDWR	R0,0588H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1	
	;D11
	LDWR	R0,0467H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,058AH;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1	
preCtoF_D_RET:
RET

preCtoF_R:
	;R01
	LDWR	R0,0491H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,0590H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1	
	;R02
	LDWR	R0,0492H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,0592H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1	
	;R04
	LDWR	R0,0493H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    DEC		R46,1,160;
    DEC		R46,1,160		
    LDWR	R0,0594H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1	
	;R05
	LDWR	R0,0494H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
   	DEC		R46,1,160
    DEC		R46,1,160		
    LDWR	R0,0596H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1	
	;R08
	LDWR	R0,0495H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,0598H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1	
	;R09
	LDWR	R0,0496H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,059AH;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1	
	;R10
	LDWR	R0,0497H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,059CH;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1	
	;R11
	LDWR	R0,0498H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,059EH;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1		
		;R15
	LDWR	R0,0499H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,05A0H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1	
		;R29
	LDWR	R0,049AH;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,05A2H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1	
		;R30
	LDWR	R0,049BH;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,05A4H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1	
		;R31
	LDWR	R0,049CH;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,05A6H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1	
		;R32
	LDWR	R0,04A7H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,05A8H;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1	
		;R33
	LDWR	R0,04A8H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,05AAH;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1	
		;R34
	LDWR	R0,04A9H;通信变量 摄氏度						
	MOVXR	R32,1,1
	CALL	conversionCtoF	
    LDWR	R0,05ACH;用户设定变量 摄氏度/华氏度
	MOVXR	R46,0,1	
	
preCtoF_R_RET:
RET

preCtoF_T:
preCtoF_T_RET:
RET

preFtoC_A:
	;A03
	LDWR	R0,0414H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0530H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1
	;A04
	LDWR	R0,0415H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0532H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1
	;A05
	LDWR	R0,0416H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0534H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1
	;A06
	LDWR	R0,0417H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0536H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1
	;A18
	LDWR	R0,0420H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0538H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1	
preFtoC_A_RET:
RET
preFtoC_F:
		;F02
	LDWR	R0,042EH;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0550H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1
	;F03
	LDWR	R0,0430H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0552H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1
	;F05
	LDWR	R0,0434H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0554H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1
	;F06
	LDWR	R0,0436H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0556H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1
	;F15
	LDWR	R0,043BH;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0558H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1
	;F26
	LDWR	R0,0453H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,055AH;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1
	;F27
	LDWR	R0,0454H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,055CH;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1
preFtoC_F_RET:
RET


preFtoC_E:
	;E13
	LDWR	R0,0477H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0560H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1
	;E16
	LDWR	R0,047AH;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0562H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1
	;E17
	LDWR	R0,047BH;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0564H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1
	;E18
	LDWR	R0,047CH;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0566H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1
	;E19
	LDWR	R0,047DH;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0568H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1
	;E20
	LDWR	R0,047EH;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,056AH;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1
	;E22L
	LDWR	R0,0480H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,056CH;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1
	;E29
	LDWR	R0,0487H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,056EH;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1
	;E30
	LDWR	R0,0488H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0570H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1
	;E31
	LDWR	R0,0489H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0572H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1
preFtoC_E_RET:
RET
preFtoC_D:
	;D01
	LDWR	R0,045CH;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0580H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1
	;D02
	LDWR	R0,045EH;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0582H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1	
	;D08
	LDWR	R0,0463H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0584H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1	
	;D09
	LDWR	R0,0464H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0586H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1		
	;D10
	LDWR	R0,0465H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0588H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1	
	;D11
	LDWR	R0,0467H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,058AH;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1	
preFtoC_D_RET:
RET

preFtoC_R:
	;R01
	LDWR	R0,0491H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0590H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1	
	;R02
	LDWR	R0,0492H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0592H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1	
	;R04
	LDWR	R0,0493H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0594H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1	
	;R05
	LDWR	R0,0494H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0596H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1	
	;R08
	LDWR	R0,0495H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,0598H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1	
	;R09
	LDWR	R0,0496H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,059AH;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1	
	;R10
	LDWR	R0,0497H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,059CH;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1	
	;R11
	LDWR	R0,0498H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,059EH;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1	
		;R15
	LDWR	R0,0499H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,05A0H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1	
		;R29
	LDWR	R0,049AH;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,05A2H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1	
		;R30
	LDWR	R0,049BH;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,05A4H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1	
		;R31
	LDWR	R0,049CH;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,05A6H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1	
		;R32
	LDWR	R0,04A7H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,05A8H;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1	
		;R33
	LDWR	R0,04A8H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,05AAH;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1	
		;R34
	LDWR	R0,04A9H;通信变量 摄氏度						
	MOVXR	R30,1,1
    LDWR	R0,05ACH;用户设定变量 摄氏度/华氏度
	MOVXR	R30,0,1	
preFtoC_R_RET:
RET

preFtoC_T:
preFtoC_T_RET:
RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;华氏摄氏转化完毕
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;延时函数:
;;为保证通信变量在conversion
;;执行前已经被传输完毕添加的延时函数,注销掉会出现F参数之后的参数在华氏开机数据异常的问题
;;所用地址：3924H
;;;;;;;;;;;;;;;;;;;;;
countToZero:
MOVDR	4AH,R30,2
LDWR	R0,3924H
MOVXR	R30,0,1
IJNE	R30,0,2
IJNE	R31,0,countToZero_RET
CALL	conversion		;华氏摄氏转化
countToZero_RET:
RET

;**********************************************
;**无操作30s后暗屏2min后熄屏
;**	05F1H~05F3H	保存计时
;** 05F4H~05F6H	保存计时
Display_On_Off:		
MOVDR	05H,R50,1  ;触摸坐标是否有更新
IJNE 	R50,5AH,TP_Sta_Get
	LDBR    R50,0,1;更新
	MOVRD   R50,05H,1
	GOTO	Touched_Screen
	
TP_Sta_Get:
MOVDR	06H,R40,1
IJNE	R40,0,Un_Touched_Screen
 						
	;****上电后一直没有触碰屏幕时，06H=0
	LDWR	R64,150;30S	系统200ms执行一次
	LDWR	R66,600;2min
	LDWR	R68,4000;自加上限，防止溢出
							
	LDWR	R0,05F1H
	MOVXR	R60,1,1
	JS		R68,R60,2
		INC		R60,1,1
		MOVXR	R60,0,1
			  	
;是否暗屏		  	
Display_if_Low1:  
MOVDR	01H,R31,1;取出当前亮度
LDBR	R30,0,1
LDWR	R32,4;亮度大于3，则需要暗屏，否则不需要
JS 		R30,R32,Display_if_Off1
JS 		R60,R64,Display_if_Off1
	LDBR	R30,3,1
	MOVRD	R30,01H,1;暗屏
	LDBR	R30,0,1
	MOVRD	R30,0BH,1;按键无效
						
;是否熄屏
Display_if_Off1: 
MOVDR	01H,R31,1;取出当前亮度
LDBR	R30,0,1
LDWR	R32,1;亮度大于0，则需要熄屏，否则不需要
JS 		R30,R32,Display_On_Off_RET  					
JS 		R60,R66,Display_On_Off_RET
	MOVRD	R30,01H,1;熄屏
	LDBR	R30,0,1
	MOVRD	R30,0BH,1;按键无效
	GOTO	Display_On_Off_RET
						
;**第一次触碰屏幕以后，当前未碰屏幕				
Un_Touched_Screen:
IJNE	R40,2,Touched_Screen;首次触碰了屏幕后，06H只有1、2、3三个值，1、3表示当前触碰了屏幕，2表示当前未触碰
	;当前未触碰
	LDWR	R64,150;30S
	LDWR	R66,600;2min
	LDWR	R68,4000;自加上限，防止溢出
						
	;LDWR	R0,0467H
	LDWR	R0,05F4H
	MOVXR	R60,1,1
	JS		R68,R60,2
			INC		R60,1,1
			MOVXR	R60,0,1
						
;是否暗屏		  	
Display_if_Low2: 
MOVDR	01H,R31,1;取出当前亮度
LDBR	R30,0,1
LDWR	R32,4;亮度大于3，则需要暗屏，否则不需要
JS 		R30,R32,Display_if_Off2				
JS 		R60,R64,Display_if_Off2
	LDBR	R30,3,1
	MOVRD	R30,01H,1;暗屏	
	LDBR	R30,0,1
	MOVRD	R30,0BH,1;按键无效
	  	
					  	
Display_if_Off2: 
MOVDR	01H,R31,1;取出当前亮度
LDBR	R30,0,1
LDWR	R32,1;亮度大于0，则需要熄屏，否则不需要
JS 		R30,R32,Display_On_Off_RET	
JS 		R60,R66,Display_On_Off_RET						
	LDBR	R30,0,1
	MOVRD	R30,01H,1;熄屏		
	LDBR	R30,0,1
	MOVRD	R30,0BH,1;另屏幕上的按键无效
	GOTO	Display_On_Off_RET						
						
						
;****************************第一次触碰屏幕以后，当前触碰了或长按了屏幕				
Touched_Screen:	
LDBR	R30,40H,1
MOVRD	R30,01H,1;亮屏	
LDBR	R30,FFH,1
MOVRD	R30,0BH,1;另屏幕上的按键有效
 	  					
MOVDR	01H,R34,1;取出当前亮度
IJNE	R34,0,Display_if_Off_Reclock;亮度=0，则跳到主界面
					  	
;					  	LDWR	R30,0;清空单台机组状态、机组参数、故障的页面中间变量
;					  	LDWR	R0,0412H;MKJ状态
;					  	MOVXR	R30,0,1
;					  	LDWR	R0,0413H;MKJ系统
;					  	MOVXR	R30,0,1
;					  	LDWR	R0,0414H;MKJ历史故障
;					  	MOVXR	R30,0,1
;					  	LDWR	R0,044CH;MKJ实时
;					  	MOVXR	R30,0,1					  	
;					  	
;					  	LDWR	R0,0416H;工程历史故障
;					  	MOVXR	R30,0,1
;					  						  	
;					  	LDWR	R0,0454H;MKJ状态
;					  	MOVXR	R30,0,1
;					  	LDWR	R0,0455H;MKJ系统
;					  	MOVXR	R30,0,1	
;					  	LDWR	R0,0456H;MKJ历史故障
;					  	MOVXR	R30,0,1
;					  	LDWR	R0,0462H;MKJ实时
;					  	MOVXR	R30,0,1
					  	
					  	LDBR	R30,01H,1
					  	LDWR	R31,0005H;16bit
					  	EXIT	R30,R31	  	;跳到主界面
					  	
	  					
			;***清空计时	
Display_if_Off_Reclock:	LDWR	R30,0  	
;						LDWR	R0,0464H
						LDWR	R0,05F1H
						MOVXR	R30,0,1
;						LDWR	R0,0467H
						LDWR	R0,05F4H
						MOVXR	R30,0,1

 Display_On_Off_RET:	RET


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;屏幕校验进入计数功能
;;;;;;;4s清空点击计数
;;;;;;touchCount	--	0610H
;;;;;;flagBit    	--  0611H
;;;;;;timerCount    --  0612H
;;;;;;;;;;;;;;;;;;;;;;;;;
screenEnterTest:
	LDWR	R0,0610H
	MOVXR	R30,1,1
	IJNE    R31,0,1		;判断是否有点击
	    RET   
	IJNE    R31,10,5
    	LDWR	R30,0091H   ;Page-145
    	MOVRD   R30,03H,2
    	LDWR    R30,0000H
    	MOVXR	R30,0,1
    	GOTO    timerCountReset1
	LDWR    R0,0611H
	MOVXR	R32,1,1
	IJNE    R33,0,subToZero1
	    LDWR    R32,0001H
	    MOVXR	R32,0,1	;flagBit置1
	    LDWR	R0,0612H
	    LDWR	R30,0014H	;200ms * 20 = 4s
		MOVXR	R30,0,1	
subToZero1:
    LDWR	R32,0001H ;计数下限,防止异常时溢出造成不可知破坏
    LDWR	R0,0612H
    MOVXR	R30,1,1
    JS		R30,R32,timerCountReset1     ;不知道为什么这里小于0后不跳转
        DEC    R30,1,1 
        MOVXR  R30,0,1  ;自减后再保存到timerCount里面
        RET
timerCountReset1:
    LDWR    R0,0610H
    LDWR	R30,0000H
    MOVXR	R30,0,1    ;touchCount清零
    LDWR	R0,0611H
    MOVXR	R30,0,1	   ;flagBit清零
    
    
screenEnterTest_RET:
RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;屏幕校验退出计数功能
;;;;;;;60s自动退出
;;;;;;touchCount	--	063FH
;;;;;;flagBit    	--  0613H
;;;;;;timerCount    --  0614H
;;;;;;;;;;;;;;;;;;;;;;;;;
screenExitTest:
	MOVDR    03H,R30,2
	IJNE	 R31,91H,screenExitTest_RET		;Page-145 屏幕校准页面
	    CALL    weatherCountTwo
	    LDWR    R0,0613H
	    MOVXR	R30,1,1
	    IJNE    R31,0,subToZero2
            init:
            LDWR    R30,0001H
            MOVXR	R30,0,1
            LDWR	R0,0614H
            LDWR	R30,300    ;300 * 200 ms = 1min
        	MOVXR	R30,0,1
        	CALL    clearGreenSqure
        subToZero2:
        LDWR    R32,0001H
        LDWR	R0,0614H
        MOVXR	R30,1,1
        JS      R30,R32,timerCountReset2
            DEC    R30,1,1
            MOVXR  R30,0,1     ;自减后保存到计时器里
            RET
        timerCountReset2:
            LDWR    R30,0041H       ;Page-65,负载第一页
            MOVRD	R30,03H,2
            LDWR    R0,0614H
    		LDWR	R30,0000H
   			MOVXR	R30,0,1    ;TimerCount清零
		    LDWR	R0,0613H
 		    MOVXR	R30,0,1	   ;flagBit清零
 		    RET
    weatherCountTwo:
        LDWR    R0,063FH
        MOVXR   R30,1,1
        IJNE    R31,2,screenExitTest_RET
			GOTO    timerCountReset2
screenExitTest_RET:
RET
;;;;;;;;;;;;
;;;初始化清除绿方块
;;;循环清零
;;;;;;;;;
clearGreenSqure:
    LDWR	R34,0618H
    LDWR	R32,063FH
    LDWR    R30,0000H
LOOP:
    JS      R32,R34,clearGreenSqure_RET
    	MOV		 R34,R0,2
        MOVXR    R30,0,1
        INC      R35,0,1
        GOTO     LOOP
clearGreenSqure_RET:
RET

;;;;;;
;屏幕校验
;;;;;
screenTest:
	CALL    screenEnterTest
	CALL    screenExitTest

	
screenTest_RET:
RET

;;;;;;;;;;;;;;;
;;;时间格式显示
;;;;;;;;;;;;;;;
;;;040CH --  摄氏度/华氏度   R30
;;;0650H --  月份（华氏）   
;;;0651H --  月份（摄氏）   
;;;0652H --  日   (华氏)   
;;;0653H --  日  （摄氏）  
;;;0660H --  描述指针-日(摄氏)  R40
;;;0670H --  描述指针-日（华氏）R42 
;;;0BCAH --  月（通信）   R32
;;;0BCBH --  日（通信）   R34
clockFormat:
	LDWR	R0,040CH
	MOVXR	R30,1,1
	LDWR	R0,0BCAH
	MOVXR	R32,1,1	
	LDWR	R0,0BCBH
	MOVXR	R34,1,1	  	
	LDWR	R0,0652H
	MOVXR	R34,0,1
	LDWR	R0,0653H
	MOVXR	R34,0,1
	IJNE	R31,0,formatF  ;摄氏度往下走
		;;;;月份
		LDWR	R0,0651H
		MOVXR	R32,0,1	
		LDWR	R0,0650H
		LDWR	R30,0000H
		MOVXR	R30,0,1
		;;;月份显示结束
		;;;日期
		LDWR	R0,0660H
		LDWR	R40,0653H
		MOVXR	R40,0,1
		
		LDWR	R0,0670H
		LDWR	R42,FFFFH
		MOVXR	R42,0,1
		
		LDWR	R0,0680H
		LDWR	R40,0653H
		MOVXR	R40,0,1
		
		LDWR	R0,0690H
		LDWR	R42,FFFFH
		MOVXR	R42,0,1
		;;;日期显示结束
		GOTO	clockFormat_RET
formatF:
	LDWR	R0,0650H
	MOVXR	R32,0,1	
	LDWR	R0,0651H
	LDWR	R30,0000H
	MOVXR	R30,0,1
	
	LDWR	R0,0660H
	LDWR	R40,FFFFH
	MOVXR	R40,0,1
		
	LDWR	R0,0670H
	LDWR	R42,0652H
	MOVXR	R42,0,1
	
	LDWR	R0,0680H
	LDWR	R40,FFFFH
	MOVXR	R40,0,1
		
	LDWR	R0,0690H
	LDWR	R42,0652H
	MOVXR	R42,0,1

clockFormat_RET:
RET	
;;;;
;;0654H  --进入时钟界面按钮
;;;;
systTimeSetJump:
LDWR	R0,0654H
MOVXR	R30,1,1
IJNE	R31,1,systTimeSetJump_RET
	LDWR	R0,040CH
	MOVXR	R32,1,1
	IJNE	R33,1,3
	    LDWR	R34,141
	    MOVRD	R34,03H,2
	    GOTO	clearClockFlag
	LDWR	R34,150
	MOVRD	R34,03H,2
clearClockFlag:
LDWR	R40,0000H
LDWR	R0,0654H
MOVXR	R40,0,1

systTimeSetJump_RET:
RET


;;;;;
;;0656H -- 遮挡图标 
;;;;;
hidSuTemp:
	MOVDR	03H,R40,2
	IJNE	R41,117,hidSuTemp_RET	;需要被遮挡的那一页
	LDWR	R0,0401H
	MOVXR	R30,1,1
	IJNE	R31,2,1
	    GOTO    hideSu2andSu4
	IJNE	R31,3,clearSu2andSu4
	
	hideSu2andSu4:
		LDWR	R0,0656H
		LDWR	R32,0001H
		MOVXR	R32,0,1
		GOTO	hidSuTemp_RET
		
	clearSu2andSu4:
		LDWR	R0,0656H
		LDWR	R32,0000H
		MOVXR	R32,0,1
		GOTO	hidSuTemp_RET

hidSuTemp_RET:
RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;定时时间设置
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ClockerSet:  
;	LDWR 	R200,1738H;;选择的是星期几
;	LDWR	R202,1739H;缓存上一次选择的星期
;	LDWR	R204,1730H;记录了是否启用星期日的定时，1730H-1736H存放每个星期的定时是否启用
;	LDWR	R206,1718H;界面中，用于设置当天定时是否启用的按钮地址
;	LDWR	R208,171AH;记录了星期日每小时定时记录  星期日:171AH171BH
;	LDWR	R210,1700H;界面中，用于设置当天每小时定时记录的起始地址；24小时1700H-1717H
	LDWR	R200, 06B0H ;选择的是星期几
	LDWR	R202, 06B1H ;缓存上一次选择的星期
	LDWR	R204, 06B2H ;记录是否启用星期日的定时，06B2H-06B8H存放周几的定时是否启用
	LDWR	R206, 06B9H ;DGUS界面中用于设置当天定时是否启用的按钮地址
	LDWR 	R208, 06F0H ;记录了当天每个小时定时记录24小时 06F0H-06FDH
	LDWR	R198, 06C0H ;DGUS中，用于设置当天每小时定时记录的起始地址：24小时06C0H-06D7H
ClockerBit:  
	MOV		R200,R0,2;
	MOVXR	R52,1,1; 
	MOV		R202,R0,2;
	MOVXR	R50,1,1;
	JS		R50,R52,TimeBits
	JS		R52,R50,TimeBits
TimeBiti:;位组合
	CALL	CalcWeekToR52R53; 
	MOV		R204,R36,2;
	LDWR	R40,01H;
	LDWR	R46,00H;
	MOV		R52,R46,2;
	CALL	R36R37SMACR40R41TOR46R47;R46R47 = R36R37 * R40R41 + R46R47
	MOV		R46,R2,2;  
	MOV		R206,R0,2;
	MOVXX	1;
	 
	MOV		R208,R46,2;
	LDWR	R40,02H;  
	MOV		R52,R36,2;
	CALL	R36R37SMACR40R41TOR46R47;R46R47 = R36R37 * R40R41 + R46R47 
	MOV		R46,R0,2; 
	
;	BITI R50,1700H;0-7小时
;	BITI R51,1708H;8-15小时
	BITI	R50, 06C0H ;0-7clock
	BITI 	R51, 06C8H ;8-15clock
	MOVXR	R50,0,1;
	LDWR	R50,00H;
;	BITI R50,1710H;16-23小时
 	BITI 	R50, 06D0H ;16-24clock
	INC	    R0,1,1;
	MOVXR 	R50,0,1;
	GOTO	TimeBitEnd; 
TimeBits:;位分解 
	MOV		R200,R0,2;
	MOVXR	R52,1,1; 
	MOV		R202,R0,2;
	MOVXR	R52,0,1; 
	 
	MOV		R200,R0,2;
	MOVXR	R52,1,1;
	CALL	CalcWeekToR52R53;  
	MOV		R208,R46,2;
	LDWR	R40,02H;  
	MOV		R52,R36,2;
	CALL	R36R37SMACR40R41TOR46R47;R46R47 = R36R37 * R40R41 + R46R47 
	
	MOV		R46,R0,2;  
	MOVXR 	R50,1,1; 
;	BITS R50,1700H;高8位
;	BITS R51,1708H;低8位
	BITS 	R50,06C0H;高8位
	BITS 	R51,06C8H;低8位	
	INC	 R0,1,1;
	MOVXR 	R50,1,1;
;	BITS R50,1710H; 高8位
    BITS 	R50, 06D0H ;16-24clock
	MOV		R204,R36,2;
	LDWR	R40,01H;
	LDWR	R46,00H;
	MOV		R52,R46,2;
	CALL	R36R37SMACR40R41TOR46R47;R46R47 = R36R37 * R40R41 + R46R47
	MOV		R46,R0,2;;R46R47 = 1830H * 01H + R46R47(星期)  
	MOV		R206,R2,2;
	MOVXX	1; 
TimeBitEnd:	
ClockerSet_RET:
RET;
GetCurWeekSetting: 
;	LDWR	R200,171AH;;星期日的定时记录地址   
	LDWR	R200,06F0H ;星期日的定时记录地址     	
	;;获取当天的每小时记录
	LDWR	R102,00H;
	CALL	GetCurWeekToR103;  
	MOV		R200,R46,2;
	LDWR	R40,02H;  
	MOV		R102,R36,2;
	CALL	R36R37SMACR40R41TOR46R47;R46R47 = R36R37 * R40R41 + R46R47  
	MOV		R46,R0,2;获取到当前星期的地址
	
	MOVXR 	R50,1,1; 
;	BITS	R50,1800H;高8位
;	BITS	R51,1808H;低8位
	BITS	R50, 06D8H; 高八位	
	BITS	R51, 06E0H; 低八位
	INC		R0,1,1;
	MOVXR 	R50,1,1;
;	BITS	R50,1810H; 高8位
	BITS	R50, 06E8H; 高八位
GetCurWeekSetting_RET:
RET;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;根据当前星期，获取定时记录
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TimeBitsByCurWeek: 
;	LDWR	R200,171AH;;星期日的定时记录地址 
;	LDWR	R202,1730H;;记录了是否启用星期日的定时，1730H-1736H存放每个星期的定时是否启用
;	LDWR	R204,1718H;界面中，用于设置当天定时是否启用的按钮地址
;	LDWR	R206,1738H;;选择的是星期几
	LDWR	R206, 06B0H ;选择的是星期几
	LDWR	R202, 06B2H ;记录是否启用星期日的定时，06B2H-06B8H存放周几的定时是否启用
	LDWR	R204, 06B9H ;DGUS界面中用于设置当天定时是否启用的按钮地址
	LDWR 	R200, 06F0H ;记录了当天每个小时定时记录24小时 06F0H-06FDH	
	
	;;获取当天的每小时记录
	LDWR	R102,00H;
	CALL	GetCurWeekToR103;  
	MOV		R200,R46,2;
	LDWR	R40,02H;  
	MOV		R102,R36,2;
	CALL	R36R37SMACR40R41TOR46R47;R46R47 = R36R37 * R40R41 + R46R47  
	MOV		R46,R0,2;获取到当前星期的地址
	
	MOVXR 	R50,1,1; 
;	BITS	R50,1700H;高8位
;	BITS	R51,1708H;低8位
	BITS	R50, 06C0H ;0-7clock
	BITS 	R51, 06C8H ;8-15clock
	INC		R0,1,1;
	MOVXR 	R50,1,1;
;	BITS	R50,1710H; 高8位
	BITS 	R50, 06D0H ;16-23clock 
   
   ;;获取启用标志的状态
	MOV		R202,R36,2;
	LDWR	R40,01H;
	LDWR	R46,00H;
	MOV		R102,R46,2;
	CALL	R36R37SMACR40R41TOR46R47;R46R47 = R36R37 * R40R41 + R46R47
	MOV		R46,R0,2;; 
	MOV		R204,R2,2;
	MOVXX	1; 设置启用图标
	
	;将选择状态设置为当天的
	LDWR	R102,00H;
	CALL	GetCurWeekToR103; 
	IJNE	R103,0,2;
	LDWR	R36,1;
	GOTO	SetWeek_END
	
	LDWR	R36,01H;   
	LDWR	R40,02H; 
	MOV		R102,R54,2;
SetWeek:	
	DEC		R54,1,1;
	LDWR	R46,00H; 
	CALL	R36R37SMACR40R41TOR46R47;R46R47 = R36R37 * R40R41 + R46R47
	MOV		R46,R36,2;
	IJNE	R55,0,SetWeek;  
SetWeek_END:   
	MOV		R206,R0,2;
	MOVXR	R36,0,1;  
TimeBitsByCurWeek_RET:
RET;
 
CalcWeekToR52R53:
	LDWR	R36,01H;
	LDWR	R40,02H;
	LDWR	R54,00H;
GetWeek:	
	LDWR	R46,00H;
	INC		R54,1,1;
	CALL	R36R37SMACR40R41TOR46R47;R46R47 = R36R37 * R40R41 + R46R47
	MOV		R46,R36,2;
	IJNE	R55,7,2;
	LDWR	R52,00H;星期日
	GOTO	GetWeek_END
	JS		R46,R52,GetWeek
	JS		R52,R46,GetWeek
	MOV		R54,R52,2;
GetWeek_END: 
CalcWeekToR52R53_RET:
RET;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;获取商和余数
;可用于计算得到十进制的小时,因为彩屏读出来的时间是用十六进制表示十进制
;小时21H == 小时21点  21H/10H == 2        21H%10H == 1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;输入：R36R37            被除数
;输入：R46R47            除数
;输出：R36R37			商数
;输出：R46R47			余数
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;R36R37 = R36R37 / R46R47
;R46R47 = R36R37 % R46R47
R36R37ModR46R47:
	LDBR	R40,0,6;R40R41R42R43R44R45R46R47 
	LDBR	R30,0,6;R30R31R32R33R34R35R36R37 
	DIV		R30,R40,0;得到的商(即时间/10)放到R30~R37,得到的余数(即时间%10)放到R46R47
R36R37ModR46R47_RET:
RET;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;R46R47 = R36R37 * R40R41 + R46R47
;输入：R36R37;十位00x1H
;输入：R46R47;个位00x2H
;输出：R47;十个位x1x2H(一个字节)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; LDWR	R36,2;十位
	; LDWR	R46,2;个位; 
	;LDWR	R40,0010H;将1629H*16 + 162AH的值给到R105--分
ReCombineBySmac:
	CALL	R36R37SMACR40R41TOR46R47;
ReCombineBySmac_RET:
RET;
R36R37SMACR40R41TOR46R47: ;	
	LDBR	R44,00H,2; 
	SMAC		R36,R40,R44; 
R36R37SMACR40R41TOR46R47_RET:
RET;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;获取当前星期
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GetCurWeekToR103:
	;星期：R103
	MOVDR 	23H,R103,1
GetCurWeekToR103_RET:
RET;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;功能：判断定时是否到达
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
Clocker: 
	CALL	GetCurWeekSetting;;获取今天的定时记录
	
;	LDWR	R200,1730H;星期日为起始
;	LDWR	R202,1737H;主界面定时图标
;	LDWR	R204,260BH;开关机地址
	LDWR	R200, 06B2H
	LDWR	R202, 06FEH
	LDWR	R204, 03F3H    ;lsz.ll 2017-04-6
	
;	LDWR	R206,1800H;GetCurWeekSetting将定时设置分解到这里，0点为起始地址 
	LDWR	R206, 06D8H 
	;年:R100、月R101、日：R102、星期：R103、时：R104、分：R105、秒：R106
	CALL	GetCurDateTimeToR100R106;获取当前时间
	;判断当前星期是否启用定时
	; LDWR	R36,1730H;星期日为起始
	MOV		R200,R36,2;
	LDWR	R40,01H;
	LDWR	R46,00H;
	MOV		R103,R47,1;
	CALL	R36R37SMACR40R41TOR46R47;R46R47 = R36R37 * R40R41 + R46R47
	MOV		R46,R0,2;;R46R47 = 1830H * 01H + R46R47(星期)
	MOVXR	R180,1,1;
	; LDWR 	R0,1737H ;主界面定时图标
	MOV		R202,R0,2;
	MOVXR 	R180,0,1 ;如果当天已启用定时，则主界面显示为绿色图标
	IJNE	R181,01H,Clocker_DisEnable;
Clocker_Enable:;定时已启动
	;如果当天已启用定时则在零点时刻，判断是否启用定时
	IJNE	R105,00H,Clocker_23_59_59;分
	IJNE	R106,00H,Clocker_23_59_59;秒
Clocker_XX_00_00:;越过零点：
	;;小时刚刚越过整点,则根据当前小时对应的设置值进行设置开关机状态
	;过了第1秒就不设置了  这里可以改一下，1秒的时候恐怕不够
	; LDWR	R170,260BH;开关机地址
	MOV		R204,R170,2;
	MOV		R206,R200,2;
	CALL	SetPowerByClock;
	GOTO	Clocker_RET;
Clocker_23_59_59:;准备越过零点，结束当天的定时(如果当天有定时，则会进入)
;重置值=当天定时使能&零时定时使能。即如果当天零时零分零秒，
	IJNE	R104,23H,Clocker_RET;时
	IJNE	R105,59H,Clocker_RET;分
	IJNE	R106,59H,Clocker_RET;秒

;这段代码是为了得到下一天0时的定时使能状态	，所以需要将星期+1，将小时置0 
	INC		R103,0,1;
	LDWR	R36,0000H;
	MOV		R103,R37,1;;这里是为了取下一天的定时状态，
	LDWR	R46,07; 由于+1后，值可能是7，而星期7是不存在的，星期是从0开始的，故做了一个%7的操作 
	CALL	R36R37ModR46R47
;得到下一天的地址
	; LDWR	R36,1730H;星期日为起始
	MOV		R200,R36,2;
	LDWR	R40,01H; 
	CALL	R36R37SMACR40R41TOR46R47;R46R47 = R36R37 * R40R41 + R46R47
	MOV		R46,R0,2;;R46R47 = 1830H * 01H + R46R47(星期)
	MOVXR	R180,1,1; 
	
;所以需要将星期+1，将小时置0
	LDBR	R104,00H,1;下一天的00时
	; LDWR	R170,260BH;开关机地址
	MOV		R204,R170,2; 
	MOV		R206,R200,2;
	CALL	SetPowerByClock;
Clocker_DisEnable:
Clocker_RET: 
RET;
 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;根据定时器中的设置，设置开关机状态
;输入：开关机地址		R170R171
;输入：当天是否使能定时 R180R181
;输入：当前小时	 		R104
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; LDWR	R170,260BH; 
	; LDWR	R180,
	; LDBR	R104,00H,1;
	;LDWR	R200,1700H;0点为起始地址 
SetPowerByClock: 
;计算得到十进制的小时，作为偏移量
;彩屏读出来的时间是用十六进制表示十进制 小时13H == 小时13点
	LDWR	R36,00H; 
	MOV		R104,R37,1; 
	LDWR	R46,10H;
	CALL	R36R37ModR46R47;
	LDWR	R40,10;
	CALL	ReCombineBySmac; ;R46R47 = R36R37 * R40R41 + R46R47
;从1700H加上偏移量
	LDWR	R40,01H;
	; LDWR	R36,1700H;0点为起始地址 
	MOV		R200,R36,2;
	CALL	R36R37SMACR40R41TOR46R47;得到当前“时”对应的设置地址;R46R47 = 1700H * 01H + R46R47 
	MOV		R46,R0,2;
	MOVXR	R46,1,1;将当前小时的状态读出
	
	  
	IJNE	R104,00H,GetLastHour;在0点时刻，就不取上一个小时啦
	GOTO	GetThisHour;
GetLastHour:;需要取出上一个小时的使能状态作为判断
;	DEC		R0,1,1;
;	MOVXR	R48,1,1;
;	XOR		R48,R46,2;只有在当前小时和上一个小时的使能状态不一致时才去重置开关机	;lsz.ll 4-8注销
;	IJNE	R49,01H,SetPowerByClock_RET;
GetThisHour: ;获取当前小时的使能状态即可
;这里采用AND，可以省略了两层判断，当天使能，并且00时使能，才为1，否则为0
;这个功能在23:59:59时的处理中，尤为管用
	AND		R46,R180,2;Clocker中的R180，当天是否使能
	MOV		R170,R0,2;
	MOVXR	R46,0,1;
SetPowerByClock_RET:
RET;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;获取当前日期时间
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GetCurDateTimeToR100R106:
	;年:R100、月R101、日：R102、星期：R103、时：R104、分：R105、秒：R106
	MOVDR 	20H,R100,7;
GetCurDateTimeToR100R106_RET:
RET;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;将设定的定时时间保存到数据库
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Clocker_Save:
;	LDWR	R200,16FFH;;时钟设定保存1700H--1740H，16FFH为故障头
	LDWR	R200, 06AFH	;06AF-06FF
	LDWR 	R40,5AA5H;
	MOV		R200,R0,2;
	MOVXR 	R40,0,1

	LDBR 	R4,02H,1;加载用户数据库地址02 86 00 A0到R4、R5、R6、R7:预留到02 86 00 FF
	LDBR 	R5,86H,1	
	LDBR 	R6,00H,1
	LDBR 	R7,90H,1; 
	MOV		R200,R0,2;
;	MOVXL 	3,0040H;模式3--DGUS变量到用户数据库，30H个字长度:
	MOVXL	3, 0050H 
Clocker_Save_Ret:
RET;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;上电时候，需要加载用户历史定时
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Clocker_Recover:;上电恢复时钟设置1700H--1740H
;	LDWR	R200,16FFH;;时钟设定保存1700H--1740H，16FFH为故障头
	LDWR	R200, 06AFH 
;	LDWR 	R202,1740H;终点
	LDWR	R202, 06FFH	
	
	LDBR 	R4,02H,1;加载用户数据库地址02 86 00 A0到R4、R5、R6、R7--加一个故障头0x5A5AH
	LDBR 	R5,86H,1
	LDBR 	R6,00H,1
	LDBR 	R7,90H,1
	; LDWR 	R0,16FFH;(16FFH-1740H)
	MOV		R200,R0,2;
	MOVXL 	2,0050H;模式2--用户数据库到DGUS变量，50H个字长度

	; LDWR 	R0,16FFH;判读故障头
	MOV		R200,R0,2;
	MOVXR 	R40,1,1
	IJNE 	R41,A5H,Clock_Cleaner;判断是否符合故障头条件，不满足就清空----去除乱码
	IJNE 	R40,5AH,Clock_Cleaner;判断是否符合故障头条件，不满足就清空----去除乱码
	GOTO	Clocker_Recover_Ret 
;如果发现历史定时时间读取时候出问题了
;就清除，避免读取到无效时间 
Clock_Cleaner:  
	LDBR 	R80,0,32; 
	; LDWR 	R140,16FFH;;清除所有
	MOV		R200,R140,2;
	; LDWR 	R176,1740H;
	MOV		R202,R176,2;
cycle_cleaner_clock:
	MOV 	R140,R0,2
	MOVXR 	R80,0,16
	INC 	R140,1,0010H
	JS		R140,R176,cycle_cleaner_clock;这里是个清理循环
	CALL 	Clocker_Save;保存
Clock_Cleaner_Ret: 
Clocker_Recover_Ret:
RET;
 

doClockerSave:	
    LDWR    R0, 06AEH	;计时寄存器
    MOVXR	R36, 1, 1
    INC     R36, 1, 1
    LDWR	R46, 50
    CALL	R36R37ModR46R47
    MOVXR	R46, 0, 1
    IJNE	R47, 0, doClockerSave_RET
        CALL    Clocker_Save
 
 doClockerSave_RET:
 RET


;;;;;;;;;;;;;
;;;;新增函数调用
;;;;;;;;;;;;
newlyAddedFeature:

CALL 	systTimeSet		;系统时钟设置
CALL 	failureReback	;故障页面调回
CALL	enterFalog		;实时故障才能进入主界面
CALL 	inMainPage		;主界面显示判断到底该显示哪一个
CALL 	inModePage		;控制模式选择
;CALL 	Judge_DisplayF26;单风腔并联机型的控制		lsz 12.22注销(功能取消)
CALL 	circleDisplay	;主界面旋转图标的显示
CALL	countToZero		;计时器，倒计时640*4ms后再调用转化

CALL    screenTest		;屏幕校验功能

CALL	Display_On_Off ;熄屏
CALL    clockFormat		;日期格式

CALL    systTimeSetJump

CALL	hidSuTemp

CALL	ClockerSet		;7*24定时
CALL	Clocker			;判断定时启动
;CALL	Clocker_Save	;保存定时
CALL	doClockerSave	;30S自动定时
newlyAddedFeature_RET:
RET
;;;;;;;;;;;;;
;;;;新增函数调用结束
;;;;;;;;;;;;


