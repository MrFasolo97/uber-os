Uber OS
=======

An Unix like operating system for Minecraft mod ComputerCraft

This operating system is still under heavy development

What works
----------
  Multithreading system
  
  User accounts
  
  Kernel modules loading
  
  Shell interpreter
  
  Some utils (ls, cd, edit, ps, kill, clear, modprobe, rm, mv, cp)
  
  File privelegies

  Symlinks

What doesn't
------------
  Kernel modules control
  
  Package manager

Credits
-------
  https://github.com/stravant/LuaMinify - Lua Minifier
  
  http://www.computercraft.info/forums2/index.php?/topic/3479-basic-background-thread-api - Base code for thread manager
  
  https://github.com/1Ridav/ComputerCraft-GUI - GUI Library (porting):

How to install
---------------
  If you are on Linux, install "make", "lua" and run "make" in cloned repository. It will generate out folder, with basic   packages intalled and minified. Copy contents to computer. (~/.minecraft/saves/SAVENAME/computer/ID)
