# Kerman - Kernel Manager

Handles all of tasks typically done after running make install on
the kernel source. Generates and deletes efi boot entries, removes old modules,
removes old kernels. Appends version number/string to the kernel.

example usage: kerman -a 5.10.17-kiss | kerman -r 4.19.176-LTS
