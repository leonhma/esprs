<!-- after .embuild got created and the error was 'riscv32-esp-elf-gcc: ldproxy: ld missing' run and evaluate 'python .embuild/espressif/esp-idf/v5.3.2/tools/idf_tools.py export --format shell 2>/dev/null' to add the esp-idf tools to the path -->

- try to get the .mold suffix removed in collect2  > this should work
- looking in the local dir collect2 inserts a lot of ../

collect2
- cpath for 'real-ld'
- cpath for 'collect-ld'
- cpath for 'ld.<suffix>'
- path for 'TARGET-ld.<suffix>'
- IFDEF LDD_SUFFIX
    - cpath for ldd_suffix
    - path for ldd_suffix