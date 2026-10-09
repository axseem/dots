{
  # The 16AKP10's internal keyboard physically reads Ctrl, Fn, Super, Alt. Fn is
  # handled by the embedded controller and never reaches Linux, so the only
  # movable pair is the leftmost Ctrl and the rightmost Alt; swapping those two
  # turns the row into Alt, Fn, Super, Ctrl.
  #
  # The remap happens in the kernel keymap (hwdb -> udev keyboard builtin ->
  # EVIOCSKEYCODE), so every consumer sees it: virtual consoles, the greetd
  # prompt, X and Wayland. Fn, both Super keys and the right Ctrl/Alt pairs are
  # left alone, and both keys stay Ctrl and Alt for chords such as Ctrl+Alt+Bksp.
  #
  # Scancodes are the set-1 codes atkbd reports, with E0-prefixed keys carrying
  # the 0x80 bit (0x1d is the leftmost Ctrl, 0x38 the rightmost Alt). Only the
  # AT keyboard driver is matched by the DMI key below, so external USB
  # keyboards keep their own layout.
  services.udev.extraHwdb = ''
    evdev:atkbd:dmi:bvn*:bvr*:bd*:svnLENOVO*:pn83JN:*
     KEYBOARD_KEY_1d=leftalt
     KEYBOARD_KEY_38=leftctrl
  '';
}
