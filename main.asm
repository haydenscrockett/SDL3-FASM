format elf64 executable
entry start

include     "import64.inc"                ; also requires elf.inc dependency
interpreter "/lib64/ld-linux-x86-64.so.2"
needed      "libSDL3.so"                  ; add libc.so.6 for C functions if desired

import SDL_CreateWindowAndRenderer, SDL_Delay, SDL_DestroyRenderer, SDL_DestroyWindow, SDL_GetTicks, SDL_Init, SDL_Log, SDL_PollEvent, SDL_Quit, SDL_RenderClear, SDL_RenderPresent



segment readable writeable

title db "FASM SDL3 App", 0

ticks rb 64



segment readable executable


start:    

    mov    qword [rsp],      0 ; window   = NULL
    mov    qword [rsp + 8],  0 ; renderer = NULL
    mov    qword [rsp + 16], 0 ; event    = NULL

    mov    rdi, 32    ; 32 is SDL_INIT_VIDEO
    call   [SDL_Init] ; initialize SDL

    ;call   [SDL_GetTicks]
    ;implement logic to convert rax (int) to string
    ;mov    rdi, rax
    ;call   [SDL_Log]

    lea    rdi, [title]                  ; title  = FASM SDL3 App
    mov    rsi, 640                      ; width  = 640px
    mov    rdx, 480                      ; height = 480px
    xor    rcx, rcx                      ; flags  = none | 32 = resizable but crashes
    mov    r8,  rsp                      ; &window
    lea    r9,  [rsp + 8]                ; &renderer
    call   [SDL_CreateWindowAndRenderer] ; build window according to arguments

    mov    rdi, [rsp + 8]      ; renderer
    call   [SDL_RenderPresent] ; update


poll:

    lea    rdi, [rsp + 16] ; &event
    call   [SDL_PollEvent] ; poll for events

    test   al, al ; if (AL == 0) {ZF = 1}, else if (AL == 1) {ZF = 0}
    jnz    event  ; jump to event handling if event detected


render:

    mov    rdi, [rsp + 8]    ; renderer
    call   [SDL_RenderClear] ; fill background with current color

    call   [SDL_RenderPresent] ; update

    mov    rdi, 16     ; ~60 fps | use GetTicks later for precision
    call   [SDL_Delay] ; wait for 16 ms

    jmp    poll ; jump to poll to check for events again


event:

    cmp    qword [rsp + 16], 256 ; SDL_EVENT_QUIT
    je     exit                  ; jump to exit if program exit attempted

    cmp    qword [rsp + 16], 768 ; SDL_EVENT_KEY_DOWN
    je     key_down              ; jump to key down logic

    cmp    qword [rsp + 16], 769 ; SDL_EVENT_KEY_UP
    je     key_up                ; jump to key up logic

    jmp    poll ; jump to poll to check for events again


key_down:

    cmp    dword [rsp + 44], 27 ; SDLK_ESCAPE
    je     exit

    ret ; return to path in event


key_up:

    ret ; return to path in event


exit:

    mov    rdi, qword [rsp + 8]  ; renderer
    call   [SDL_DestroyRenderer] ; remove renderer

    mov    rdi, qword [rsp]    ; window
    call   [SDL_DestroyWindow] ; remove window

    call   [SDL_Quit] ; deinitialize SDL

    mov    rax, 60
    xor    rdi, rdi
    syscall