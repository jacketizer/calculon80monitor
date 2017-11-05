CALCULON/80 ROM MONITOR
=======================

A ROM monitor program for the Calculon/80 microcomputer that resides in ROM and
is loaded to RAM at boot. It enables users to control the computer and to load
programs from disk or serial device.

This is a work in progress. While most of the drivers are complete, the HDD
driver and utility programs are yet to be implemented.

ROM Layout
----------

    Addr   Program         Size (bytes)
    ------ --------------- ---------------
    0x0030 Main Program    4k - 40
    0x0000 Bootloader      40

RAM Layout
----------

    Start addr Purpose
    ---------- -------
    0xFFFF     Stack Top
    0xF000     Stack Bottom
    0xE000     Main Program
    0xDC00     BSS: Uninitialized Data
    0x0000     Page Zero: ISR

Device Addresses
----------------

    Device                                  I/O Addr
    --------------------------------------- --------
    Bank Switching Device                   0x00
    Output Port A                           0x0C
    Z80DART Data register                   0x10
    Z80DART Control register                0x11
    IDE Host interface - Data               0x18
    IDE Host interface - Error              0x19
    IDE Host interface - Sector count       0x1A
    IDE Host interface - Sector number      0x1B
    IDE Host interface - Cyliner low        0x1C
    IDE Host interface - Cyliner high       0x1D
    IDE Host interface - Head/Device        0x1E
    IDE Host interface - Status             0x1F
    IDE Host interface - Command            0x1F
    IDE Host interface, High 8-bit          0x20
    CTC - Channel 0                         0x28
    CTC - Channel 1                         0x29
    CTC - Channel 2                         0x2A
    CTC - Channel 3                         0x2B

Bootloader
----------

The bootloader is the first program to be executed when the computer starts.
Its purpose is to test the memory where the Main Program will be loaded and
then copy the Main Program into RAM by doing the following:

  * Disable interrupts
  * Wait for reset line to stabilize
  * Test high RAM (0xE000-0xFFFF)
  * Copy Main Program from ROM (0x0030) to RAM (0xE000)
  * Run Main Program from RAM

The bootloader isn't allowed to utilize any RAM or devices other than what is
needed to test the memory and copy the Main Program. Due to this, the stack can
not be used.

Main Program
------------

This is the program that will be run from RAM once loaded from the ROM by the
bootloader. Its purpose is to initialize all the device drivers, install
interrupt service routines and start the shell program which is a part of the
main program.

The program can be divided into four parts:

  * Shell
  * Utility Programs
  * Libraries
  * Hardware Abstraction Layer (Drivers)

### Shell

The shell is the part the user interact with. It runs on top of the hardware
drivers and lets users run commands.

### Utility Program (not implemented yet)

A collection of useful programs for controlling the computer. The user can run
them from the shell.

### Libraries (not implemented yet)

The libraries are a set of functions for string handling etc.

### Hardware Abstraction Layer

The hardware abstraction layer consists of device drivers which acts like the
BIOS in CP/M and MS-DOS, except that they are invoked as subroutines instead of
system calls (using interrupts or jump tables). The idea is to re-use these
drivers when writing a DOS and to adapt them to allow system calls etc.

#### COM: Character Device Communication

`COM_INIT`, `COM_STATUS`, `COM_READ`, `COM_WRITE`, `COM_TX_OFF`, `COM_TX_ON`

#### ISR: Interrupt Service Routines

Subroutines for installing interrupt service routines.

`ISR_INIT`, `ISR_INSTALL`

#### CTC: General Purpose Timer

`CTC_INIT`, `CTC_ENABLE_INT`, `CTC_DISABLE_INT`, `CTC_SET_VAL`

#### PIO: Parallel I/O

`PIO_INIT`, `PIO_READ`, `PIO_WRITE`

#### MEM: Memory Testing and Mapping

`MEM_TEST`, `MEM_ROM_IN`, `MEM_ROM_OUT`, `MEM_BANK_STATE`

#### HDD (not implemented yet)

`HDD_READ_STATUS, `HDD_READ_ERR`, `HDD_IDENTIFY`, `HDD_EXEC_DIAG`, `HDD_RESET`, `HDD_FORMAT_TRACK`,
`HDD_RECALIBRATE`, `HDD_READ_SECTOR`, `HDD_WRITE_SECTOR`

#### CONSOLE: Console Pseudo Driver

This is a pseudo device driver that wraps a COM channel to allow buffered
input and output as well as a more user friendly user interaction. It abstracts
the console and does not necessarily need to utilize the COM driver for this, if
a graphics device and keyboard is available, it could be used instead.

`CONS_WRITE_CHAR`, `CONS_READ_CHAR`, `CONS_READ_LINE_ECHO`, `CONS_WRITE_STRING`, `CONS_PROCESS`
