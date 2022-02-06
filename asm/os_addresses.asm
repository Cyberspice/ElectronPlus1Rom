
; OS routines
OSRDRM            = &FFB9
OSEVEN            = &FFBF
OSARGS            = &FFDA
OSASCI            = &FFE3
OSWRCH            = &FFEE
OSBYTE            = &FFF4

; Stack
stack_start       = &0100

; OS vectors
FILEV             = &0212
INSV              = &022a
REMV              = &022c
CNPV              = &022e

; OS workspace
uart_evt_flg      = &02c6
adc_conv_last     = &02f7
adc_conv_lsb      = &02f8
adc_conv_msb      = &02fc

; Event numbers
adc_conv_event    = 3
uart_err_event    = 7

; File system numbers
file_system_none  = 0
file_system_rom   = 3

; OSARGS operations (Value for A)
oa_get_fs_number   = 0
