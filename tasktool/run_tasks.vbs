' tasktool launcher: opens build\tasktool.exe (GUI) without a console window.
' NOTE: tasktool.exe is a GUI-subsystem app, so no black window appears on its own.
' Use window style 1 (SW_SHOWNORMAL): style 0 (SW_HIDE) would keep the Qt window hidden.
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
exe = fso.BuildPath(scriptDir, "build\tasktool.exe")
If Not fso.FileExists(exe) Then
    MsgBox "Cannot find " & exe & vbCrLf & _
           "Build first: cmake -S . -B build -DCMAKE_PREFIX_PATH=""<Qt6 mingw_64>""" & vbCrLf & _
           "cmake --build build", vbCritical, "tasktool launch failed"
    WScript.Quit 1
End If
Set sh = CreateObject("WScript.Shell")
sh.Run Chr(34) & exe & Chr(34), 1, False
