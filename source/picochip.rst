. picopcb

.. _picochip :

PicoChip
========

Programming Picochip's Program Memory
-------------------------------------


Generating the programmable file
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Picochip uses the open-source PicoRV32 processor which implements the RISC-V RV32IMC Instruction Set. To generate the programmable file, an installation of the RISC-V GNU toolchain is required. The source files and instructions to install the toolchain can be found in `the RISC-V GNU Compiler Toolchain GitHub repository <https://github.com/riscv/riscv-gnu-toolchain>`_
. Make sure to install the toolchain for the 32bit ISA.

After installing the compiler toolchain, the linker script file should be generated to tell the linker which addresses are used for the data memory and which are for the program memory. For this purpose, copy the following to a file named sections.lds:

.. code:: bash

	#ifdef PICOCHIP
	#  define MEM_TOTAL 0x10000 /* 64 KB */
	#elif ICEBREAKER
	#  define MEM_TOTAL 0x20000 /* 128 KB */
	#elif HX8KDEMO
	#  define MEM_TOTAL 0x200 /* 2 KB */
	#else
	#  error "Set -DICEBREAKER or -DHX8KDEMO when compiling firmware.c"
	#endif

	MEMORY
	{
		FLASH (rx)      : ORIGIN = 0x00100000, LENGTH = 0x400000 /* entire flash, 4 MiB */
		RAM (xrw)       : ORIGIN = 0x00000000, LENGTH = MEM_TOTAL
	}

	SECTIONS {
		/* The program code and other data goes into FLASH */
		.text :
		{
			. = ALIGN(4);
			*(.text)           /* .text sections (code) */
			*(.text*)          /* .text* sections (code) */
			*(.rodata)         /* .rodata sections (constants, strings, etc.) */
			*(.rodata*)        /* .rodata* sections (constants, strings, etc.) */
			*(.srodata)        /* .rodata sections (constants, strings, etc.) */
			*(.srodata*)       /* .rodata* sections (constants, strings, etc.) */
			. = ALIGN(4);
			_etext = .;        /* define a global symbol at end of code */
			_sidata = _etext;  /* This is used by the startup in order to initialize the .data secion */
		} >FLASH


		/* This is the initialized data section
		The program executes knowing that the data is in the RAM
		but the loader puts the initial values in the FLASH (inidata).
		It is one task of the startup to copy the initial values from FLASH to RAM. */
		.data : AT ( _sidata )
		{
			. = ALIGN(4);
			_sdata = .;        /* create a global symbol at data start; used by startup code in order to initialise the .data section in RAM */
			_ram_start = .;    /* create a global symbol at ram start for garbage collector */
			. = ALIGN(4);
			*(.data)           /* .data sections */
			*(.data*)          /* .data* sections */
			*(.sdata)           /* .sdata sections */
			*(.sdata*)          /* .sdata* sections */
			. = ALIGN(4);
			_edata = .;        /* define a global symbol at data end; used by startup code in order to initialise the .data section in RAM */
		} >RAM

		/* Uninitialized data section */
		.bss :
		{
			. = ALIGN(4);
			_sbss = .;         /* define a global symbol at bss start; used by startup code */
			*(.bss)
			*(.bss*)
			*(.sbss)
			*(.sbss*)
			*(COMMON)

			. = ALIGN(4);
			_ebss = .;         /* define a global symbol at bss end; used by startup code */
		} >RAM

		/* this is to define the start of the heap, and make sure we have a minimum size */
		.heap :
		{
			. = ALIGN(4);
			_heap_start = .;    /* define a global symbol at heap start */
		} >RAM
	}
	   
Then, run the following command:

.. code:: bash

    riscv32-unknown-elf-cpp -P -D PICOCHIP -o picochip_sections.lds sections.lds

This will generate the linker script for Picochip (picochip_sections.lds) which should look similar to the code shown below:

.. code:: bash

	MEMORY
	{
		FLASH (rx) : ORIGIN = 0x00100000, LENGTH = 0x400000
		RAM (xrw) : ORIGIN = 0x00000000, LENGTH = 0x10000
	}
	SECTIONS {
		.text :
		{
			. = ALIGN(4);
			*(.text)
			*(.text*)
			*(.rodata)
			*(.rodata*)
			*(.srodata)
			*(.srodata*)
			. = ALIGN(4);
			_etext = .;
			_sidata = _etext;
		} >FLASH
		.data : AT ( _sidata )
		{
			. = ALIGN(4);
			_sdata = .;
			_ram_start = .;
			. = ALIGN(4);
			*(.data)
			*(.data*)
			*(.sdata)
			*(.sdata*)
			. = ALIGN(4);
			_edata = .;
		} >RAM
		.bss :
		{
			. = ALIGN(4);
			_sbss = .;
			*(.bss)
			*(.bss*)
			*(.sbss)
			*(.sbss*)
			*(COMMON)
			. = ALIGN(4);
			_ebss = .;
		} >RAM
		.heap :
		{
			. = ALIGN(4);
			_heap_start = .;
		} >RAM
	}

The last file required to generate the final programmable binary is the boot code. The following is a simple boot code to initialize the memory sections and start fetching the code from the FLASH memory. Save them in a file named start.s.

.. code:: bash

	.section .text

	start:

	# zero-initialize register file
	addi x1, zero, 0
	# x2 (sp) is initialized by reset
	addi x3, zero, 0
	addi x4, zero, 0
	addi x5, zero, 0
	addi x6, zero, 0
	addi x7, zero, 0
	addi x8, zero, 0
	addi x9, zero, 0
	addi x10, zero, 0
	addi x11, zero, 0
	addi x12, zero, 0
	addi x13, zero, 0
	addi x14, zero, 0
	addi x15, zero, 0
	addi x16, zero, 0
	addi x17, zero, 0
	addi x18, zero, 0
	addi x19, zero, 0
	addi x20, zero, 0
	addi x21, zero, 0
	addi x22, zero, 0
	addi x23, zero, 0
	addi x24, zero, 0
	addi x25, zero, 0
	addi x26, zero, 0
	addi x27, zero, 0
	addi x28, zero, 0
	addi x29, zero, 0
	addi x30, zero, 0
	addi x31, zero, 0

	# copy data section
	la a0, _sidata
	la a1, _sdata
	la a2, _edata
	bge a1, a2, end_init_data
	loop_init_data:
	lw a3, 0(a0)
	sw a3, 0(a1)
	addi a0, a0, 4
	addi a1, a1, 4
	blt a1, a2, loop_init_data
	end_init_data:

	# zero-init bss section
	la a0, _sbss
	la a1, _ebss
	bge a0, a1, end_init_bss
	loop_init_bss:
	sw zero, 0(a0)
	addi a0, a0, 4
	blt a0, a1, loop_init_bss
	end_init_bss:

	# call main
	call main
	loop:
	j loop

	.global flashio_worker_begin
	.global flashio_worker_end

	.balign 4

	flashio_worker_begin:
	# a0 ... data pointer
	# a1 ... data length
	# a2 ... optional WREN cmd (0 = disable)

	# address of SPI ctrl reg
	li   t0, 0x02000000

	# Set CS high, IO0 is output
	li   t1, 0x120
	sh   t1, 0(t0)

	# Enable Manual SPI Ctrl
	sb   zero, 3(t0)

	# Send optional WREN cmd
	beqz a2, flashio_worker_L1
	li   t5, 8
	andi t2, a2, 0xff
	flashio_worker_L4:
	srli t4, t2, 7
	sb   t4, 0(t0)
	ori  t4, t4, 0x10
	sb   t4, 0(t0)
	slli t2, t2, 1
	andi t2, t2, 0xff
	addi t5, t5, -1
	bnez t5, flashio_worker_L4
	sb   t1, 0(t0)

	# SPI transfer
	flashio_worker_L1:
	beqz a1, flashio_worker_L3
	li   t5, 8
	lbu  t2, 0(a0)
	flashio_worker_L2:
	srli t4, t2, 7
	sb   t4, 0(t0)
	ori  t4, t4, 0x10
	sb   t4, 0(t0)
	lbu  t4, 0(t0)
	andi t4, t4, 2
	srli t4, t4, 1
	slli t2, t2, 1
	or   t2, t2, t4
	andi t2, t2, 0xff
	addi t5, t5, -1
	bnez t5, flashio_worker_L2
	sb   t2, 0(a0)
	addi a0, a0, 1
	addi a1, a1, -1
	j    flashio_worker_L1
	flashio_worker_L3:

	# Back to MEMIO mode
	li   t1, 0x80
	sb   t1, 3(t0)

	ret

	.balign 4
	flashio_worker_end:


Finally, to generate the binary file for a C code firmware.c, run the following commands. The final binary file will be generated in a file named picochip_fw.bin.


.. code:: bash

    riscv32-unknown-elf-gcc  -D PICOCHIP -Dmarch=rv32ic -Wl,-Bstatic,-T,picochip_sections.lds,--strip-debug -ffreestanding -nostdlib -o picochip_fw.elf start.s firmware.c
    riscv32-unknown-elf-objcopy -O binary picochip_fw.elf picochip_fw.bin

Programming the SPI Flash
^^^^^^^^^^^^^^^^^^^^^^^^^
To program the flash, two main adjustments should be made to the binary file. First, the on-chip processor expects the first instruction to be located at 1MB deep in the SPI flash (address 0x00100000). Therefore, we need to add non-values (zeros) to the first 1MB part of the binary file. Second, the SPI flash used on picopcb (W25Q128JV-DTR) is 16MB deep. Therefore, we need to pad the binary file to be exactly 16MB. To make these adjustments, on Linux, we use the `truncate <https://www.man7.org/linux/man-pages/man1/truncate.1.html>`_ command as follows:

.. code:: bash

	truncate -s 1M zeros.bin
	cat zeros.bin picochip_fw.bin > concat.bin
	truncate -s 16M concat.bin
	rm zeros.bin


Using the above commands, we will have the new binary file (concat.bin) which is exactly 16MB and the starting code is at the address 0x00100000.


To program the SPI flash (Picochip's program memory) on a Linux system, the `flashrom <https://linux.die.net/man/8/flashrom>`_ utility is used. In order to not write the entire 16MB of flash (and speed up the programming) we use a layout file (picochip.layout) as below:

.. code:: bash

	00000000:000fffff start
	00100000:001fffff program
	00200000:00ffffff remainder

Finally, to write to the SPI flash, use the following command:


.. code:: bash

	flashrom -p ft2232_spi:type=4232H,port=A --layout picochip.layout --image program --write concat.bin

This command only writes to the "program" section in the flash which was specified in the layout file as addresses from 0x00100000 (1MB) to 0x001fffff (2MB).

Furthermore, we can verify the contents of the SPI flash by reading it and saving the results into a file:


.. code:: bash

	flashrom -p ft2232_spi:type=4232H,port=A --read verify.bin


Putting all the codes together, the following Makefile can be used:


.. code:: bash

	all: layout zeros write read

	read:
		@rm -f verify.bin
		flashrom -p ft2232_spi:type=4232H,port=A --read verify.bin

	write:
		flashrom -p ft2232_spi:type=4232H,port=A --layout picochip.layout --image program --write concat.bin


	truncate:
		truncate -s 16M fw.bin

	zeros:
		@truncate -s 1M zeros.bin
		@cat zeros.bin picochip_fw.bin > concat.bin
		@truncate -s 16M concat.bin
		@rm zeros.bin

	layout:
		@rm -f picochip.layout
		@touch picochip.layout
		@echo "00000000:000fffff start" >> picochip.layout
		@echo "00100000:001fffff program" >> picochip.layout
		@echo "00200000:00ffffff remainder" >> picochip.layout
