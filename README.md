# Custom Printf Implementation in x86-64 Assembly

## Overview
This project implements a custom `printf`-like function (`my_printf`) in x86-64 Assembly, which supports basic format specifiers such as `%s`, `%d`, and `%u`. The implementation processes a format string, extracts parameters from the stack, and prints them to the console using Linux syscalls.

## Features
- Supports the following format specifiers:
  - `%s` for null-terminated strings
  - `%d` for signed integers
  - `%u` for unsigned integers
  - `%%` for printing a literal `%`
- Implements a basic parameter extraction mechanism using the stack.
- Uses `syscall` for outputting characters to standard output.

## Implementation Details
- The `main` function prepares arguments and calls `my_printf`.
- `my_printf` iterates over the format string and processes characters.
- On encountering `%`, it extracts the corresponding argument from the stack and processes it accordingly.
- Uses `syscall` to print characters to standard output.

## Limitations
- Does not support floating-point numbers.
- Only handles a limited set of format specifiers.
- Relies on stack-based argument passing, which may not align with standard x86-64 calling conventions.

