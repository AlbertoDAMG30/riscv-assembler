#All rights reserved
#Copyright belongs to Ernesto Rivera
#You can use this code freely in your project(s) as long as credit is given :)

#Inspiration taken from a MIPS assembly version done by: https://github.com/AndrewHamm/MIPS-Pong for the 
#MARS emulator

#The official repository of the RARS emulator can be found in: https://github.com/TheThirdOne/rars

# To run the project:
# 1) In the upper bar go to Run->Assemble (f3)
# 2) In the upper bar go to Tools->Bitmap Display
# 3) Configure the following settings in in the Bitmap Display:
	# a) Unit Width: 8
	# b) Unit Height: 8
	# c) Display Width: 512
	# d) Display Height: 256
	# e) Base Address: gp
	# f) Press connect to program 
# 4) In the upper bar go to Tools->Keyboard and Display MMIO Simulator and press connect to MIPS
# 5) In the upper bar go to Run->Go (f5)
# 6) Click on the lower window of the Keyboard and Display simulator to produce inputs

#Player movement is w and s for the left player and o and l for the right player.

#FOR THE STUDENTS: Internal labels of a function starts with a .

# Here I define the constants that will be used along the code
.eqv TOTAL_PIXELS, 8192 # The total ammount of pixels in the screen
.eqv FOUR_BYTES, 4 # The displacement in memory is done words which equals four bytes

.eqv TITLE_SCREEN_FIRST_LINE_ROW_Y, 0
.eqv TITLE_SCREEN_SECOND_LINE_ROW_Y, 12
.eqv TITLE_SCREEN_THIRD_LINE_ROW_Y, 29

.eqv PONG_TEXT_X, 21
.eqv PONG_TEXT_Y, 5
.eqv PONG_TEXT_H, 5

.eqv BLOQUE1_X 4
.eqv BLOQUE1_Y 4

.eqv PRESS_TEXT_X, 20
.eqv PRESS_TEXT_Y, 16
.eqv PRESS_TEXT_H, 4

.eqv NAME_TEXT_X 23
.eqv NAME_TEXT_Y 23
.eqv NAME_TEXT_H, 4




.eqv KEY_INPUT_ADDRESS 0xFFFF0004
.eqv KEY_STATUS_ADDRESS 0xFFFF0000
# For reference of those addreses check https://www.it.uu.se/education/course/homepage/os/vt18/module-1/memory-mapped-io/

.eqv ASCII_1 0x00000031
.eqv ASCII_2 0x00000032

.eqv MOV_STAY 0
.eqv MOV_UP 1
.eqv MOV_DOWN 2
.eqv MOV_LEFT 3
.eqv MOV_RIGHT 4
.eqv BOMB 1

.eqv INITIAL_PADDLE_POSITION 1

.eqv SCORE_FIRST_ROW_POINTS 5
.eqv SCORE_SECOND_ROW_POINTS 6
.eqv ROW_1 1
.eqv ROW_3 3
.eqv P1_SCORE_COLUMN 1
.eqv GAME_WIN_POINTS 10

.eqv TOP_PADDLE_Y_ROW 0
.eqv BOTTOM_PADDLE_Y_ROW 29 #  31 - 2= 29 Thats the lowest point that paddle y can reach
.eqv INIT_PADDLE_X_ROW 0
.eqv END_PADDLE_X_ROW 61 #  63- 2 = 61 Thats the lowest point that paddle y can reach

.eqv PLAYER_1_PADDLE_X_POS 1

.eqv FIRST_COLUMN 0
.eqv LAST_COLUMN 63

# The constants for the ball-pallet collision position
.eqv TOP_HIGH 0
.eqv TOP_MID 1
.eqv TOP_LOW 2
.eqv BOTTOM_HIGH 3
.eqv BOTTOM_MID 4
.eqv BOTTOM_LOW 5

# The vertical wall limists
.eqv Y_DOWN_LIMIT 31
.eqv Y_UP_LIMIT 0

# The horizontal wall limists
.eqv X_INIT_LIMIT 0
.eqv X_END_LIMIT 63

.eqv Y_MAX_COLLISION_VELOCITY 1

# Player modes
.eqv ONE_PLAYER_MODE 1
.eqv TWO_PLAYER_MODE 2


# ASSCII characters

.eqv ASCII_W 119
.eqv ASCII_S 115
.eqv ASCII_A 97
.eqv ASCII_D 100
.eqv ASCII_B 98
.eqv ASCII_SPACE 32

# The coordinmates of the end game screen

.eqv P_CHAR_WIN_X 26
.eqv P_CHAR_WIN_Y 5
.eqv P_CHAR_WIN_H 5

.eqv PLAYER_NUM_WIN_X 33
.eqv PLAYER_NUM_WIN_Y 5
.eqv PLAYER_NUM_WIN_H 5

.eqv WINS_TEXT_X, 21
.eqv WINS_TEXT_Y, 12
.eqv WINS_TEXT_H, 5
.eqv I_OFFSET 8
.eqv N_OFFSET 14

.eqv GAME_OVER_X 12
.eqv GAME_OVER_Y 12

.eqv PLAYER_X 2
.eqv PLAYER_Y 2

.eqv ENEMY_X 26
.eqv ENEMY_Y 22

.eqv ENEMY2_X 10
.eqv ENEMY2_Y 18

.eqv ENEMY3_X 22
.eqv ENEMY3_Y 2

.eqv ENEMY_2X 2
.eqv ENEMY_2Y 22

.eqv ENEMY2_2X 26
.eqv ENEMY2_2Y 10

.eqv ENEMY3_2X 10
.eqv ENEMY3_2Y 8

.eqv ENEMY_3X 2
.eqv ENEMY_3Y 22

.eqv ENEMY2_3X 26
.eqv ENEMY2_3Y 10

.eqv ENEMY3_3X 10
.eqv ENEMY3_3Y 8

.eqv NIVEL_X 31
.eqv NIVEL_Y 8

.eqv PUERTA1_X 2
.eqv PUERTA1_Y 22

.eqv PUERTA2_X 26
.eqv PUERTA2_Y 8

.eqv PUERTA3_X 10
.eqv PUERTA3_Y 16

.eqv PTS_X 31
.eqv PTS_Y 16


 # Begin of the data section
.data
	color_white:	.word 0x00ffffff
	color_black:	.word 0x00000001
	color_red:	.word 0x00ff0000
	color_cyan: 	.word 0x0000ffff
	color_orange:	.word 0x00FF8000
	color_orange1:	.word 0x00FF8001
	color_gold:	.word 0x00ffbf00
	color_green:	.word 0x0000913f
	color_green2:	.word 0x00009140
	color_green3:	.word 0x00009141
	color_niveles:	.word 0x00e6ed07
	color_gray:	.word 0x00828282
	color_cafe:	.word 0x005dc1b9
	color_puerta:	.word 0x000008FF
	color_magenta:	.word 0x00A901DB
	color_amarillo:	.word 0x00F5DF04
	color_amarillo1:.word 0x00F5DF05
	color_green2res:.word 0x00009140
	color_green3res:.word 0x00009141
	player_mode:	.word 0
		

	computer_count:	.word 0
	computer_speed:	.word 0		#Used after first collision	
	
	
	player_x:	.word 2
	player_y:	.word 2
	inmortal:	.word 0
	inmortal_time:	.word 250
	
	bomb1_x:	.word 0
	bomb1_y:	.word 0
	bomb_state1:	.word 0
	bomb_time1:	.word 100
	
	LIFE_X:		.word 31
	LIFE_Y: 	.word 1

	enemy_x:	.word 26
	enemy_y:	.word 22
	enemy_move:	.word 15
	enemy_life:	.word 1
	cont_enemy:	.word 0
	
	enemy2_x:	.word 10
	enemy2_y:	.word 18
	enemy2_move:	.word 15
	enemy2_life:	.word 1
	cont_enemy2:	.word 0
	
	enemy3_x:	.word 22
	enemy3_y:	.word 2
	enemy3_move:	.word 15
	enemy3_life:	.word 1
	cont_enemy3:	.word 0
	
	next_level_x:	.word 2
	next_level_y:	.word 6
	nivel:		.word 1
	
	life1:		.word 1
	life2:		.word 1
	life3:		.word 1
	
	COUNTER:	.word 0
.text

new_game:
	jal clear_board
	jal draw_title_screen
	sw zero,COUNTER,t6
	select_1_or_2_players:
    	lw t0, KEY_INPUT_ADDRESS # Verify if the player pressed an input
    	li t1, ASCII_1
    	beq t0, t1, start_game
    	
    	li a0, 150
    	li a7, 32

    	
    	j select_1_or_2_players # If a key was not pressed go back to the loop
    	
    	
    start_game:
    	sw zero, KEY_STATUS_ADDRESS, t0 # This clears the status if a key was pressed
    
    j new_round
    	
    		
    				
gameover_inicio:
	jal clear_board
	jal draw_game_over
	li t0,1
	sw t0,nivel,t1
	
	push_space:
    	lw t0, KEY_INPUT_ADDRESS # Verify if the player pressed an input
    	li t1, ASCII_SPACE
    	beq t0, t1, nuevojuego
    	
  	j push_space
  	
  	nuevojuego:
  	sw zero, KEY_STATUS_ADDRESS, t0
	
	j new_game
win_inicio:
	jal clear_board
	jal draw_win
	
	precionar_space:
    	lw t0, KEY_INPUT_ADDRESS # Verify if the player pressed an input
    	li t1, ASCII_SPACE
    	beq t0, t1, nuevojue
    	
  	j precionar_space
  	
  	nuevojue:
  	sw zero, KEY_STATUS_ADDRESS, t0
	
	j new_game
	

draw_contador:
	addi sp,sp,-4
	sw ra,0(sp)
	
	li t0,1

	lw a5,enemy_life
	lw a6,enemy2_life
	lw a7,enemy3_life
	lw a4,nivel
	lw s7,COUNTER
	li a3,1
	
	beq a4,a3,onelevel
	addi a3,a3,1
	beq a4,a3,twolevel
	addi a3,a3,1
	beq a4,a3,threelevel
	j sale
	
	
	onelevel:
	
		bnez a5,secondenemy
		lw t5,cont_enemy
		bnez t5,secondenemy
		sw t0,cont_enemy,t2
		addi s7,s7,1
		sw s7,COUNTER,t2
		j secondenemy
		
		secondenemy:
		bnez a6,thirdenemy
		lw t5,cont_enemy2
		bnez t5,thirdenemy
		sw t0,cont_enemy2,t2
		addi s7,s7,1
		sw s7,COUNTER,t2
		j thirdenemy
		
		thirdenemy:
		bnez a7,uno
		lw t5,cont_enemy3
		bnez t5,uno
		sw t0,cont_enemy3,t2	
		addi s7,s7,1
		sw s7,COUNTER,t2
		j uno
		
	
	twolevel:
		bnez a5,secondenemy2
		lw t5,cont_enemy
		bnez t5,secondenemy2
		sw t0,cont_enemy,t2
		addi s7,s7,1
		sw s7,COUNTER,t2
		j secondenemy2
		
		secondenemy2:
		bnez a6,thirdenemy2
		lw t5,cont_enemy2
		bnez t5,thirdenemy2
		sw t0,cont_enemy2,t2
		addi s7,s7,1
		sw s7,COUNTER,t2
		j thirdenemy2
		
		thirdenemy2:
		bnez a7,tres
		lw t5,cont_enemy3
		bnez t5,tres
		sw t0,cont_enemy3,t2
		addi s7,s7,1
		sw s7,COUNTER,t2
		j cuatro
	
	threelevel:
		bnez a5,secondenemy3
		lw t5,cont_enemy
		bnez t5,secondenemy3
		sw t0,cont_enemy,t2
		addi s7,s7,1
		sw s7,COUNTER,t2
		j secondenemy3
		
		secondenemy3:
		bnez a6,thirdenemy3
		lw t5,cont_enemy2
		bnez t5,thirdenemy3
		sw t0,cont_enemy2,t2
		addi s7,s7,1
		sw s7,COUNTER,t2
		j thirdenemy3
		
		thirdenemy3:
		bnez a7,seis
		lw t5,cont_enemy3
		bnez t5,seis
		sw t0,cont_enemy3,t2
		addi s7,s7,1
		sw s7,COUNTER,t2
		j siete

	uno:
	li t1,1
	bne s7,t1,dos
	li a0,PTS_X
	li a1,PTS_Y
	lw a2,color_red
	jal draw_square
	j sale

	
	dos:
	li t1,2					
	bne s7,t1,tres
	li a0,PTS_X
	li a1,PTS_Y
	lw a2,color_red
	jal draw_square
	
	li a0,PTS_X
	addi a0,a0,2
	li a1,PTS_Y
	lw a2,color_orange
	jal draw_square
	j sale

	
	tres:
	li t1,3	
	bne s7,t1,cuatro
	li a0,PTS_X
	li a1,PTS_Y
	lw a2,color_red
	jal draw_square
	
	li a0,PTS_X
	addi a0,a0,2
	li a1,PTS_Y
	lw a2,color_orange
	jal draw_square
		
	li a0,PTS_X
	addi a0,a0,4
	li a1,PTS_Y
	lw a2,color_cyan
	jal draw_square
	j sale

					
	cuatro:
	li t1,4
	bne s7,t1,cinco
	li a0,PTS_X
	li a1,PTS_Y
	lw a2,color_red
	jal draw_square
	
	li a0,PTS_X
	addi a0,a0,2
	li a1,PTS_Y
	lw a2,color_orange
	jal draw_square
		
	li a0,PTS_X
	addi a0,a0,4
	li a1,PTS_Y
	lw a2,color_cyan 
	jal draw_square
		
	li a0,PTS_X
	addi a0,a0,6
	li a1,PTS_Y
	lw a2,color_red
	jal draw_square
	j sale

	
	cinco:
	li t1,5
	bne s7,t1,seis
	li a0,PTS_X
	li a1,PTS_Y
	lw a2,color_red
	jal draw_square
	
	li a0,PTS_X
	addi a0,a0,2
	li a1,PTS_Y
	lw a2,color_orange
	jal draw_square
		
	li a0,PTS_X
	addi a0,a0,4
	li a1,PTS_Y
	lw a2,color_cyan
	jal draw_square
		
	li a0,PTS_X
	addi a0,a0,6
	li a1,PTS_Y
	lw a2,color_red
	jal draw_square
		
	li a0,PTS_X
	addi a0,a0,8
	li a1,PTS_Y
	lw a2,color_orange
	jal draw_square
	j sale

	
	seis:
	li t1,6
	bne s7,t1,siete
	li a0,PTS_X
	li a1,PTS_Y
	lw a2,color_red
	jal draw_square
	
	li a0,PTS_X
	addi a0,a0,2
	li a1,PTS_Y
	lw a2,color_orange
	jal draw_square
		
	li a0,PTS_X
	addi a0,a0,4
	li a1,PTS_Y
	lw a2,color_cyan
	jal draw_square
		
	li a0,PTS_X
	addi a0,a0,6
	li a1,PTS_Y
	lw a2,color_red
	jal draw_square
		
	li a0,PTS_X
	addi a0,a0,8
	li a1,PTS_Y
	lw a2,color_orange
	jal draw_square
		
	li a0,PTS_X
	addi a0,a0,10
	li a1,PTS_Y
	lw a2,color_cyan
	jal draw_square
	j sale

	
	siete:
	li t1,7
	bne s7,t1,ocho
	li a0,PTS_X
	li a1,PTS_Y
	lw a2,color_red
	jal draw_square
	
	li a0,PTS_X
	addi a0,a0,2
	li a1,PTS_Y
	lw a2,color_orange
	jal draw_square
		
	li a0,PTS_X
	addi a0,a0,4
	li a1,PTS_Y
	lw a2,color_cyan
	jal draw_square
		
	li a0,PTS_X
	addi a0,a0,6
	li a1,PTS_Y
	lw a2,color_red
	jal draw_square
		
	li a0,PTS_X
	addi a0,a0,8
	li a1,PTS_Y
	lw a2,color_orange
	jal draw_square
		
	li a0,PTS_X
	addi a0,a0,10
	li a1,PTS_Y
	lw a2,color_cyan
	jal draw_square
	
	li a0,PTS_X
	addi a0,a0,12
	li a1,PTS_Y
	lw a2,color_red
	jal draw_square	
	j sale

	
	ocho:
	li t1,8
	bne s7,t1,nueve
	li a0,PTS_X
	li a1,PTS_Y
	lw a2,color_red
	jal draw_square
	
	li a0,PTS_X
	addi a0,a0,2
	li a1,PTS_Y
	lw a2,color_orange
	jal draw_square
		
	li a0,PTS_X
	addi a0,a0,4
	li a1,PTS_Y
	lw a2,color_cyan
	jal draw_square
		
	li a0,PTS_X
	addi a0,a0,6
	li a1,PTS_Y
	lw a2,color_red
	jal draw_square
		
	li a0,PTS_X
	addi a0,a0,8
	li a1,PTS_Y
	lw a2,color_orange
	jal draw_square
		
	li a0,PTS_X
	addi a0,a0,10
	li a1,PTS_Y
	lw a2,color_cyan
	jal draw_square
	
	li a0,PTS_X
	addi a0,a0,12
	li a1,PTS_Y
	lw a2,color_red
	jal draw_square	
		
	li a0,PTS_X
	addi a0,a0,14
	li a1,PTS_Y
	lw a2,color_orange
	jal draw_square
	j sale

	
	nueve:
	li t1,9
	bne s7,t1,sale
		li a0,PTS_X
	li a1,PTS_Y
	lw a2,color_red
	jal draw_square
	
	li a0,PTS_X
	addi a0,a0,2
	li a1,PTS_Y
	lw a2,color_orange
	jal draw_square
		
	li a0,PTS_X
	addi a0,a0,4
	li a1,PTS_Y
	lw a2,color_cyan
	jal draw_square
		
	li a0,PTS_X
	addi a0,a0,6
	li a1,PTS_Y
	lw a2,color_red
	jal draw_square
		
	li a0,PTS_X
	addi a0,a0,8
	li a1,PTS_Y
	lw a2,color_orange
	jal draw_square
		
	li a0,PTS_X
	addi a0,a0,10
	li a1,PTS_Y
	lw a2,color_cyan
	jal draw_square
	
	li a0,PTS_X
	addi a0,a0,12
	li a1,PTS_Y
	lw a2,color_red
	jal draw_square	
		
	li a0,PTS_X
	addi a0,a0,14
	li a1,PTS_Y
	lw a2,color_orange
	jal draw_square
	
	li a0,PTS_X
	addi a0,a0,16
	li a1,PTS_Y
	lw a2,color_cyan
	jal draw_square
	j sale
	sale:							
	
	lw ra, 0(sp)
	addi sp, sp, 4
		
	jr ra	
	
	
	
# Function: new_round
#	The function does not have parameters, but due to speed internally uses the following convention
#		s0 stores the p1 dir
#		s1 stores the p2 dir
#		s2 stores thel ball x velocity
#		s3 stores the ball y velocity
#		s4 stores the player 1 paddle position
#		s5 stores the player 2 paddle position
#		s6 stores the ball x position
# 		s7 stores tghe ball y position
# This function is part of the main loop, so it does not require to save the state of the s registers
# but if it were an internal function, it should save each state.
new_round:
	#Initialize of the required register state for  the new round
	sw zero, computer_speed, t1
	sw zero, computer_count, t1
	
	li s0, MOV_STAY
	li s1, MOV_STAY
	li s8, MOV_STAY
	li s9, MOV_STAY

	
	
	jal clear_board
	li t0,250
	sw t0,inmortal_time,t6

	sw zero,inmortal,t6
	
	lw t0,nivel
	li t1,1
	li t2,2
	li t3,3

	beq t0,t1,.nivel1
	beq t0,t2,.nivel2
	beq t0,t3,.nivel3
	
	.nivel1:
		jal draw_one
		jal draw_map_destructible
		jal draw_map_extended
		
		sw zero,cont_enemy,t6
		sw zero,cont_enemy2,t6
		sw zero,cont_enemy3,t6
		
		lw t0,color_green2res
		sw t0,color_green2,t6
		lw t0,color_green3res
		sw t0,color_green3,t6
		
		li t1,1
		sw t1, life1,t6
		sw t1, life2,t6
		sw t1, life3,t6
		
		li t0,PUERTA1_X
		li t1,PUERTA1_Y	
		sw t0,next_level_x,t3
		sw t1,next_level_y,t3
		
		li t0,31
		sw t0,LIFE_X,t1
		jal draw_life
		
		
		li t0,39
		sw t0,LIFE_X,t1
		jal draw_life
		
		li t0,47
		sw t0,LIFE_X,t1
		jal draw_life
		
		li t0,ENEMY_X
		li t1, ENEMY_Y	
		sw t0,enemy_x,t3
		sw t1, enemy_y,t3
		li t1, 1	
		sw t1,enemy_life,t3
		
		li t0,ENEMY2_X
		li t1, ENEMY2_Y	
		sw t0,enemy2_x,t3
		sw t1, enemy2_y,t3
		li t1, 1	
		sw t1,enemy2_life,t3
		
		li t0,ENEMY3_X
		li t1, ENEMY3_Y	
		sw t0,enemy3_x,t3
		sw t1, enemy3_y,t3
		li t1, 1	
		sw t1,enemy3_life,t3
		
		lw a0, player_x
		lw a1, player_y
		lw a2, color_red
		li a3, MOV_STAY
		jal	draw_paddle
		
		lw a0, enemy_x
		lw a1, enemy_y
		lw a2, color_green
		li a3, MOV_STAY
		jal	draw_enemy
		
		lw a0, enemy2_x
		lw a1, enemy2_y
		lw a2, color_green2
		li a3, MOV_STAY
		jal	draw_enemy2
		
		lw a0, enemy3_x
		lw a1, enemy3_y
		lw a2, color_green3
		li a3, MOV_STAY
		jal	draw_enemy3
		
		li a0, 1000
		li a7, 32		
		ecall		# 1 second delay
	
		j main_game_loop
		
		.nivel2:
		jal draw_two
		jal draw_map_destructible2
		jal draw_map_extended
		
		
		sw zero,cont_enemy,t6
		sw zero,cont_enemy2,t6
		sw zero,cont_enemy3,t6
		
		lw t0,color_amarillo
		sw t0,color_green2,t6
		lw t0,color_amarillo1
		sw t0,color_green3,t6
		
		li t0,PUERTA2_X
		li t1,PUERTA2_Y	
		sw t0,next_level_x,t3
		sw t1,next_level_y,t3		
		
		lw t0,life1
		li t2,1
    		beq t2,t0,.primera_vida
    		lw t0,life2
    		beq t2,t0,.segunda_vida
    		lw t0,life3
    		beq t2,t0,.tercera_vida
    		
    		.primera_vida:
    		li t0,47
		sw t0,LIFE_X,t1
		jal draw_life
		
		.segunda_vida:
		li t0,39
		sw t0,LIFE_X,t1
		jal draw_life
		
		.tercera_vida:
		li t0,31
		sw t0,LIFE_X,t1
		jal draw_life
		
		li t0,ENEMY_2X
		li t1,ENEMY_2Y	
		sw t0,enemy_x,t3
		sw t1, enemy_y,t3
		li t1, 2	
		sw t1,enemy_life,t3
		
		li t0,ENEMY2_2X
		li t1,ENEMY2_2Y	
		sw t0,enemy2_x,t3
		sw t1, enemy2_y,t3
		li t1, 2	
		sw t1,enemy2_life,t3
		
		li t0,ENEMY3_2X
		li t1,ENEMY3_2Y	
		sw t0,enemy3_x,t3
		sw t1, enemy3_y,t3
		li t1, 2	
		sw t1,enemy3_life,t3
		
		lw a0, player_x
		lw a1, player_y
		lw a2, color_red
		li a3, MOV_STAY
		jal	draw_paddle
		
		lw a0, enemy_x
		lw a1, enemy_y
		lw a2, color_green
		li a3, MOV_STAY
		jal	draw_enemy
		
		lw a0, enemy2_x
		lw a1, enemy2_y
		lw a2, color_green2
		li a3, MOV_STAY
		jal	draw_enemy2
		
		lw a0, enemy3_x
		lw a1, enemy3_y
		lw a2, color_green3
		li a3, MOV_STAY
		jal	draw_enemy3
		
		li a0, 1000
		li a7, 32		
		ecall		# 1 second delay
	
		j main_game_loop
		
		.nivel3:
		jal draw_three
		jal draw_map_destructible3
		jal draw_map_extended
		
		sw zero,cont_enemy,t6
		sw zero,cont_enemy2,t6
		sw zero,cont_enemy3,t6
		
		lw t0,color_orange
		sw t0,color_green2,t6
		lw t0,color_orange1
		sw t0,color_green3,t6
		
		li t0,PUERTA3_X
		li t1,PUERTA3_Y	
		sw t0,next_level_x,t3
		sw t1,next_level_y,t3
		
		lw t0,life1
		li t2,1
    		beq t2,t0,.primera_vida
    		lw t0,life2
    		beq t2,t0,.segunda_vida
    		lw t0,life3
    		beq t2,t0,.tercera_vida
		
		li t0,31
		sw t0,LIFE_X,t1
		jal draw_life
		
		
		li t0,39
		sw t0,LIFE_X,t1
		jal draw_life
		
		li t0,47
		sw t0,LIFE_X,t1
		jal draw_life
		
		
		li t0,ENEMY_3X
		li t1,ENEMY_3Y	
		sw t0,enemy_x,t3
		sw t1, enemy_y,t3
		li t1, 2	
		sw t1,enemy_life,t3
		
		li t0,ENEMY2_3X
		li t1,ENEMY2_3Y	
		sw t0,enemy2_x,t3
		sw t1, enemy2_y,t3
		li t1, 2	
		sw t1,enemy2_life,t3
		
		li t0,ENEMY3_3X
		li t1,ENEMY3_3Y	
		sw t0,enemy3_x,t3
		sw t1, enemy3_y,t3
		li t1, 2	
		sw t1,enemy3_life,t3
		
		lw a0, player_x
		lw a1, player_y
		lw a2, color_red
		li a3, MOV_STAY
		jal	draw_paddle
		
		lw a0, enemy_x
		lw a1, enemy_y
		lw a2, color_green
		li a3, MOV_STAY
		jal	draw_enemy
		
		lw a0, enemy2_x
		lw a1, enemy2_y
		lw a2, color_green2
		li a3, MOV_STAY
		jal	draw_enemy2
		
		lw a0, enemy3_x
		lw a1, enemy3_y
		lw a2, color_green3
		li a3, MOV_STAY
		jal	draw_enemy3
		
		li a0, 1000
		li a7, 32		
		ecall		# 1 second delay
	
		j main_game_loop

# Function: main_game_loop
# This function is the main game loop of the game when playing
#	The function does not have parameters, but due to speed internally uses the following conventions
#		s0 stores the p1 dir
#		s1 stores the p2 dir
#		s2 stores thel ball x velocity
#		s3 stores the ball y velocity
#		s4 stores the player 1 paddle position
#		s5 stores the player 2 paddle position
#		s6 stores the ball x position
# 		s7 stores the ball y position
# Return:
# 	void.
main_game_loop:
	.draw_objects:
		jal draw_contador
		lw t0, inmortal_time
		addi t0,t0,-1
		sw t0,inmortal_time,t1
		blez  t0,.hacer_mortal
		li t0,1
		sw t0,inmortal,t1
		j .seguir_programa
		
		.hacer_mortal:
			li t0,0
			sw t0,inmortal,t1
			j .seguir_programa
			
		.seguir_programa:
			lw a0, player_x
			lw a1, player_y
			mv a3, s0
			lw a2, color_red
			jal draw_paddle
			
			sw a0, player_x,t0
			sw a1, player_y,t0
			li s0, MOV_STAY
			
			jal draw_bomb
			jal draw_puerta
			
			lw a0, enemy_life
			beq a0,zero,.mov_enemy2
			jal random_dir
			lw a0, enemy_x
			lw a1, enemy_y
			mv a3, s9
			lw a2, color_green
			jal draw_enemy
			
			sw a0, enemy_x,t0
			sw a1, enemy_y,t0
			li s9, MOV_STAY
			.mov_enemy2:
				lw a0, enemy2_life
				beq a0,zero,.mov_enemy3
				jal random_dir
				lw a0, enemy2_x
				lw a1, enemy2_y
				mv a3, s9
				lw a2, color_green2
				jal draw_enemy2
				
				sw a0, enemy2_x,t0
				sw a1, enemy2_y,t0
				li s9, MOV_STAY
			.mov_enemy3:
				lw a0, enemy3_life
				beq a0,zero,.begin_standby
				jal random_dir
				lw a0, enemy3_x
				lw a1, enemy3_y
				mv a3, s9
				lw a2, color_green3
				jal draw_enemy3
				
				sw a0, enemy3_x,t0
				sw a1, enemy3_y,t0
				li s9, MOV_STAY
			
		

# Wait and read inputs
	.begin_standby:
		li t0, 2 # A counter is loaded for an aprox 50ms delay
	
	.standby:
		blez t0, .end_standby
		
		# syscall for pausing 10 ms
		li a0, 10
		li a7, 32
		ecall		
	
		addi t0, t0, -1
		
		# check for a key press
		lw t1, KEY_STATUS_ADDRESS
		blez t1, .standby
		
		jal adjust_dir
		sw zero, KEY_STATUS_ADDRESS, t1 # Clean the state that a key has been pressed
		#j .standby
		
	.end_standby:
		j .draw_objects
# Function: adjust_dir
# Parameters:
#	None.
# Return:
#	void.
adjust_dir:
	lw t0, KEY_INPUT_ADDRESS
	
	.adjust_dir_up:
		li t1, ASCII_W
		bne t0, t1, .adjust_dir_down
		li s0, MOV_UP
		j .adjust_dir_done
	
	.adjust_dir_down:
		li t1, ASCII_S
		bne t0, t1, .adjust_dir_right
		li s0, MOV_DOWN
		j .adjust_dir_done
	
	.adjust_dir_right:
		li t1, ASCII_D
		bne t0, t1, .adjust_dir_left
		li s0, MOV_RIGHT
		j .adjust_dir_done
		
	.adjust_dir_left:
		li t1, ASCII_A
		bne t0, t1, .adjust_dir_b
		li s0, MOV_LEFT
		j .adjust_dir_done
		
	.adjust_dir_b:
		li t1, ASCII_B
		bne t0, t1, .adjust_dir_none
		lw t0,bomb_state1
		li t1,1
		bne t1,t0,.conti
		j .adjust_dir_done
	.conti:
		li s10, BOMB
		jr ra
	.adjust_dir_none:
		# This section is kept as a case point if the player didn't press a valid option
	
	.adjust_dir_done:
		jr ra
	
	
random_dir:
	addi sp, sp, -12
	sw ra, 0(sp)
	sw a0, 4(sp)
	sw a1, 8(sp)
	
	li  a7, 42          # Código de la llamada al sistema para random
    	li  a0, 0
    	li  a1, 4           # Valor máximo (4)
    	ecall
	addi a0, a0, 1
	mv s9, a0

	lw ra, 0(sp)
	lw a0, 4(sp)
	lw a1, 8(sp)
	addi sp, sp, 12

	jr ra			
				
								
draw_one:
	addi sp,sp,-4
	sw ra,0(sp)
	
	li a0, NIVEL_X 
	addi a0,a0,1
	li a1,NIVEL_Y
	addi a1,a1,2
	lw a2, color_niveles
	jal draw_point 
	
	li a0, NIVEL_X 
	addi a0,a0,2
	li a1,NIVEL_Y
	addi a1,a1,1
	lw a2, color_niveles	
	jal draw_point
	
	li a0, NIVEL_X 
	addi a0,a0,3
	li a1,NIVEL_Y
	addi a3, a1,6
	lw a2, color_niveles
	jal draw_vertical_line	

	
	lw ra, 0(sp)
	addi sp, sp, 4
	
			
	jr ra																			
					

							
draw_two:
	addi sp,sp,-4
	sw ra,0(sp)
	
	li a0,NIVEL_X
	li a1,NIVEL_Y
	lw a2,color_niveles
	addi a1,a1,1
	jal draw_point
	
	li a0,NIVEL_X
	addi a0,a0,1
	li a1,NIVEL_Y
	lw a2,color_niveles	
	addi a3,a0,1
	jal draw_horizontal_line 
	
	li a0,NIVEL_X
	addi a0,a0,3
	li a1,NIVEL_Y
	addi a1,a1,1
	lw a2,color_niveles
	jal draw_point
	
	li a0,NIVEL_X
	addi a0,a0,3
	li a1,NIVEL_Y
	lw a2,color_niveles
	addi a1,a1,2
	jal draw_point			
	
	li a0,NIVEL_X
	addi a0,a0,1
	li a1,NIVEL_Y
	addi a1,a1,3
	lw a2,color_niveles	
	addi a3,a0,1
	jal draw_horizontal_line 
	
	li a0,NIVEL_X
	li a1,NIVEL_Y
	addi a1,a1,4
	lw a2,color_niveles
	jal draw_point	
		
	li a0,NIVEL_X
	addi a0,a0,1
	li a1,NIVEL_Y
	addi a1,a1,3
	lw a2,color_niveles	
	addi a3,a0,1
	jal draw_horizontal_line 

	li a0,NIVEL_X
	li a1,NIVEL_Y
	addi a1,a1,5
	lw a2,color_niveles	
	addi a3,a0,3
	jal draw_horizontal_line 												


	lw ra, 0(sp)
	addi sp, sp, 4
	
			
	jr ra	


draw_three:
	addi sp,sp,-4
	sw ra, 0(sp)
	
	li a0,NIVEL_X
	li a1, NIVEL_Y
	addi a1,a1,1
	lw a2,color_niveles
	jal draw_point 
	
	li a0,NIVEL_X
	addi a0,a0,1
	li a1,NIVEL_Y
	lw a2,color_niveles	
	addi a3,a0,1
	jal draw_horizontal_line 	
	
	li a0,NIVEL_X
	addi a0,a0,3
	li a1,NIVEL_Y
	addi a1,a1,1
	lw a2,color_niveles
	jal draw_point
	
	li a0,NIVEL_X
	addi a0,a0,2
	li a1,NIVEL_Y
	addi a1,a1,2
	lw a2,color_niveles
	jal draw_point

	li a0,NIVEL_X
	addi a0,a0,3
	li a1,NIVEL_Y
	addi a1,a1,3
	lw a2,color_niveles
	jal draw_point
									
	li a0,NIVEL_X
	addi a0,a0,3
	li a1,NIVEL_Y
	addi a1,a1,4
	lw a2,color_niveles
	jal draw_point
								
	li a0,NIVEL_X
	addi a0,a0,1
	li a1,NIVEL_Y
	addi a1,a1,5
	lw a2,color_niveles	
	addi a3,a0,1
	jal draw_horizontal_line 
	
	li a0,NIVEL_X
	li a1,NIVEL_Y
	addi a1,a1,4
	lw a2,color_niveles
	jal draw_point
										
	lw ra, 0(sp)
	addi sp, sp, 4
	
	jr ra

																																												
draw_puerta:
	# Reservar espacio en la pila
    	addi sp, sp, -12
    	sw ra, 0(sp)
    	sw a0, 4(sp)
	sw a1, 8(sp)
     
    	lw a0,next_level_x
	lw a1,next_level_y
	lw a2,color_puerta
	lw a3,color_cafe
    	
    	jal check_collisions
    	beq s11,a3,.esperar
    	jal draw_square
    
    	.esperar:
    		# Restaurar registros guardados y liberar espacio en la pila
		lw ra, 0(sp)
		lw a0, 4(sp)
		lw a1, 8(sp)
		addi sp, sp, 8
		    
	    	# Retorno
	    	jr ra
draw_bomb:
    # Reservar espacio en la pila
    addi sp, sp, -4
    sw ra, 0(sp)
     
    lw a2,color_magenta
    
    li t0,1
    
    
    bne t0, s10, .draw
    li t0,1
    sw t0,bomb_state1,t1
    sw a0,bomb1_x,t1
    sw a1,bomb1_y,t1
    jal .draw
    
    .draw:
    	
    	lw t0,bomb_state1
    	li t1,1
    	bne t0,t1,.fin
    	
    	lw t0,bomb_time1
    	addi t0,t0,-1
    	sw t0,bomb_time1,t1
    	bne zero,t0,.continuar
    	sw zero,bomb_state1,t1
    	lw a0,bomb1_x
	lw a1,bomb1_y
	lw a2,color_black
	lw t0,bomb_time1
	addi t0,t0,100
	sw t0,bomb_time1,t1
	jal draw_square
	jal draw_bomb_explosion
	jal reinicio_player
	jal eliminate_enemy
	jal eliminate_enemy2
	jal eliminate_enemy3
		
    	.continuar:
	    	lw a0,bomb1_x
	    	lw a1,bomb1_y
	    	jal draw_square
	
    .fin:
    	
    	li s10,0
    	# Restaurar registros guardados y liberar espacio en la pila
    	lw ra, 0(sp)
    	addi sp, sp, 4
    
    	# Retorno
    	jr ra

draw_bomb_explosion:
    # Reservar espacio en la pila
    addi sp, sp, -12
    sw ra, 0(sp)
    sw a0, 4(sp)
    sw a1, 8(sp)
    
    mv t2,a0
    mv t3,a1
    lw a2,color_black
    lw a3,color_gray
    lw a4,color_red
    lw a5,color_green
    lw a6,color_green2
    lw a7,color_green3
    jal .up_bomb
    
   	.up_bomb: 
   		mv a0,t2
		addi a1,t3,-1
		jal check_collisions
		beq s11,a4,.down_bomb
		
		mv a0,t2
		addi a1,t3,-2
		jal check_collisions
		beq s11,a4,.down_bomb
		
		addi a0,t2,1
		addi a1,t3,-2
		jal check_collisions
		beq s11,a4,.down_bomb
		
		mv a0,t2
		addi a1,t3,-1
		jal check_collisions
		beq s11,a5,.down_bomb
		
		mv a0,t2
		addi a1,t3,-2
		jal check_collisions
		beq s11,a5,.down_bomb
		
		addi a0,t2,1
		addi a1,t3,-2
		jal check_collisions
		beq s11,a5,.down_bomb
		
		mv a0,t2
		addi a1,t3,-1
		jal check_collisions
		beq s11,a6,.down_bomb
		
		mv a0,t2
		addi a1,t3,-2
		jal check_collisions
		beq s11,a6,.down_bomb
		
		addi a0,t2,1
		addi a1,t3,-2
		jal check_collisions
		beq s11,a6,.down_bomb
		
		mv a0,t2
		addi a1,t3,-1
		jal check_collisions
		beq s11,a7,.down_bomb
		
		mv a0,t2
		addi a1,t3,-2
		jal check_collisions
		beq s11,a7,.down_bomb
		
		addi a0,t2,1
		addi a1,t3,-2
		jal check_collisions
		beq s11,a7,.down_bomb
		
		mv a0,t2
		addi a1,t3,-2
		bne s11,a3, .borrar
		jal .down_bomb
			
	.down_bomb:
		mv a0,t2
		addi a1,t3,2
		jal check_collisions
		beq s11,a4,.left_bomb
		
		mv a0,t2
		addi a1,t3,3
		jal check_collisions
		beq s11,a4,.left_bomb
		
		addi a0,t2,1
		addi a1,t3,3
		jal check_collisions
		beq s11,a4,.left_bomb
		
		mv a0,t2
		addi a1,t3,2
		jal check_collisions
		beq s11,a5,.left_bomb
		
		mv a0,t2
		addi a1,t3,3
		jal check_collisions
		beq s11,a5,.left_bomb
		
		addi a0,t2,1
		addi a1,t3,3
		jal check_collisions
		beq s11,a5,.left_bomb
		
		mv a0,t2
		addi a1,t3,2
		jal check_collisions
		beq s11,a6,.left_bomb
		
		mv a0,t2
		addi a1,t3,3
		jal check_collisions
		beq s11,a6,.left_bomb
		
		addi a0,t2,1
		addi a1,t3,3
		jal check_collisions
		beq s11,a6,.left_bomb
		
		mv a0,t2
		addi a1,t3,2
		jal check_collisions
		beq s11,a7,.left_bomb
		
		mv a0,t2
		addi a1,t3,3
		jal check_collisions
		beq s11,a7,.left_bomb
		
		addi a0,t2,1
		addi a1,t3,3
		jal check_collisions
		beq s11,a7,.left_bomb
		
		mv a0,t2
		addi a1,t3,2
		bne s11,a3, .borrar
		jal .left_bomb
		
	.left_bomb:
		addi a0,t2,-1
		addi a1,t3,1
		jal check_collisions
		beq s11,a4,.right_bomb
	
		addi a0,t2,-1
		mv a1,t3
		jal check_collisions
		beq s11,a4,.right_bomb
			
		addi a0,t2,-2
		addi a1,t3,1
		jal check_collisions
		beq s11,a4,.right_bomb
		
		addi a0,t2,-1
		addi a1,t3,1
		jal check_collisions
		beq s11,a5,.right_bomb
	
		addi a0,t2,-1
		mv a1,t3
		jal check_collisions
		beq s11,a5,.right_bomb
			
		addi a0,t2,-2
		addi a1,t3,1
		jal check_collisions
		beq s11,a5,.right_bomb
		
		addi a0,t2,-1
		addi a1,t3,1
		jal check_collisions
		beq s11,a6,.right_bomb
	
		addi a0,t2,-1
		mv a1,t3
		jal check_collisions
		beq s11,a6,.right_bomb
			
		addi a0,t2,-2
		addi a1,t3,1
		jal check_collisions
		beq s11,a6,.right_bomb
		
		addi a0,t2,-1
		addi a1,t3,1
		jal check_collisions
		beq s11,a7,.right_bomb
	
		addi a0,t2,-1
		mv a1,t3
		jal check_collisions
		beq s11,a7,.right_bomb
			
		addi a0,t2,-2
		addi a1,t3,1
		jal check_collisions
		beq s11,a7,.right_bomb
		
		mv a1,t3
		bne s11,a3, .borrar
		jal .right_bomb
		
	.right_bomb:
		addi a0,t2,2
		addi a1,t3,1
		jal check_collisions
		beq s11,a4,.next

		addi a0,t2,2
		mv a1,t3
		jal check_collisions
		beq s11,a4,.next	
						
		addi a0,t2,3
		addi a1,t3,1
		jal check_collisions
		beq s11,a4,.next
		
		addi a0,t2,2
		addi a1,t3,1
		jal check_collisions
		beq s11,a5,.next

		addi a0,t2,2
		mv a1,t3
		jal check_collisions
		beq s11,a5,.next	
						
		addi a0,t2,3
		addi a1,t3,1
		jal check_collisions
		beq s11,a5,.next
		
		addi a0,t2,2
		addi a1,t3,1
		jal check_collisions
		beq s11,a6,.next

		addi a0,t2,2
		mv a1,t3
		jal check_collisions
		beq s11,a6,.next	
						
		addi a0,t2,3
		addi a1,t3,1
		jal check_collisions
		beq s11,a6,.next
		
		addi a0,t2,2
		addi a1,t3,1
		jal check_collisions
		beq s11,a7,.next

		addi a0,t2,2
		mv a1,t3
		jal check_collisions
		beq s11,a7,.next	
						
		addi a0,t2,3
		addi a1,t3,1
		jal check_collisions
		beq s11,a7,.next
		
		addi a0,a0,-1
		mv a1,t3
		bne s11,a3, .borrar
		jal .next
		
	.borrar:
		jal draw_square
		jal .next
    	
    	.next:
    		addi t5,t2,-2
    		beq a0,t5,.right_bomb
    		addi t5,t2,2
    		beq a0,t5,.final
    		addi t5,t3,-2
    		beq a1,t5,.down_bomb
    		addi t5,t3,2
    		beq a1,t5,.left_bomb
    		
    	.final:
	    	li s10,0
	    	# Restaurar registros guardados y liberar espacio en la pila
	    	lw ra, 0(sp)
	    	lw a0, 4(sp)
	    	lw a1, 8(sp)
	    	addi sp, sp, 12
	    
	    	# Retorno
	    	jr ra

reinicio_player:
	addi sp, sp, -12
    	sw ra, 0(sp)
    	sw a0, 4(sp)
    	sw a1, 8(sp)
    	
    	mv t2,a0
    	mv t3,a1
    	lw a3,color_red
    	lw a2,color_black
    	lw t0,inmortal
    	bne t0,zero,.final_player
    	jal .center_bomb_player
    	
    	.center_bomb_player: 
   		mv a0,t2
		mv a1,t3
		lw t4,player_x
		lw t5,player_y
		bne a0,t4,.up_bomb_player
		bne a1,t5,.up_bomb_player 
		jal .borrar_player
    
   	.up_bomb_player: 
   		mv a0,t2
		addi a1,t3,-1
		jal check_collisions
		beq s11,a3, .borrar_player
   		
		mv a0,t2
		addi a1,t3,-2
		jal check_collisions
		beq s11,a3, .borrar_player
		
		addi a0,t2,1
		addi a1,t3,-2
		jal check_collisions
		beq s11,a3, .borrar_player
		jal .down_bomb_player
			
	.down_bomb_player:
		mv a0,t2
		addi a1,t3,2
		jal check_collisions
		beq s11,a3, .borrar_player
		
		mv a0,t2
		addi a1,t3,3
		jal check_collisions
		beq s11,a3, .borrar_player
		
		addi a0,t2,1
		addi a1,t3,3
		jal check_collisions
		beq s11,a3, .borrar_player
		jal .left_bomb_player
		
	.left_bomb_player:
		addi a0,t2,-1
		mv a1,t3
		jal check_collisions
		beq s11,a3, .borrar_player
		
		addi a0,t2,-2
		mv a1,t3
		jal check_collisions
		beq s11,a3, .borrar_player
		
		addi a0,t2,-2
		addi a1,t3,1
		jal check_collisions
		beq s11,a3, .borrar_player
		jal .right_bomb_player
		
	.right_bomb_player:
		addi a0,t2,2
		mv a1,t3
		jal check_collisions
		beq s11,a3, .borrar_player
		
		addi a0,t2,3
		mv a1,t3
		jal check_collisions
		beq s11,a3, .borrar_player
		
		addi a0,t2,3
		addi a1,t3,1
		jal check_collisions
		beq s11,a3, .borrar_player
		jal .final_player
		
	.borrar_player:
		lw a0,player_x
		lw a1,player_y
		jal draw_square
		li t0,PLAYER_X
		li t1,PLAYER_Y
		sw t0,player_x,t6
		sw t1,player_y,t6
		lw a0,player_x
		lw a1,player_y
		lw a2,color_red
		jal draw_square
		lw a2,color_black
		li t0,250
		sw t0,inmortal_time,t1
		jal .borrar_life
	
	.borrar_life:
		sw zero,life1,t6
    		li a0,47
    		li a1,2
    		jal check_collisions
    		li a1,1
    		beq s11,a3,.borrar_corazon
    		sw zero,life2,t6
    		li a0,39
    		li a1,2
    		jal check_collisions
    		li a1,1
    		beq s11,a3,.borrar_corazon
    		li a0,31
    		li a1,2
    		jal check_collisions
    		li a1,1
    		beq s11,a3,.borrar_corazon
    		
    	.borrar_corazon:
    		jal borrar_corazon
		li a0,31
    		li a1,2
    		jal check_collisions
    		bne s11, a2, .final_player
    		j gameover_inicio
    	.final_player:
	    	# Restaurar registros guardados y liberar espacio en la pila
	    	lw ra, 0(sp)
	    	lw a0, 4(sp)
	    	lw a1, 8(sp)
	    	addi sp, sp, 12
	    
	    	# Retorno
	    	jr ra
    
eliminate_enemy:
	addi sp, sp, -12
    	sw ra, 0(sp)
    	sw a0, 4(sp)
    	sw a1, 8(sp)
    	
    	mv t2,a0
    	mv t3,a1
    	lw a3,color_green
    	lw a2,color_black
    	jal .up_bomb_enemy
    
   	.up_bomb_enemy: 
   		mv a0,t2
		addi a1,t3,-1
		jal check_collisions
		beq s11,a3, .borrar_enemy
   		
		mv a0,t2
		addi a1,t3,-2
		jal check_collisions
		beq s11,a3, .borrar_enemy
		
		addi a0,t2,1
		addi a1,t3,-2
		jal check_collisions
		beq s11,a3, .borrar_enemy
		jal .down_bomb_enemy
			
	.down_bomb_enemy:
		mv a0,t2
		addi a1,t3,2
		jal check_collisions
		beq s11,a3, .borrar_enemy
		
		mv a0,t2
		addi a1,t3,3
		jal check_collisions
		beq s11,a3, .borrar_enemy
		
		addi a0,t2,1
		addi a1,t3,3
		jal check_collisions
		beq s11,a3, .borrar_enemy
		jal .left_bomb_enemy
		
	.left_bomb_enemy:
		addi a0,t2,-1
		mv a1,t3
		jal check_collisions
		beq s11,a3, .borrar_enemy
		
		addi a0,t2,-2
		mv a1,t3
		jal check_collisions
		beq s11,a3, .borrar_enemy
		
		addi a0,t2,-2
		addi a1,t3,1
		jal check_collisions
		beq s11,a3, .borrar_enemy
		jal .right_bomb_enemy
		
	.right_bomb_enemy:
		addi a0,t2,2
		mv a1,t3
		jal check_collisions
		beq s11,a3, .borrar_enemy
		
		addi a0,t2,3
		mv a1,t3
		jal check_collisions
		beq s11,a3, .borrar_enemy
		
		addi a0,t2,3
		addi a1,t3,1
		jal check_collisions
		beq s11,a3, .borrar_enemy
		jal .final_enemy
		
	.borrar_enemy:
		lw a0,enemy_x
		lw a1,enemy_y
		jal draw_square
		li t0,ENEMY_X
		li t1,ENEMY_Y
		sw t0,enemy_x,t6
		sw t1,enemy_y,t6
		lw t0,enemy_life
		addi t0,t0,-1
		sw t0,enemy_life,t6
    	.final_enemy:
	    	# Restaurar registros guardados y liberar espacio en la pila
	    	lw ra, 0(sp)
	    	lw a0, 4(sp)
	    	lw a1, 8(sp)
	    	addi sp, sp, 12
	    
	    	# Retorno
	    	jr ra
	    	
eliminate_enemy2:
	addi sp, sp, -12
    	sw ra, 0(sp)
    	sw a0, 4(sp)
    	sw a1, 8(sp)
    	
    	mv t2,a0
    	mv t3,a1
    	lw a3,color_green2
    	lw a2,color_black
    	jal .up_bomb_enemy2
    
   	.up_bomb_enemy2: 
   		mv a0,t2
		addi a1,t3,-1
		jal check_collisions
		beq s11,a3, .borrar_enemy2
   		
		mv a0,t2
		addi a1,t3,-2
		jal check_collisions
		beq s11,a3, .borrar_enemy2
		
		addi a0,t2,1
		addi a1,t3,-2
		jal check_collisions
		beq s11,a3, .borrar_enemy2
		jal .down_bomb_enemy2
			
	.down_bomb_enemy2:
		mv a0,t2
		addi a1,t3,2
		jal check_collisions
		beq s11,a3, .borrar_enemy2
		
		mv a0,t2
		addi a1,t3,3
		jal check_collisions
		beq s11,a3, .borrar_enemy2
		
		addi a0,t2,1
		addi a1,t3,3
		jal check_collisions
		beq s11,a3, .borrar_enemy2
		jal .left_bomb_enemy2
		
	.left_bomb_enemy2:
		addi a0,t2,-1
		mv a1,t3
		jal check_collisions
		beq s11,a3, .borrar_enemy2
		
		addi a0,t2,-2
		mv a1,t3
		jal check_collisions
		beq s11,a3, .borrar_enemy2
		
		addi a0,t2,-2
		addi a1,t3,1
		jal check_collisions
		beq s11,a3, .borrar_enemy2
		jal .right_bomb_enemy2
		
	.right_bomb_enemy2:
		addi a0,t2,2
		mv a1,t3
		jal check_collisions
		beq s11,a3, .borrar_enemy2
		
		addi a0,t2,3
		mv a1,t3
		jal check_collisions
		beq s11,a3, .borrar_enemy2
		
		addi a0,t2,3
		addi a1,t3,1
		jal check_collisions
		beq s11,a3, .borrar_enemy2
		jal .final_enemy2
		
	.borrar_enemy2:
		lw a0,enemy2_x
		lw a1,enemy2_y
		jal draw_square
		li t0,ENEMY2_X
		li t1,ENEMY2_Y
		sw t0,enemy2_x,t6
		sw t1,enemy2_y,t6
		lw t0,enemy2_life
		addi t0,t0,-1
		sw t0,enemy2_life,t6
    	.final_enemy2:
	    	# Restaurar registros guardados y liberar espacio en la pila
	    	lw ra, 0(sp)
	    	lw a0, 4(sp)
	    	lw a1, 8(sp)
	    	addi sp, sp, 12
	    
	    	# Retorno
	    	jr ra

eliminate_enemy3:
	addi sp, sp, -12
    	sw ra, 0(sp)
    	sw a0, 4(sp)
    	sw a1, 8(sp)
    	
    	mv t2,a0
    	mv t3,a1
    	lw a3,color_green3
    	lw a2,color_black
    	jal .up_bomb_enemy3
    
   	.up_bomb_enemy3: 
   		mv a0,t2
		addi a1,t3,-1
		jal check_collisions
		beq s11,a3, .borrar_enemy3
   		
		mv a0,t2
		addi a1,t3,-2
		jal check_collisions
		beq s11,a3, .borrar_enemy3
		
		addi a0,t2,1
		addi a1,t3,-2
		jal check_collisions
		beq s11,a3, .borrar_enemy3
		jal .down_bomb_enemy3
			
	.down_bomb_enemy3:
		mv a0,t2
		addi a1,t3,2
		jal check_collisions
		beq s11,a3, .borrar_enemy3
		
		mv a0,t2
		addi a1,t3,3
		jal check_collisions
		beq s11,a3, .borrar_enemy3
		
		addi a0,t2,1
		addi a1,t3,3
		jal check_collisions
		beq s11,a3, .borrar_enemy3
		jal .left_bomb_enemy3
		
	.left_bomb_enemy3:
		addi a0,t2,-1
		mv a1,t3
		jal check_collisions
		beq s11,a3, .borrar_enemy3
		
		addi a0,t2,-2
		mv a1,t3
		jal check_collisions
		beq s11,a3, .borrar_enemy3
		
		addi a0,t2,-2
		addi a1,t3,1
		jal check_collisions
		beq s11,a3, .borrar_enemy3
		jal .right_bomb_enemy3
		
	.right_bomb_enemy3:
		addi a0,t2,2
		mv a1,t3
		jal check_collisions
		beq s11,a3, .borrar_enemy3
		
		addi a0,t2,3
		mv a1,t3
		jal check_collisions
		beq s11,a3, .borrar_enemy3
		
		addi a0,t2,3
		addi a1,t3,1
		jal check_collisions
		beq s11,a3, .borrar_enemy3
		jal .final_enemy3
		
	.borrar_enemy3:
		lw a0,enemy3_x
		lw a1,enemy3_y
		jal draw_square
		li t0,ENEMY3_X
		li t1,ENEMY3_Y
		sw t0,enemy3_x,t6
		sw t1,enemy3_y,t6
		lw t0,enemy3_life
		addi t0,t0,-1
		sw t0,enemy3_life,t6
    	.final_enemy3:
	    	# Restaurar registros guardados y liberar espacio en la pila
	    	lw ra, 0(sp)
	    	lw a0, 4(sp)
	    	lw a1, 8(sp)
	    	addi sp, sp, 12
	    
	    	# Retorno
	    	jr ra


#FunctionL check_collisions
# Parameters:
#	a0: ball x pos
#	a1: ball Y pos
# Return: 
#	void.
check_collisions:
    addi sp, sp, -4        # Configura el marco de la pila
    sw ra, 0(sp)            # Guarda la dirección de retorno en la pila
    
    mv t0, a0        # Calcula la posición anterior
    li t1, 6
    sll t1, a1, t1         # Multiplica la coordenada y por 64
    add t0, t0, t1          # Agrega el desplazamiento y
    li t1, 2
    sll t0, t0, t1         # Multiplica por 4 para obtener el desplazamiento en bytes
    add t0, t0, gp          # Agrega la dirección base
    lw s11, 0(t0) 
    

    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra	

borrar_corazon:
    # Reservar espacio en la pila
    addi sp, sp, -12
    sw ra, 0(sp)
    sw a0, 4(sp)
    sw a1, 8(sp)
    
     # Punto superior izquierdo
    jal draw_point

    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    #segunda columna
    lw a1, 8(sp)
    addi a0, a0,1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    #tercera columna
    lw a1, 8(sp)
    addi a0, a0,1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    #cuarta columna
    lw a1, 8(sp)
    addi a0, a0,1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    #quinta columna
    lw a1, 8(sp)
    addi a0, a0,1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    #sexta columna
    lw a1, 8(sp)
    addi a0, a0,1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    #setima columna
    lw a1, 8(sp)
    addi a0, a0,1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    #octava columna
    lw a1, 8(sp)
    addi a0, a0,1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
    
    addi a1, a1, 1
    jal draw_point
	    
    # Restaurar registros y retornar
    lw ra, 0(sp)
    lw a0, 4(sp)
    lw a1, 8(sp)
    addi sp, sp, 12
    jr ra		
    
 
 draw_enemy:
	addi sp, sp -20
	sw ra, 0(sp)
	sw s0, 4(sp)
	sw s1, 8(sp)
	sw s2, 12(sp)
	sw s9, 16(sp)
	
	mv s0,a0
	mv s1,a1
	mv s2,a2
	mv s9,a3
	
	
	lw t0,enemy_move
	addi t0,t0,-1
	sw t0,enemy_move,t1
	bne t0,zero,.move_enemy
	li t0,15
	sw t0,enemy_move,t1
	lw t4,color_red
	lw t5,color_puerta
	li t0, MOV_UP
	beq t0, s8, .up_enemy
	li t0, MOV_DOWN
	beq t0, s8, .down_enemy
	li t0, MOV_RIGHT
	beq t0,s8, .right_enemy
	li t0, MOV_LEFT
	beq t0,s8, .left_enemy
	
	lw t3,color_black
	li t0, MOV_DOWN
	beq t0, s9, .down_enemy
	li t0, MOV_RIGHT
	beq t0,s9, .right_enemy
	li t0, MOV_LEFT
	beq t0,s9, .left_enemy
	li t0, MOV_STAY
	beq t0, s9, .no_mov_enemy
		
		#The default case is the up movement
		
	.up_enemy:
		li s8, MOV_UP 
		#erase bottom point
		mv a0, s0
		addi a1, s1,1 
		lw a2, color_black
		jal draw_point
		
		
		addi a0,s0,1
		addi a1,s1,1
		lw a2, color_black
		jal draw_point
		
		mv a0,s0
		addi a1,s1,-1
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy
		addi a0,s0,1
		addi a1,s1,-1
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy
		addi s1, s1, -1
		j .move_enemy
			
	.down_enemy:
		li s8, MOV_DOWN
		#erase top point
		mv a0, s0
		mv a1, s1
		lw a2, color_black
		jal draw_point
		
		addi a0,s0,1
		mv a1, s1 
		lw a2, color_black
		jal draw_point
		
		
		mv a0,s0
		addi a1,s1,2
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy
		addi a0,s0,1
		addi a1,s1,2
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy
		addi s1, s1, 1
		j .move_enemy
		
	.left_enemy:
		li s8, MOV_LEFT
		#erase right point
		mv a0, s0
		addi a0,s0,1
		mv a1, s1 
		lw a2, color_black
		jal draw_point
		
		addi a0,s0,1
		addi a1,s1,1
		lw a2, color_black
		jal draw_point
		
		addi a0,s0,-1
		mv a1,s1
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy
		addi a0,s0,-1
		addi a1,s1,1
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy
		addi s0, s0, -1
		j .move_enemy
		
	.right_enemy:
		li s8, MOV_RIGHT
		#erase left point
		mv a0, s0
		mv a1, s1
		lw a2, color_black
		jal draw_point
		
		mv a0, s0 
		addi a1,s1,1
		lw a2, color_black
		jal draw_point
		
		
		addi a0,s0,2
		mv a1,s1
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy
		addi a0,s0,2
		addi a1,s1,1
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy
		addi s0, s0, 1
		j .move_enemy
		
	
	.seguir_camino_enemy:
		li t0, MOV_UP
		beq t0, s8, .adelante_enemy
		li t0, MOV_DOWN
		beq t0, s8, .atras_enemy
		li t0, MOV_RIGHT
		beq t0,s8, .derecha_enemy
		li t0, MOV_LEFT
		beq t0,s8, .izquierda_enemy
	
	.adelante_enemy:
		addi s1, s1, -1
		j .move_enemy	
	
	.atras_enemy:
		addi s1, s1, 1
		j .move_enemy	
	
	.derecha_enemy:
		addi s0, s0, 1
		j .move_enemy	
	
	.izquierda_enemy:
		addi s0, s0, -1
		j .move_enemy
	
	.no_mov_enemy:
		#set the return value to MOV_STAY
		li s9, MOV_STAY
		li s8, MOV_STAY
	
	.move_enemy:
		mv a0, s0
		mv a1, s1
		mv a2, s2
		jal draw_point
		
		mv a0, s0
		addi a1, s1,1
		mv a2, s2
		jal draw_point
		
		addi a0, s0,1
		mv a1, s1
		mv a2, s2
		jal draw_point
		
		addi a0, s0,1
		addi a1, s1,1
		mv a2, s2
		jal draw_point
			
		
	mv a0, s0
	mv a1, s1
	
	lw ra, 0(sp)
	lw s0, 4(sp)
	lw s1, 8(sp)
	lw s2, 12(sp)
	lw s9, 16(sp)
	addi sp, sp 20
	
	jr ra		
    						   						   						   						
draw_enemy2:
	addi sp, sp -20
	sw ra, 0(sp)
	sw s0, 4(sp)
	sw s1, 8(sp)
	sw s2, 12(sp)
	sw s9, 16(sp)
	
	mv s0,a0
	mv s1,a1
	mv s2,a2
	mv s9,a3
	
	
	lw t0,enemy2_move
	addi t0,t0,-1
	sw t0,enemy2_move,t1
	bne t0,zero,.move_enemy2
	li t0,15
	sw t0,enemy2_move,t1
	lw t4,color_red
	lw t5,color_puerta
	li t0, MOV_UP
	beq t0, s6, .up_enemy2
	li t0, MOV_DOWN
	beq t0, s6, .down_enemy2
	li t0, MOV_RIGHT
	beq t0,s6, .right_enemy2
	li t0, MOV_LEFT
	beq t0,s6, .left_enemy2
	
	lw t3,color_black
	li t0, MOV_DOWN
	beq t0, s9, .down_enemy2
	li t0, MOV_RIGHT
	beq t0,s9, .right_enemy2
	li t0, MOV_LEFT
	beq t0,s9, .left_enemy2
	li t0, MOV_STAY
	beq t0, s9, .no_mov_enemy2
		
		#The default case is the up movement
		
	.up_enemy2:
		li s6, MOV_UP 
		#erase bottom point
		mv a0, s0
		addi a1, s1,1 
		lw a2, color_black
		jal draw_point
		
		
		addi a0,s0,1
		addi a1,s1,1
		lw a2, color_black
		jal draw_point
		
		mv a0,s0
		addi a1,s1,-1
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy2
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy2
		addi a0,s0,1
		addi a1,s1,-1
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy2
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy2
		addi s1, s1, -1
		j .move_enemy
			
	.down_enemy2:
		li s6, MOV_DOWN
		#erase top point
		mv a0, s0
		mv a1, s1
		lw a2, color_black
		jal draw_point
		
		addi a0,s0,1
		mv a1, s1 
		lw a2, color_black
		jal draw_point
		
		
		mv a0,s0
		addi a1,s1,2
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy2
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy2
		addi a0,s0,1
		addi a1,s1,2
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy2
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy2
		addi s1, s1, 1
		j .move_enemy2
		
	.left_enemy2:
		li s6, MOV_LEFT
		#erase right point
		mv a0, s0
		addi a0,s0,1
		mv a1, s1 
		lw a2, color_black
		jal draw_point
		
		addi a0,s0,1
		addi a1,s1,1
		lw a2, color_black
		jal draw_point
		
		addi a0,s0,-1
		mv a1,s1
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy2
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy2
		addi a0,s0,-1
		addi a1,s1,1
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy2
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy2
		addi s0, s0, -1
		j .move_enemy2
		
	.right_enemy2:
		li s6, MOV_RIGHT
		#erase left point
		mv a0, s0
		mv a1, s1
		lw a2, color_black
		jal draw_point
		
		mv a0, s0 
		addi a1,s1,1
		lw a2, color_black
		jal draw_point
		
		
		addi a0,s0,2
		mv a1,s1
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy2
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy2
		addi a0,s0,2
		addi a1,s1,1
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy2
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy2
		addi s0, s0, 1
		j .move_enemy2
		
	
	.seguir_camino_enemy2:
		li t0, MOV_UP
		beq t0, s6, .adelante_enemy2
		li t0, MOV_DOWN
		beq t0, s6, .atras_enemy2
		li t0, MOV_RIGHT
		beq t0,s6, .derecha_enemy2
		li t0, MOV_LEFT
		beq t0,s6, .izquierda_enemy2
	
	.adelante_enemy2:
		addi s1, s1, -1
		j .move_enemy2	
	
	.atras_enemy2:
		addi s1, s1, 1
		j .move_enemy2	
	
	.derecha_enemy2:
		addi s0, s0, 1
		j .move_enemy2	
	
	.izquierda_enemy2:
		addi s0, s0, -1
		j .move_enemy2
	
	.no_mov_enemy2:
		#set the return value to MOV_STAY
		li s9, MOV_STAY
		li s6, MOV_STAY
	
	.move_enemy2:
		mv a0, s0
		mv a1, s1
		mv a2, s2
		jal draw_point
		
		mv a0, s0
		addi a1, s1,1
		mv a2, s2
		jal draw_point
		
		addi a0, s0,1
		mv a1, s1
		mv a2, s2
		jal draw_point
		
		addi a0, s0,1
		addi a1, s1,1
		mv a2, s2
		jal draw_point
			
		
	mv a0, s0
	mv a1, s1
	
	lw ra, 0(sp)
	lw s0, 4(sp)
	lw s1, 8(sp)
	lw s2, 12(sp)
	lw s9, 16(sp)
	addi sp, sp 20
	
	jr ra		
    			
draw_enemy3:
	addi sp, sp -20
	sw ra, 0(sp)
	sw s0, 4(sp)
	sw s1, 8(sp)
	sw s2, 12(sp)
	sw s9, 16(sp)
	
	mv s0,a0
	mv s1,a1
	mv s2,a2
	mv s9,a3
	
	
	lw t0,enemy3_move
	addi t0,t0,-1
	sw t0,enemy3_move,t1
	bne t0,zero,.move_enemy3
	li t0,15
	sw t0,enemy3_move,t1
	lw t4,color_red
	lw t5,color_puerta
	li t0, MOV_UP
	beq t0, s5, .up_enemy3
	li t0, MOV_DOWN
	beq t0, s5, .down_enemy3
	li t0, MOV_RIGHT
	beq t0,s5, .right_enemy3
	li t0, MOV_LEFT
	beq t0,s5, .left_enemy3
	
	lw t3,color_black
	li t0, MOV_DOWN
	beq t0, s9, .down_enemy3
	li t0, MOV_RIGHT
	beq t0,s9, .right_enemy3
	li t0, MOV_LEFT
	beq t0,s9, .left_enemy3
	li t0, MOV_STAY
	beq t0, s9, .no_mov_enemy3
		
		#The default case is the up movement
		
	.up_enemy3:
		li s5, MOV_UP 
		#erase bottom point
		mv a0, s0
		addi a1, s1,1 
		lw a2, color_black
		jal draw_point
		
		
		addi a0,s0,1
		addi a1,s1,1
		lw a2, color_black
		jal draw_point
		
		mv a0,s0
		addi a1,s1,-1
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy3
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy3
		addi a0,s0,1
		addi a1,s1,-1
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy3
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy3
		addi s1, s1, -1
		j .move_enemy3
			
	.down_enemy3:
		li s5, MOV_DOWN
		#erase top point
		mv a0, s0
		mv a1, s1
		lw a2, color_black
		jal draw_point
		
		addi a0,s0,1
		mv a1, s1 
		lw a2, color_black
		jal draw_point
		
		
		mv a0,s0
		addi a1,s1,2
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy3
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy3
		addi a0,s0,1
		addi a1,s1,2
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy3
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy3
		addi s1, s1, 1
		j .move_enemy3
		
	.left_enemy3:
		li s5, MOV_LEFT
		#erase right point
		mv a0, s0
		addi a0,s0,1
		mv a1, s1 
		lw a2, color_black
		jal draw_point
		
		addi a0,s0,1
		addi a1,s1,1
		lw a2, color_black
		jal draw_point
		
		addi a0,s0,-1
		mv a1,s1
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy3
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy3
		addi a0,s0,-1
		addi a1,s1,1
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy3
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy3
		addi s0, s0, -1
		j .move_enemy3
		
	.right_enemy3:
		li s5, MOV_RIGHT
		#erase left point
		mv a0, s0
		mv a1, s1
		lw a2, color_black
		jal draw_point
		
		mv a0, s0 
		addi a1,s1,1
		lw a2, color_black
		jal draw_point
		
		
		addi a0,s0,2
		mv a1,s1
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy3
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy3
		addi a0,s0,2
		addi a1,s1,1
		jal check_collisions
		beq s11,t5,.seguir_camino_enemy3
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov_enemy3
		addi s0, s0, 1
		j .move_enemy3
		
	
	.seguir_camino_enemy3:
		li t0, MOV_UP
		beq t0, s5, .adelante_enemy3
		li t0, MOV_DOWN
		beq t0, s5, .atras_enemy3
		li t0, MOV_RIGHT
		beq t0,s5, .derecha_enemy3
		li t0, MOV_LEFT
		beq t0,s5, .izquierda_enemy3
	
	.adelante_enemy3:
		addi s1, s1, -1
		j .move_enemy2	
	
	.atras_enemy3:
		addi s1, s1, 1
		j .move_enemy2	
	
	.derecha_enemy3:
		addi s0, s0, 1
		j .move_enemy2	
	
	.izquierda_enemy3:
		addi s0, s0, -1
		j .move_enemy2
	
	.no_mov_enemy3:
		#set the return value to MOV_STAY
		li s9, MOV_STAY
		li s5, MOV_STAY
	
	.move_enemy3:
		mv a0, s0
		mv a1, s1
		mv a2, s2
		jal draw_point
		
		mv a0, s0
		addi a1, s1,1
		mv a2, s2
		jal draw_point
		
		addi a0, s0,1
		mv a1, s1
		mv a2, s2
		jal draw_point
		
		addi a0, s0,1
		addi a1, s1,1
		mv a2, s2
		jal draw_point
			
		
	mv a0, s0
	mv a1, s1
	
	lw ra, 0(sp)
	lw s0, 4(sp)
	lw s1, 8(sp)
	lw s2, 12(sp)
	lw s9, 16(sp)
	addi sp, sp 20
	
	jr ra																																				
# Function: draw_paddle
# Parameters:
#	a0: paddle x position
#	a1: paddle top y position
#	a2: paddle color
#	a3: paddle direction
# Return:
#	a0: new top y position
#	a1: direction of the paddle
 draw_paddle:
	addi sp, sp -20
	sw ra, 0(sp)
	sw s0, 4(sp)
	sw s1, 8(sp)
	sw s2, 12(sp)
	sw s3, 16(sp)

	mv s0, a0
	mv s1, a1
	mv s2, a2
	mv s3, a3
	
	lw t3,color_black
	lw t4,color_green
	lw a6,color_green2
	lw a7,color_green3
	lw t5,color_puerta
	li t0, MOV_STAY
	beq t0, s3, .no_mov
	li t0, MOV_DOWN
	beq t0, s3, .down
	li t0, MOV_RIGHT
	beq t0,s3, .right
	li t0, MOV_LEFT
	beq t0,s3, .left
	
	#The default case is the up movement
	
	.up: 
		#erase bottom point
		mv a0, s0
		addi a1, s1,1 
		lw a2, color_black
		jal draw_point
		
		
		addi a0,s0,1
		addi a1,s1,1
		lw a2, color_black
		jal draw_point
		
		mv a0,s0
		addi a1,s1,-1
		jal check_collisions
		beq s11,t5,.comprobar_next
		beq s11,a6,eliminate_player
		beq s11,a7,eliminate_player
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov
		addi a0,s0,1
		addi a1,s1,-1
		jal check_collisions
		beq s11,t5,.comprobar_next
		beq s11,a6,eliminate_player
		beq s11,a7,eliminate_player
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov
		addi s1, s1, -1
		j .move
			
	.down:
		#erase top point
		mv a0, s0
		mv a1, s1
		lw a2, color_black
		jal draw_point
		
		addi a0,s0,1
		mv a1, s1 
		lw a2, color_black
		jal draw_point
		
		
		mv a0,s0
		addi a1,s1,2
		jal check_collisions
		beq s11,t5,.comprobar_next
		beq s11,a6,eliminate_player
		beq s11,a7,eliminate_player
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov
		addi a0,s0,1
		addi a1,s1,2
		jal check_collisions
		beq s11,t5,.comprobar_next
		beq s11,a6,eliminate_player
		beq s11,a7,eliminate_player
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov
		addi s1, s1, 1
		j .move
		
	.left:
		#erase right point
		mv a0, s0
		addi a0,s0,1
		mv a1, s1 
		lw a2, color_black
		jal draw_point
		
		addi a0,s0,1
		addi a1,s1,1
		lw a2, color_black
		jal draw_point
		
		addi a0,s0,-1
		mv a1,s1
		jal check_collisions
		beq s11,t5,.comprobar_next
		beq s11,a6,eliminate_player
		beq s11,a7,eliminate_player
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov
		addi a0,s0,-1
		addi a1,s1,1
		jal check_collisions
		beq s11,t5,.comprobar_next
		beq s11,a6,eliminate_player
		beq s11,a7,eliminate_player
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov
		addi s0, s0, -1
		j .move
		
	.right:
		#erase left point
		mv a0, s0
		mv a1, s1
		lw a2, color_black
		jal draw_point
		
		mv a0, s0 
		addi a1,s1,1
		lw a2, color_black
		jal draw_point
		
		
		addi a0,s0,2
		mv a1,s1
		jal check_collisions
		beq s11,t5,.comprobar_next
		beq s11,a6,eliminate_player
		beq s11,a7,eliminate_player
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov
		addi a0,s0,2
		addi a1,s1,1
		jal check_collisions
		beq s11,t5,.comprobar_next
		beq s11,a6,eliminate_player
		beq s11,a7,eliminate_player
		beq s11,t4,eliminate_player
		bne s11,t3, .no_mov
		addi s0, s0, 1
		j .move			
	
	.comprobar_next:
		lw t0,enemy_life
		bne t0,zero,.seguir_camino
		lw t0,enemy2_life
		bne t0,zero,.seguir_camino
		lw t0,enemy3_life
		bne t0,zero,.seguir_camino
		j .next_nivel
	
	.seguir_camino:
		li t0, MOV_UP
		beq t0, s3, .adelante
		li t0, MOV_DOWN
		beq t0, s3, .atras
		li t0, MOV_RIGHT
		beq t0,s3, .derecha
		li t0, MOV_LEFT
		beq t0,s3, .izquierda
	
	.adelante:
		addi s1, s1, -1
		j .move	
	
	.atras:
		addi s1, s1, 1
		j .move	
	
	.derecha:
		addi s0, s0, 1
		j .move	
	
	.izquierda:
		addi s0, s0, -1
		j .move
	
	.next_nivel:
		lw t0,nivel
		addi t0,t0,1
		sw t0,nivel,t6
		li t1,4
		beq t0,t1,.win
		lw a0,player_x
		lw a1,player_y
		jal draw_square
		li t0,PLAYER_X
		li t1,PLAYER_Y
		sw t0,player_x,t6
		sw t1,player_y,t6
		lw a0,player_x
		lw a1,player_y
		lw a2,color_red
		jal draw_square
		lw a2,color_black
		j new_round
	.win:
		lw a0,player_x
		lw a1,player_y
		jal draw_square
		li t0,PLAYER_X
		li t1,PLAYER_Y
		sw t0,player_x,t6
		sw t1,player_y,t6
		lw a0,player_x
		lw a1,player_y
		lw a2,color_red
		jal draw_square
		lw a2,color_black
		li t0,1
		sw t0,nivel,t6
		j win_inicio	
	.no_mov:
		#set the return value to MOV_STAY
		li s3, MOV_STAY
	
	.move:
		mv a0, s0
		mv a1, s1
		mv a2, s2
		jal draw_point
		
		mv a0, s0
		addi a1, s1,1
		mv a2, s2
		jal draw_point
		
		addi a0, s0,1
		mv a1, s1
		mv a2, s2
		jal draw_point
		
		addi a0, s0,1
		addi a1, s1,1
		mv a2, s2
		jal draw_point
		
		
	# The return values of the new y-top position
	mv a0, s0
	mv a1, s1


	lw ra, 0(sp)
	lw s0, 4(sp)
	lw s1, 8(sp)
	lw s2, 12(sp)
	lw s3, 16(sp)
	addi sp, sp 20
	
	jr ra

eliminate_player:
    	lw a2,color_black
    	lw a3,color_red
    	lw t0,inmortal
    	bne t0,zero,.final_player_player_enemy
	.borrar_player_enemy:
		lw a0,player_x
		lw a1,player_y
		jal draw_square
		li t0,PLAYER_X
		li t1,PLAYER_Y
		sw t0,player_x,t6
		sw t1,player_y,t6
		lw a0,player_x
		lw a1,player_y
		lw a2,color_red
		jal draw_square
		lw a2,color_black
		li t0,250
		sw t0,inmortal_time,t1
		li t0,1
		sw t0,inmortal,t6
		jal .borrar_life_player_enemy
	
	.borrar_life_player_enemy:
		sw zero,life1,t6
    		li a0,47
    		li a1,2
    		jal check_collisions
    		li a1,1
    		beq s11,a3,.borrar_corazon_player_enemy
    		sw zero,life2,t6
    		li a0,39
    		li a1,2
    		jal check_collisions
    		li a1,1
    		beq s11,a3,.borrar_corazon_player_enemy
    		li a0,31
    		li a1,2
    		jal check_collisions
    		li a1,1
    		beq s11,a3,.borrar_corazon_player_enemy
    		
    	.borrar_corazon_player_enemy:
    		jal borrar_corazon
		li a0,31
    		li a1,2
    		jal check_collisions
    		bne s11, a2, .final_player_player_enemy
    		j gameover_inicio
    	.final_player_player_enemy:
	    	
	    	j main_game_loop
				
# Function: draw_point
# Parameters:
#	a0: x coordinate
#	a1: y coordinate
#	a2: color of the point
# Return
#	void
draw_point:
	li t0, 6
	sll t0, a1, t0 #Due to the size of the screen, multiply y coodinate by 64 (length of the field)
	add t1, a0, t0
	li t0, 2
	sll t1, t1, t0 # Multiply the resulting coodinate by 4
	add t1, t1, gp
	sw a2, (t1)
	jr ra
	
draw_life:
	addi sp, sp,-4
	sw ra, 0(sp)

	lw a0, LIFE_X
	lw a1, LIFE_Y
	addi a1,a1,1
	lw a2, color_red
	li a3, 3
	jal draw_vertical_line
	
	lw a0, LIFE_X
	addi a0,a0,1
	lw a1, LIFE_Y
	lw a2, color_red
	li a3, 4
	jal draw_vertical_line
	

	lw a0, LIFE_X
	addi a0,a0,2
	lw a1, LIFE_Y
	lw a2, color_red
	li a3, 5
	jal draw_vertical_line
	
	lw a0, LIFE_X
	addi a0,a0,3
	lw a1, LIFE_Y
	addi a1,a1,1
	lw a2, color_red
	li a3, 6
	jal draw_vertical_line
	
	lw a0, LIFE_X
	addi a0,a0,4
	lw a1, LIFE_Y
	lw a2, color_red
	li a3, 5
	jal draw_vertical_line						
											
	lw a0, LIFE_X
	addi a0,a0,5
	lw a1, LIFE_Y
	lw a2, color_red
	li a3, 4
	jal draw_vertical_line
	
	lw a0, LIFE_X
	addi a0,a0,6
	lw a1, LIFE_Y
	addi a1,a1,1
	lw a2, color_red
	li a3, 3
	jal draw_vertical_line	
	
																																										
	lw ra, 0(sp)
	addi sp, sp, 4
	
			
	jr ra		

	
		
draw_game_over:
	addi sp, sp,-4
	sw ra, 0(sp)
	
	# The G
	li a0, GAME_OVER_X
	li a1, GAME_OVER_Y
	lw a2, color_red
	addi a3,a0,3
	jal draw_vertical_line
	
	li a0, GAME_OVER_X
	li a1, GAME_OVER_Y
	addi a1, a1, 4
	lw a2, color_red
	addi a3, a0, 3
	jal draw_horizontal_line
	
	li a0, GAME_OVER_X
	li a1, GAME_OVER_Y
	lw a2, color_red
	addi a3, a0, 3
	jal draw_horizontal_line
	
	li a0, GAME_OVER_X
	addi a0, a0,2
	li a1, GAME_OVER_Y
	addi a1, a1, 2
	lw a2, color_red
	addi a3, a0, 1
	jal draw_horizontal_line
	
	li a0, GAME_OVER_X
	addi a0, a0, 3
	li a1, GAME_OVER_Y
	addi a1, a1, 3
	lw a2, color_red
	jal draw_point	
	
	# The A
	li a0,GAME_OVER_X
	li a1,GAME_OVER_Y
	lw a2, color_red
	addi a0,a0,5
	addi a1,a1,1
	addi a3,a1,3
	jal draw_vertical_line
	
	li a0,GAME_OVER_X
	li a1,GAME_OVER_Y
	lw a2, color_red
	addi a0,a0,6
	addi a3,a0,1
	jal draw_horizontal_line
	
	li a0,GAME_OVER_X
	li a1,GAME_OVER_Y
	lw a2, color_red
	addi a0,a0,6
	addi a1,a1,2
	addi a3,a0,1
	jal draw_horizontal_line
	
	li a0,GAME_OVER_X
	li a1,GAME_OVER_Y
	lw a2, color_red
	addi a0,a0,8
	addi a1,a1,1
	addi a3,a1,3
	jal draw_vertical_line	
	
	# The M
	li a0,GAME_OVER_X
	addi a0, a0, 10
	li a1, GAME_OVER_Y
	lw a2, color_red
	li a3, GAME_OVER_Y
	addi a3, a3, 4
	jal draw_vertical_line
	
	li a0, GAME_OVER_X
	addi a0, a0, 11
	li a1, GAME_OVER_Y
	lw a2, color_red
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, GAME_OVER_X
	addi a0, a0, 12
	li a1, GAME_OVER_Y
	addi a1, a1, 2
	lw a2, color_red
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, GAME_OVER_X
	addi a0, a0, 13
	li a1, GAME_OVER_Y
	lw a2, color_red
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, GAME_OVER_X
	addi a0, a0, 14
	li a1, GAME_OVER_Y
	lw a2, color_red
	li a3, GAME_OVER_Y
	addi a3, a3, 4
	jal draw_vertical_line

	#The E
	li a0, GAME_OVER_X
	addi a0, a0, 16
	li a1, GAME_OVER_Y
	lw a2, color_red
	addi a3, a1, 4
	jal draw_vertical_line
	
	li a0, GAME_OVER_X
	addi a0, a0, 17
	li a1, GAME_OVER_Y
	lw a2, color_red
	jal draw_point
	
	li a0, GAME_OVER_X
	addi a0, a0, 17
	li a1, GAME_OVER_Y
	addi a1, a1, 2
	lw a2, color_red
	jal draw_point
	
	li a0, GAME_OVER_X
	addi a0, a0, 17
	li a1, GAME_OVER_Y
	addi a1, a1, 4
	lw a2, color_red
	jal draw_point	
	
	li a0, GAME_OVER_X
	addi a0, a0, 18
	li a1, GAME_OVER_Y
	lw a2, color_red
	jal draw_point
	
	li a0, GAME_OVER_X
	addi a0, a0, 18
	li a1, GAME_OVER_Y
	addi a1, a1, 2
	lw a2, color_red
	jal draw_point
	
	li a0, GAME_OVER_X
	addi a0, a0, 18
	li a1, GAME_OVER_Y
	addi a1, a1, 4
	lw a2, color_red
	jal draw_point
	
	
	# The O
	li a0, GAME_OVER_X
	addi a0, a0, 21
	li a1, GAME_OVER_Y
	lw a2, color_red
	li a3, GAME_OVER_Y
	addi a3, a3,4
	jal draw_vertical_line
	
	li a0,GAME_OVER_X
	addi a0, a0, 24
	li a1, GAME_OVER_Y
	lw a2, color_red
	li a3, GAME_OVER_Y
	addi a3, a3, 4
	jal draw_vertical_line
	
	li a0, GAME_OVER_X
	addi a0, a0, 22
	li a1, GAME_OVER_Y
	lw a2, color_red
	addi a3, a0, 1
	jal draw_horizontal_line

	li a0, GAME_OVER_X
	addi a0, a0, 22
	li a1, GAME_OVER_Y
	addi a1,  a1, 4
	lw a2, color_red
	addi a3, a0, 1
	jal draw_horizontal_line
	
	
	# The V	
	li a0, GAME_OVER_X
	addi a0, a0, 26
	li a1, GAME_OVER_Y
	lw a2, color_red
	li a3, GAME_OVER_Y
	addi a3, a3,3
	jal draw_vertical_line
	
	li a0, GAME_OVER_X
	addi a0, a0, 29
	li a1, GAME_OVER_Y
	lw a2, color_red
	li a3, GAME_OVER_Y
	addi a3, a3,3
	jal draw_vertical_line
	
	li a0, GAME_OVER_X
	addi a0, a0, 27
	li a1, GAME_OVER_Y
	addi a1,  a1, 4
	lw a2, color_red
	addi a3, a0, 1
	jal draw_horizontal_line
	
	#The E
	li a0, GAME_OVER_X
	addi a0, a0, 31
	li a1, GAME_OVER_Y
	lw a2, color_red
	addi a3, a1, 4
	jal draw_vertical_line
	
	li a0, GAME_OVER_X
	addi a0, a0, 32
	li a1, GAME_OVER_Y
	lw a2, color_red
	jal draw_point
	
	li a0, GAME_OVER_X
	addi a0, a0, 32
	li a1, GAME_OVER_Y
	addi a1, a1, 2
	lw a2, color_red
	jal draw_point
	
	li a0, GAME_OVER_X
	addi a0, a0, 32
	li a1, GAME_OVER_Y
	addi a1, a1, 4
	lw a2, color_red
	jal draw_point	
	
	li a0, GAME_OVER_X
	addi a0, a0, 33
	li a1, GAME_OVER_Y
	lw a2, color_red
	jal draw_point
	
	li a0, GAME_OVER_X
	addi a0, a0, 33
	li a1, GAME_OVER_Y
	addi a1, a1, 2
	lw a2, color_red
	jal draw_point
	
	li a0, GAME_OVER_X
	addi a0, a0, 33
	li a1, GAME_OVER_Y
	addi a1, a1, 4
	lw a2, color_red
	jal draw_point
	
	#The R
	li a0, GAME_OVER_X
	addi a0, a0, 35
	li a1, GAME_OVER_Y
	lw a2, color_red
	addi a3, a1, 4
	jal draw_vertical_line
	
	li a0, GAME_OVER_X
	addi a0, a0, 36
	li a1, GAME_OVER_Y
	lw a2, color_red
	addi a3, a0, 1
	jal draw_horizontal_line
	
	li a0, GAME_OVER_X
	addi a0, a0, 36
	li a1, GAME_OVER_Y
	addi a1,a1,2
	lw a2, color_red
	addi a3, a0, 1
	jal draw_horizontal_line	
	
	li a0, GAME_OVER_X
	addi a0, a0, 38
	li a1, GAME_OVER_Y
	addi a1,a1,1
	lw a2, color_red
	jal draw_point
	
	li a0, GAME_OVER_X
	addi a0, a0, 38
	li a1, GAME_OVER_Y
	addi a1,a1,3
	lw a2, color_red
	addi a3, a1, 1
	jal draw_vertical_line
	

	# The upper lines
	li a0, 0
	li a1, TITLE_SCREEN_FIRST_LINE_ROW_Y
	lw a2, color_red
	li a3, 63
	jal draw_horizontal_line
	
	li a0, 0
	li a1, TITLE_SCREEN_FIRST_LINE_ROW_Y
	addi a1, a1, 1
	lw a2, color_orange
	li a3, 63
	jal draw_horizontal_line
	
	li a0, 0
	li a1, TITLE_SCREEN_FIRST_LINE_ROW_Y
	addi a1, a1, 2
	lw a2, color_red
	li a3, 63
	jal draw_horizontal_line
		
	# The final lines
	li a0, 0
	li a1, TITLE_SCREEN_THIRD_LINE_ROW_Y
	lw a2, color_red
	li a3, 63
	jal draw_horizontal_line
	
	li a0, 0
	li a1, TITLE_SCREEN_THIRD_LINE_ROW_Y
	addi a1, a1, 1
	lw a2, color_orange
	li a3, 63
	jal draw_horizontal_line
	
	li a0, 0
	li a1, TITLE_SCREEN_THIRD_LINE_ROW_Y
	addi a1, a1, 2
	lw a2, color_red
	li a3, 63
	jal draw_horizontal_line
			

	lw ra, 0(sp)
	addi sp, sp, 4											
	jr ra	

draw_win:
	addi sp, sp,-4
	sw ra, 0(sp)

	# The W
	li a0, WINS_TEXT_X
	li a1, WINS_TEXT_Y
	lw a2, color_gold
	addi a3, a1, 2
	jal draw_vertical_line
	
	li a0, WINS_TEXT_X
	addi a0, a0, 1
	li a1, WINS_TEXT_Y
	addi a1, a1, 3
	lw a2, color_gold
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, WINS_TEXT_X
	addi a0, a0, 2
	li a1, WINS_TEXT_Y
	addi a1, a1, WINS_TEXT_H
	lw a2, color_gold
	jal draw_point
	
	li a0, WINS_TEXT_X
	addi a0, a0, 3
	li a1, WINS_TEXT_Y
	addi a1, a1, 3
	lw a2, color_gold
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, WINS_TEXT_X
	addi a0, a0, 4
	li a1, WINS_TEXT_Y
	addi a1, a1, WINS_TEXT_H
	lw a2, color_gold
	jal draw_point
	
	li a0, WINS_TEXT_X
	addi a0, a0, 5
	li a1, WINS_TEXT_Y
	addi a1, a1, 3
	lw a2, color_gold
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, WINS_TEXT_X
	addi a0, a0, 6
	li a1, WINS_TEXT_Y
	lw a2, color_gold
	addi a3, a1, 2
	jal draw_vertical_line
	
	# The I starts at offset 8
	li a0, WINS_TEXT_X
	addi a0, a0, I_OFFSET
	li a1, WINS_TEXT_Y
	lw a2, color_gold
	addi a3, a0, 4 
	jal draw_horizontal_line
	
	li a0, WINS_TEXT_X
	addi a0, a0, I_OFFSET
	addi a0, a0, 2
	li a1, WINS_TEXT_Y
	lw a2, color_gold
	addi a3, a1, WINS_TEXT_H
	jal draw_vertical_line
	
	li a0, WINS_TEXT_X
	addi a0, a0, I_OFFSET
	li a1, WINS_TEXT_Y
	addi a1, a1, WINS_TEXT_H
	lw a2, color_gold
	addi a3, a0, 4 
	jal draw_horizontal_line

	# The N starts at offset 14
	li a0, WINS_TEXT_X
	addi a0, a0, N_OFFSET
	li a1, WINS_TEXT_Y
	lw a2, color_gold
	addi a3, a1, WINS_TEXT_H
	jal draw_vertical_line
	
	li a0, WINS_TEXT_X
	addi a0, a0, N_OFFSET
	addi a0, a0, 1
	li a1, WINS_TEXT_Y
	lw a2, color_gold
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, WINS_TEXT_X
	addi a0, a0, N_OFFSET
	addi a0, a0, 2
	li a1, WINS_TEXT_Y
	addi a1, a1, 2
	lw a2, color_gold
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, WINS_TEXT_X
	addi a0, a0, N_OFFSET
	addi a0, a0, 3
	li a1, WINS_TEXT_Y
	addi a1, a1, 4
	lw a2, color_gold
	addi a3, a1, 1
	jal draw_vertical_line

	li a0, WINS_TEXT_X
	addi a0, a0, N_OFFSET
	addi a0, a0, 4
	li a1, WINS_TEXT_Y
	lw a2, color_gold
	addi a3, a1, WINS_TEXT_H
	jal draw_vertical_line

	# The upper lines
	li a0, 0
	li a1, TITLE_SCREEN_FIRST_LINE_ROW_Y
	lw a2, color_gold
	li a3, 63
	jal draw_horizontal_line
	
	li a0, 0
	li a1, TITLE_SCREEN_FIRST_LINE_ROW_Y
	addi a1, a1, 1
	lw a2, color_green
	li a3, 63
	jal draw_horizontal_line
	
	li a0, 0
	li a1, TITLE_SCREEN_FIRST_LINE_ROW_Y
	addi a1, a1, 2
	lw a2, color_gold
	li a3, 63
	jal draw_horizontal_line
		
	# The final lines
	li a0, 0
	li a1, TITLE_SCREEN_THIRD_LINE_ROW_Y
	lw a2, color_gold
	li a3, 63
	jal draw_horizontal_line
	
	li a0, 0
	li a1, TITLE_SCREEN_THIRD_LINE_ROW_Y
	addi a1, a1, 1
	lw a2, color_green
	li a3, 63
	jal draw_horizontal_line
	
	li a0, 0
	li a1, TITLE_SCREEN_THIRD_LINE_ROW_Y
	addi a1, a1, 2
	lw a2, color_gold
	li a3, 63
	jal draw_horizontal_line
			

		
	lw ra, 0(sp)
	addi sp, sp, 4
	
			
	jr ra				
					
# Función: draw_map_extended
# Parámetros:
#   a0: coordenada x del punto de inicio
#   a1: coordenada y del punto de inicio
#   a2: color de los puntos
# Retorno:
#   void
draw_map_extended:

    # Reservar espacio en la pila
    addi sp, sp, -16
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    
    li a0, BLOQUE1_X
    li a1, BLOQUE1_Y
    
    li s0, 0
    li s1, 6
    jal draw_horizontal_map
    jal draw_vertical_map
    
    .loop_mapa1:
    	lw a2, color_gray
	jal draw_square 
	addi a1, a1, 4
	
	jal draw_square 
	addi a1, a1, 4
	
	jal draw_square 
	addi a1, a1, 4
	
	jal draw_square 
	addi a1, a1, 4
	
	jal draw_square 
	
	addi s1, s1, -1
	addi a0, a0,  4
   	li a1, BLOQUE1_Y
	
	 bne s0, s1, .loop_mapa1
	
    
    # Restaurar registros guardados y liberar espacio en la pila
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    addi sp, sp, 16
    
    # Retorno
    jr ra


# Función auxiliar: draw_square
# Parámetros:
#   ninguno
# Retorno:
#   void
draw_square:
    # Dibujar los puntos del cuadrado
    addi sp, sp, -12
    sw ra, 0(sp)
    sw a0, 4(sp)
    sw a1, 8(sp)
    
    
    # Punto superior izquierdo
    jal draw_point
    
    # Punto superior derecho
    addi a0, a0, 1
    jal draw_point
    
    # Punto inferior izquierdo
    addi a0, a0, -1
    addi a1, a1, 1
    jal draw_point
    
    # Punto inferior derecho
    addi a0, a0, 1 
    jal draw_point
    
    
    
    lw ra, 0(sp)
    lw a0, 4(sp)
    lw a1, 8(sp)
    addi sp, sp, 12
    jr ra
    
draw_map_destructible:
	  # Reservar espacio en la pila
    addi sp, sp, -4
    sw ra, 0(sp)
    
    li a0,6
    li a1,2
    lw a2, color_cafe
    
    jal draw_square
    li a0,8
    jal draw_square
    li a0,14
    jal draw_square
    li a0,18
    jal draw_square
    li a0,24
    jal draw_square
    li a0,26
    jal draw_square
    
    li a0,6
    li a1,4
    jal draw_square
    li a0,18
    jal draw_square
    
    li a0,2
    li a1,6
    jal draw_square
    li a0,8
    jal draw_square
    li a0,12
    jal draw_square
    li a0,22
    jal draw_square
    
    li a0,6
    li a1,8
    jal draw_square
    li a0,18
    jal draw_square
    
    li a0,10
    li a1,10
    jal draw_square
    li a0,12
    jal draw_square
    li a0,14
    jal draw_square
    li a0,26
    jal draw_square
    
    li a0,2
    li a1,12
    jal draw_square
    li a0,10
    jal draw_square
    li a0,22
    jal draw_square
    
    li a0,2
    li a1,14
    jal draw_square
    li a0,4
    jal draw_square
    li a0,6
    jal draw_square
    li a0,22
    jal draw_square
    
    li a0,2
    li a1,16
    jal draw_square
    li a0,14
    jal draw_square
    li a0,18
    jal draw_square
    li a0,26
    jal draw_square
    
    li a0,12
    li a1,18
    jal draw_square
    li a0,22
    jal draw_square
    li a0,24
    jal draw_square
    li a0,26
    jal draw_square
    
    
    li a0,6
    li a1,20
    jal draw_square
    li a0,10
    jal draw_square
    li a0,18
    jal draw_square
    
    li a0,2
    li a1,22
    jal draw_square
    li a0,8
    jal draw_square
    li a0,12
    jal draw_square
    li a0,20
    jal draw_square
   
    # Restaurar registros guardados y liberar espacio en la pila
    lw ra, 0(sp)
    addi sp, sp, 4
    
    # Retorno
    jr ra

draw_map_destructible2:
	  # Reservar espacio en la pila
    addi sp, sp, -4
    sw ra, 0(sp)
    
    li a0,6
    li a1,2
    lw a2, color_cafe
    
    jal draw_square
    li a0,14
    jal draw_square
    li a0,26
    jal draw_square
    
    li a0,6
    li a1,4
    jal draw_square
    li a0,10
    jal draw_square
    li a0,18
    jal draw_square
    
    li a0,8
    li a1,6
    jal draw_square
    li a0,12
    jal draw_square
    li a0,14
    jal draw_square
    li a0,16
    jal draw_square
    li a0,22
    jal draw_square
    
    li a0,2
    li a1,8
    jal draw_square
    li a0,14
    jal draw_square
    li a0,22
    jal draw_square
    li a0,26
    jal draw_square
    
    li a0,4
    li a1,10
    jal draw_square
    li a0,6
    jal draw_square
    li a0,18
    jal draw_square
    
    li a0,6
    li a1,12
    jal draw_square
    li a0,10
    jal draw_square
    li a0,18
    jal draw_square
    li a0,26
    jal draw_square
    
     li a0,14
    li a1,14
    jal draw_square
    li a0,24
    jal draw_square
    
     li a0,2
    li a1,16
    jal draw_square
    li a0,10
    jal draw_square
    li a0,22
    jal draw_square
    
    li a0,6
    li a1,18
    jal draw_square
    li a0,18
    jal draw_square
    li a0,20
    jal draw_square
    li a0,22
    jal draw_square
    
    li a0,12
    li a1,22
    jal draw_square
    
    
    # Restaurar registros guardados y liberar espacio en la pila
    lw ra, 0(sp)
    addi sp, sp, 4
    
    # Retorno
    jr ra
    
draw_map_destructible3:
	  # Reservar espacio en la pila
    addi sp, sp, -4
    sw ra, 0(sp)
    
    li a0,10
    li a1,2
    lw a2, color_cafe
    
    jal draw_square
    li a0,14
    jal draw_square

    
    li a0,6
    li a1,4
    jal draw_square
    li a0,14
    jal draw_square
    li a0,18
    jal draw_square
    li a0,20
    jal draw_square
    
    li a0,2
    li a1,6
    jal draw_square
    li a0,4
    jal draw_square
    li a0,6
    jal draw_square
    li a0,16
    jal draw_square
    li a0,22
    jal draw_square
    li a0,24
    jal draw_square
    
    li a0,2
    li a1,8
    jal draw_square
    li a0,14
    jal draw_square
    li a0,26
    jal draw_square
    
    li a0,4
    li a1,10
    jal draw_square
    li a0,8
    jal draw_square
    li a0,16
    jal draw_square
    li a0,18
    jal draw_square
    
    li a0,6
    li a1,14
    jal draw_square
    li a0,18
    jal draw_square
    li a0,22
    jal draw_square
    li a0,26
    jal draw_square
    
     li a0,14
    li a1,2
    jal draw_square
    li a0,10
    jal draw_square
    
     li a0,2
    li a1,16
    jal draw_square
    li a0,10
    jal draw_square
    li a0,22
    jal draw_square
    
    li a0,4
    li a1,18
    jal draw_square
    li a0,8
    jal draw_square
    li a0,10
    jal draw_square
    li a0,12
    jal draw_square
    li a0,20
    jal draw_square
    li a0,26
    jal draw_square
    
    li a0,6
    li a1,20
    jal draw_square
    li a0,14
    jal draw_square
    li a0,18
    jal draw_square
    li a0,26
    jal draw_square
    
    li a0,2
    li a1,22
    jal draw_square
    li a0,4
    jal draw_square
    li a0,8
    jal draw_square
    li a0,12
    jal draw_square
    li a0,20
    jal draw_square
    
    # Restaurar registros guardados y liberar espacio en la pila
    lw ra, 0(sp)
    addi sp, sp, 4
    
    # Retorno
    jr ra
    
draw_horizontal_map:
    # Dibujar los puntos del cuadrado
    addi sp, sp, -12
    sw ra, 0(sp)
    sw a0, 4(sp)
    sw a1, 8(sp)
    
    mv a0,zero
    mv a1,zero
    lw a2,color_gray
    addi a3,zero,27
    jal draw_horizontal_line
    addi a1,a1,1
    jal draw_horizontal_line
    addi a1,a1,23
    jal draw_horizontal_line
    addi a1,a1,1
    jal draw_horizontal_line
    
   
    lw ra, 0(sp)
    lw a0, 4(sp)
    lw a1, 8(sp)
    addi sp, sp, 12
    jr ra
    
draw_vertical_map:
    # Dibujar los puntos del cuadrado
    addi sp, sp, -12
    sw ra, 0(sp)
    sw a0, 4(sp)
    sw a1, 8(sp)
    
    mv a0,zero
    mv a1,zero
    lw a2,color_gray
    addi a3,zero,25
    jal draw_vertical_line
    addi a0,a0,1
    jal draw_vertical_line
    addi a0,a0,27
    jal draw_vertical_line
    addi a0,a0,1
    jal draw_vertical_line
    
   
    lw ra, 0(sp)
    lw a0, 4(sp)
    lw a1, 8(sp)
    addi sp, sp, 12
    jr ra


# Function: draw_horizontal_line
# Parameters:
#	a0: starting x coordinate
#	a1: y coordinate
#	a2: color of the line
#	a3: ending x coordinate
# Return
#	void
draw_horizontal_line:
	
	addi sp, sp, -16
	sw ra, 0(sp)
	sw s0, 4(sp)
	sw s1, 8(sp)
	sw s2, 12(sp)
	
	sub s0, a3, a0
	mv s1, a0
	li s2, 0
	
	.horizontal_loop:
		add a0, s1, s0
		jal draw_point
		addi s0, s0, -1
		
		bge s0, s2, .horizontal_loop
	
	lw ra, 0(sp)
	lw s0, 4(sp)
	lw s1, 8(sp)
	lw s2, 12(sp)
	addi sp, sp, 16	
	
	jr ra


# Function: draw_vertical_line
# Parameters:
#	a0: x coordinate
#	a1: starting y coordinate
#	a2: color of the line
#	a3: ending y coordinate
# Return
#	void
draw_vertical_line:
	
	addi sp, sp, -16
	sw ra, 0(sp)
	sw s0, 4(sp)
	sw s1, 8(sp)
	sw s2, 12(sp)
	
	sub s0, a3, a1
	mv s1, a1
	li s2, 0
	
	.vertical_loop:
		add a1, s1, s0
		jal draw_point
		addi s0, s0, -1
		
		bge s0, s2, .vertical_loop
	
	lw ra, 0(sp)
	lw s0, 4(sp)
	lw s1, 8(sp)
	lw s2, 12(sp)
	
	addi sp, sp, 16	
	
	jr ra

# Function: clear_board
# Parameters:
#	none
# Return
#	void
clear_board:
	lw t0, color_black
	li t1, TOTAL_PIXELS
	li t2, FOUR_BYTES
	
	.start_clear_loop:
		sub t1, t1, t2
		add t3, t1, gp
		sw t0, (t3)
		beqz t1, .end_clear_loop
		j .start_clear_loop
		
	.end_clear_loop:
	
	jr ra
	
# Function: draw_title_screen
# Parameters:
#	none
# Return
#	void
draw_title_screen:

	addi sp, sp, -4
	sw ra, 0(sp)

	# The upper lines
	li a0, 0
	li a1, TITLE_SCREEN_FIRST_LINE_ROW_Y
	lw a2, color_red
	li a3, 63
	jal draw_horizontal_line
	
	li a0, 0
	li a1, TITLE_SCREEN_FIRST_LINE_ROW_Y
	addi a1, a1, 1
	lw a2, color_cyan
	li a3, 63
	jal draw_horizontal_line
	
	li a0, 0
	li a1, TITLE_SCREEN_FIRST_LINE_ROW_Y
	addi a1, a1, 2
	lw a2, color_orange
	li a3, 63
	jal draw_horizontal_line
	
	# The medium lines
	li a0, 0
	li a1, TITLE_SCREEN_SECOND_LINE_ROW_Y
	lw a2, color_red
	li a3, 63
	jal draw_horizontal_line
	
	li a0, 0
	li a1, TITLE_SCREEN_SECOND_LINE_ROW_Y
	addi a1, a1, 1
	lw a2, color_cyan
	li a3, 63
	jal draw_horizontal_line
	
	li a0, 0
	li a1, TITLE_SCREEN_SECOND_LINE_ROW_Y
	addi a1, a1, 2
	lw a2, color_orange
	li a3, 63
	jal draw_horizontal_line
	
	# The final lines
	li a0, 0
	li a1, TITLE_SCREEN_THIRD_LINE_ROW_Y
	lw a2, color_red
	li a3, 63
	jal draw_horizontal_line
	
	li a0, 0
	li a1, TITLE_SCREEN_THIRD_LINE_ROW_Y
	addi a1, a1, 1
	lw a2, color_cyan
	li a3, 63
	jal draw_horizontal_line
	
	li a0, 0
	li a1, TITLE_SCREEN_THIRD_LINE_ROW_Y
	addi a1, a1, 2
	lw a2, color_orange
	li a3, 63
	jal draw_horizontal_line
	
	
	# BOMB text
	# The B
	li a0, PONG_TEXT_X
	li a1, PONG_TEXT_Y
	lw a2, color_white
	li a3, PONG_TEXT_Y
	addi a3, a3, 6
	jal draw_vertical_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 4
	li a1, PONG_TEXT_Y
	addi a1,a1,1
	lw a2, color_white
	li a3, PONG_TEXT_H
	addi a3, a3, PONG_TEXT_H
	jal draw_vertical_line
	

	li a0, PONG_TEXT_X
	addi a0, a0, 1
	li a1, PONG_TEXT_Y
	lw a2, color_white
	addi a3, a0, 2
	jal draw_horizontal_line

	li a0, PONG_TEXT_X
	addi a0, a0, 1
	li a1, PONG_TEXT_Y
	addi a1, a1, 3
	lw a2, color_white
	addi a3, a0, 2
	jal draw_horizontal_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 1
	li a1, PONG_TEXT_Y
	addi a1, a1, 6
	lw a2, color_white
	addi a3, a0, 2
	jal draw_horizontal_line
	
	# The O
	li a0, PONG_TEXT_X
	addi a0, a0, 6
	li a1, PONG_TEXT_Y
	lw a2, color_white
	li a3, PONG_TEXT_Y
	addi a3, a3,6
	jal draw_vertical_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 10
	li a1, PONG_TEXT_Y
	lw a2, color_white
	li a3, PONG_TEXT_Y
	addi a3, a3, 6
	jal draw_vertical_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 6
	li a1, PONG_TEXT_Y
	lw a2, color_white
	addi a3, a0, 3
	jal draw_horizontal_line

	li a0, PONG_TEXT_X
	addi a0, a0, 6
	li a1, PONG_TEXT_Y
	addi a1,  a1, 6
	lw a2, color_white
	addi a3, a0, 3
	jal draw_horizontal_line
			
	# The M
	li a0, PONG_TEXT_X
	addi a0, a0, 12
	li a1, PONG_TEXT_Y
	lw a2, color_white
	li a3, PONG_TEXT_Y
	addi a3, a3, 6
	jal draw_vertical_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 13
	li a1, PONG_TEXT_Y
	lw a2, color_white
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 14
	li a1, PONG_TEXT_Y
	addi a1, a1, 2
	lw a2, color_white
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 15
	li a1, PONG_TEXT_Y
	lw a2, color_white
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 16
	li a1, PONG_TEXT_Y
	lw a2, color_white
	li a3, PONG_TEXT_Y
	addi a3, a3, 6
	jal draw_vertical_line
	
	
	#The B
	li a0, PONG_TEXT_X
	addi a0, a0, 18
	li a1, PONG_TEXT_Y
	lw a2, color_white
	li a3, PONG_TEXT_Y
	addi a3, a3, 6
	jal draw_vertical_line
	
	
	li a0, PONG_TEXT_X
	addi a0, a0, 19
	li a1, PONG_TEXT_Y
	addi a1, a1, 6
	lw a2, color_white
	addi a3, a0, 2
	jal draw_horizontal_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 19
	li a1, PONG_TEXT_Y
	lw a2, color_white
	addi a3, a0, 2
	jal draw_horizontal_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 19
	li a1, PONG_TEXT_Y
	addi a1, a1, 3
	lw a2, color_white
	addi a3, a0, 2
	jal draw_horizontal_line
	
	
	li a0, PONG_TEXT_X
	addi a0, a0, 22
	li a1, PONG_TEXT_Y
	addi a1,a1,1
	lw a2, color_white
	li a3, PONG_TEXT_H
	addi a3, a3, 5
	jal draw_vertical_line
	


	
	# Press 1 or 2 text
	# The P
	li a0, PRESS_TEXT_X
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 3
	li a1, PRESS_TEXT_Y
	addi a1, a1, 1
	lw a2, color_white
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 1
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a0, 2
	jal draw_horizontal_line
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 1
	li a1, PRESS_TEXT_Y
	addi a1, a1, 2
	lw a2, color_white
	addi a3, a0, 2
	jal draw_horizontal_line
	
	# The R
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 5
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 7
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 7
	li a1, PRESS_TEXT_Y
	addi a1, a1, 2
	lw a2, color_black
	jal draw_point
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 6
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	jal draw_point

	li a0, PRESS_TEXT_X
	addi a0, a0, 6
	li a1, PRESS_TEXT_Y
	addi a1, a1, 2
	lw a2, color_white
	jal draw_point
			
	#The E
	li a0, PRESS_TEXT_X
	addi a0, a0, 9
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 10
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	jal draw_point
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 10
	li a1, PRESS_TEXT_Y
	addi a1, a1, 2
	lw a2, color_white
	jal draw_point
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 10
	li a1, PRESS_TEXT_Y
	addi a1, a1, 4
	lw a2, color_white
	jal draw_point
	
	# The first S
	li a0, PRESS_TEXT_X
	addi a0, a0, 12
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 12
	li a1, PRESS_TEXT_Y
	addi a1, a1, 3
	lw a2, color_black
	jal draw_point
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 13
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	jal draw_point
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 13
	li a1, PRESS_TEXT_Y
	addi a1,  a1, 2
	lw a2, color_white
	jal draw_point

	li a0, PRESS_TEXT_X
	addi a0, a0, 13
	li a1, PRESS_TEXT_Y
	addi a1,  a1, 4
	lw a2, color_white
	jal draw_point
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 14
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line

	li a0, PRESS_TEXT_X
	addi a0, a0, 14
	li a1, PRESS_TEXT_Y
	addi a1,  a1, 1
	lw a2, color_black
	jal draw_point

	# The other S
		
	li a0, PRESS_TEXT_X
	addi a0, a0, 16
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 16
	li a1, PRESS_TEXT_Y
	addi a1, a1, 3
	lw a2, color_black
	jal draw_point
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 17
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	jal draw_point
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 17
	li a1, PRESS_TEXT_Y
	addi a1,  a1, 2
	lw a2, color_white
	jal draw_point

	li a0, PRESS_TEXT_X
	addi a0, a0, 17
	li a1, PRESS_TEXT_Y
	addi a1,  a1, 4
	lw a2, color_white
	jal draw_point
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 18
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line

	li a0, PRESS_TEXT_X
	addi a0, a0, 18
	li a1, PRESS_TEXT_Y
	addi a1,  a1, 1
	lw a2, color_black
	jal draw_point
	
	# The 1 

	li a0, PRESS_TEXT_X
	addi a0, a0, 23
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line
			
	li a0, PRESS_TEXT_X
	addi a0, a0, 22
	li a1, PRESS_TEXT_Y
	addi a1,  a1, 1
	lw a2, color_white
	jal draw_point
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 22
	li a1, PRESS_TEXT_Y
	addi a1, a1, PRESS_TEXT_H
	lw a2, color_white
	addi a3, a0, 2
	jal draw_horizontal_line
					
	# The name																																																																
																																																																																																																													
	#The J
	li a0, NAME_TEXT_X
	li a1, NAME_TEXT_Y
	addi a1,a1,3
	lw a2, color_white
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 1
	li a1, NAME_TEXT_Y
	addi a1, a1, 4
	lw a2, color_white
	jal draw_point	
																																																																																																																																																																																							
	li a0, NAME_TEXT_X
	addi a0, a0, 2
	li a1, NAME_TEXT_Y
	lw a2, color_white
	add a3,a3, zero
	jal draw_vertical_line
					
	# The G
	li a0, NAME_TEXT_X
	addi a0, a0, 4
	li a1, NAME_TEXT_Y
	lw a2, color_white
	li a3, NAME_TEXT_Y
	addi a3, a3, 3
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 4
	li a1, NAME_TEXT_Y
	addi a1, a1, 4
	lw a2, color_white
	addi a3, a0, 3
	jal draw_horizontal_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 4
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a0, 3
	jal draw_horizontal_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 6
	li a1, NAME_TEXT_Y
	addi a1, a1, 2
	lw a2, color_white
	addi a3, a0, 1
	jal draw_horizontal_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 7
	li a1, NAME_TEXT_Y
	addi a1, a1, 3
	lw a2, color_white
	jal draw_point

	# The .
	li a0, NAME_TEXT_X
	addi a0, a0, 9
	li a1, NAME_TEXT_Y
	addi a1, a1, 4
	lw a2, color_white
	jal draw_point
	
	#The second J
	li a0, NAME_TEXT_X
	addi a0,a0,11
	li a1, NAME_TEXT_Y
	addi a1,a1,3
	lw a2, color_white
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 12
	li a1, NAME_TEXT_Y
	addi a1, a1, 4
	lw a2, color_white
	jal draw_point	
																																																																																																																																																																																							
	li a0, NAME_TEXT_X
	addi a0, a0, 13
	li a1, NAME_TEXT_Y
	lw a2, color_white
	add a3,a3, zero
	jal draw_vertical_line
	
	#The B
	
	li a0, NAME_TEXT_X
	addi a0, a0, 15
	li a1, NAME_TEXT_Y
	lw a2, color_white
	add a3,a3, zero
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 16
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a0,1 
	jal draw_horizontal_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 16
	li a1, NAME_TEXT_Y
	addi a1,a1,2
	lw a2, color_white
	addi a3, a0,1 
	jal draw_horizontal_line	
	
	li a0, NAME_TEXT_X
	addi a0, a0, 16
	li a1, NAME_TEXT_Y
	addi a1,a1,4
	lw a2, color_white
	addi a3, a0,1 
	jal draw_horizontal_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 18
	li a1, NAME_TEXT_Y
	addi a1, a1, 1
	lw a2, color_white
	jal draw_point			
							
	li a0, NAME_TEXT_X
	addi a0, a0, 18
	li a1, NAME_TEXT_Y
	addi a1, a1, 3
	lw a2, color_white
	jal draw_point	
	
	# The second .
	li a0, NAME_TEXT_X
	addi a0, a0, 20
	li a1, NAME_TEXT_Y
	addi a1, a1, 4
	lw a2, color_white
	jal draw_point
		
					
	lw ra, 0(sp)
	addi sp, sp, 4
	
	jr ra 

# Function: clear_key_press
# Parameters:
# 	none.
# Return:
#	void.
clear_key_press:
	sw zero, KEY_INPUT_ADDRESS, t0
	jr ra
	
# Function: clear_key_status
# Parameters:
# 	none.
# Return:
#	void.
clear_key_status:
	sw zero, KEY_STATUS_ADDRESS, t0
	jr ra


end:

j end
