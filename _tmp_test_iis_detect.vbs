On Error Resume Next

WScript.Echo "== ADSI =="
Set adsiObj = GetObject("IIS://localhost/W3SVC")
If Err.Number <> 0 Then
  WScript.Echo "ADSI_ERR:" & Hex(Err.Number) & ":" & Err.Description
  Err.Clear
Else
  WScript.Echo "ADSI_OK:" & adsiObj.ADsPath
End If

WScript.Echo "== WMI =="
Set wmiSvc = GetObject("winmgmts:root\MicrosoftIISv2")
If Err.Number <> 0 Then
  WScript.Echo "WMI_ERR:" & Hex(Err.Number) & ":" & Err.Description
  Err.Clear
Else
  Set col = wmiSvc.ExecQuery("select * from IIsWebService")
  If Err.Number <> 0 Then
    WScript.Echo "WMI_QUERY_ERR:" & Hex(Err.Number) & ":" & Err.Description
    Err.Clear
  Else
    For Each item In col
      WScript.Echo "WMI_OK:" & item.Name
      Exit For
    Next
    If col.Count = 0 Then
      WScript.Echo "WMI_EMPTY"
    End If
  End If
End If
