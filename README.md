# Roblox Luau Language Server

[Original Project](https://github.com/sumneko/lua-language-server) by [sumneko](https://github.com/sumneko). I used [this](https://github.com/codesenseAye/roblox-lsp-plus-knit) version of it made by [codesenseAye](https://github.com/codesenseAye), big thanks to him for adding Knit support.

Make sure you don't have both [Lua](https://marketplace.visualstudio.com/items?itemName=sumneko.lua) by sumneko and Roblox LSP enabled.

## Cleaning the source code

Me, msix29 took the decision to clean the source code and I've done so for the most part but have stopped and this extension has been discontinued. It's completely functional though

## Install In VSCode

[Extension Link](https://marketplace.visualstudio.com/items?itemName=Msix29.roblox-lsp-with-knit)

## Get Help

[Roblox OS Community Discord Server](https://discord.gg/c4nPcZHwFU)

## Features

- [x] Full Roblox Environment
- [x] Support for Luau static typing
- [x] Full support for [Rojo](https://github.com/Roblox/rojo)
- [x] Support for Third-Party libraries like Roact, Rodux, Promise, TestEz, etc.
- [x] Auto-completion for instances in Roblox Studio
- [x] Auto-updatable API
- [x] Inlay Hints
- [x] Color3 Preview and Picker
- [x] Goto Definition
- [x] Find All References
- [x] Hover
- [x] Diagnostics
- [x] Rename
- [x] Auto Completion
- [x] IntelliSense
- [x] Signature Help
- [x] Document Symbols
- [x] Workspace Symbols
- [x] Syntax Check
- [x] Highlight
- [x] Code Action
- [x] Multi Workspace
- [x] Semantic Tokens

## CodesenseAye Additions

- [x] Knit Go-to File
- [x] Knit Go-to Method
- [x] Knit Method Auto Completion
- [x] Knit Method Signature Help
- [x] Knit Method Auto Import
- [x] Knit Method Hover

## My additions

- [x] Support for JSDoc (@params and @return)
- [x] Some fixes to the hover provider
- [x] Knit.GetController only gets controllers now
- [x] Knit.GetService only gets services now
- [x] Knit.GetController/Knit.GetService don't get underlined if the corresponding file wasn't found (indicating no link/goto meaning you have done something wrong.)
- [x] Detecting Knit controllers/services have been changed from checking name of the file to checking the source of it
- [x] Cleaned up all the code from start to finish
- [x] Added explanation files so it's easier for users to edit the extension
- [x] Added LuaDoc/JSDoc comments toa ll functions to indicate types as well as a small explanation at the top

### Preview

![avatar](https://i.imgur.com/4sgYDii.gif)
![avatar](https://i.imgur.com/vHbKIJ0.gif)
![avatar](https://cdn.discordapp.com/attachments/434146484758249482/778145929345368064/test.gif)

### CodesenseAye Additions Preview

![avatar](https://i.imgur.com/3cv1NER.gif)
Knit Method Auto Import

![avatar](https://i.imgur.com/oPm0UyW.gif)
Knit Go-to File

![avatar](https://i.imgur.com/nUPGEks.gif)
Knit Method Auto Completion

![avatar](https://i.imgur.com/0DPDhi2.png)
Knit Method Hover (use CTRL to go-to method)

### My additions preview

![avater](https://imgur.com/ue6necB.png)
GetController and GetService only show the correct corresponding type of file

![avater](https://imgur.com/mx1JPSn.png)
Adds goto even though the name doesn't correspond to the file name but corresponds to the service name

![avater](https://imgur.com/OZWg98M.png)
JSDoc support

[Explanation file](explanation.md)

---

The rest of my additions are all back-end, it's mainly to allow other developers to add their own features, if needed, and make the process of doing so seamlessly easy, it was painful to figure out most of this alone when I wanted to add features so yea.

## Credit

- [lua-language-server](https://github.com/sumneko/lua-language-server)
- [vscode-luau](https://github.com/Dekkonot/vscode-luau)
- [bee.lua](https://github.com/actboy168/bee.lua)
- [luamake](https://github.com/actboy168/luamake)
- [lni](https://github.com/actboy168/lni)
- [LPegLabel](https://github.com/sqmedeiros/lpeglabel)
- [LuaParser](https://github.com/sumneko/LuaParser)
- [rcedit](https://github.com/electron/rcedit)
- [ScreenToGif](https://github.com/NickeManarin/ScreenToGif)
- [vscode-languageclient](https://github.com/microsoft/vscode-languageserver-node)
- [lua.tmbundle](https://github.com/textmate/lua.tmbundle)
- [EmmyLua](https://emmylua.github.io)
- [lua-glob](https://github.com/sumneko/lua-glob)
- [utility](https://github.com/sumneko/utility)
- [json.lua](https://github.com/actboy168/json.lua)

## Acknowledgement

- [NightrainsRbx](https://github.com/NightrainsRbx)
- [codesenseAye](https://github.com/codesenseAye)
- [sumneko](https://github.com/sumneko)
- [actboy168](https://github.com/actboy168)
- [Dekkonot](https://github.com/Dekkonot)
- [Dmitry Sannikov](https://github.com/dasannikov)
- [Jayden Charbonneau](https://github.com/Reshiram110)
- [Stjepan Bakrac](https://github.com/z16)
- [Peter Young](https://github.com/young40)
- [Li Xiaobin](https://github.com/Xiaobin0860)
- [Fedora7](https://github.com/Fedora7)
- [Allen Shaw](https://github.com/shuxiao9058)
- [Bartel](https://github.com/Letrab)
- [Ruin0x11](https://github.com/Ruin0x11)
- [uhziel](https://github.com/uhziel)
- [火凌之](https://github.com/PhoenixZeng)
- [CppCXY](https://github.com/CppCXY)
- [Ketho](https://github.com/Ketho)
- [Folke Lemaitre](https://github.com/folke)
