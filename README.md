# Assembler_2sem
Assembler programs in MS DOS of 2 term MIPT 

# Installing
1. Full setup of Dos-Box+Volkov-Commander+Asm: [ded32.net.ru/storage.ded32.ru/Materials/TXLib/dosbox-asm-setup.rar.exe](http://nas.ded32.ru/storage.ded32.ru/Materials/TXLib/dosbox-asm-setup.rar.exe)
2. Emulator of DosBox+Asm by yourself

# List of programs with description

- [```Frame```](#frame)
- [```Cringe Video Memory```](#cringe-video-memory)
- [```Resident Registers```](#resident-registers)
- [```Cracking```](#cracking)

## Frame
[FRAME.ASM](https://github.com/khmelnitskiianton/Assembler_2sem/blob/main/FRAME.ASM) & [FRAME.COM](https://github.com/khmelnitskiianton/Assembler_2sem/blob/main/FRAME.COM)

Program that draws a frame in DOS with parametrs. Read info in asm code before run. By addressing to video memory in Dos we can change viewing, you can setup frame with length, width, color(in hex) and choose number of style, write text in it too.

<img src="https://github.com/khmelnitskiianton/Assembler_2sem/assets/142332024/f7fe785a-9ce3-4958-b36f-370fbd2cad42)" width=50%>

## Cringe Video Memory
[CRINGE.ASM](https://github.com/khmelnitskiianton/Assembler_2sem/blob/main/CRINGE.ASM) & [CRINGE.COM](https://github.com/khmelnitskiianton/Assembler_2sem/blob/main/CRINGE.COM)

Cringe program that copy segment of data to segment of memory in DOS and look what you have :)

<img src="https://github.com/khmelnitskiianton/Assembler_2sem/assets/142332024/315cbdda-e508-482c-8366-4481722575f9" width=50%>

## Resident Registers
[RESIDENT.ASM](https://github.com/khmelnitskiianton/Assembler_2sem/blob/main/RESIDENT.ASM) & [RESIDENT.COM](https://github.com/khmelnitskiianton/Assembler_2sem/blob/main/RESIDENT.COM) 

Program rendering actual values of all registers in frame like a piece of TurboDebugger. By hot-keys like `CTRL+A`/`CTRL+X` you can turn on/off rendering by timer.

<img src="https://github.com/khmelnitskiianton/Assembler_2sem/assets/142332024/35e6ed65-a72d-40da-b76c-71994d0c49b7" width=50%>

It uses interrupts - 09 for analyze hot-keys and 08 for timer and resident saving in memory for code!

Press `CTRL+A` to start rendering every 55ms and press `CTRL+X` to stop rendering regs.
## Cracking
-
