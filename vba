Public Sub GenerateRunupReductionFiles()
    Dim sRunupRedFactorFilePath As String
    Dim sSourceRunupFolderPath As String
    Dim sSourceRunupFilePath As String
    Dim sNewRunupFolderPath As String
    Dim pFSO As New FileSystemObject
    Dim pFolder As Folder
    Dim pTextStream As TextStream
    Dim sLine As String
    Dim sSplitLine() As String
    Dim DictRunupRedVals As New Dictionary
    
    'INPUT PARAMETERS - SHOULD BE CHANGED WHEN NEW AREAS ARE PROCESSED
    sRunupRedFactorFilePath = "P:\02\NY\Chautauqua_Co_36013C\STUDY__TO90\TECHNICAL\ENG_FLOOD_HAZ_DEV\COASTAL\WAVE_MODELING\WAVE_RUNUP\Chautauqua_NY_Roughness.txt" 'CHANGE
    sSourceRunupFolderPath = "P:\02\NY\Chautauqua_Co_36013C\STUDY__TO90\TECHNICAL\ENG_FLOOD_HAZ_DEV\COASTAL\WAVE_MODELING\CSHORE\STATS_2perRunup\output\before_applying_Roughness_coefficient" 'CHANGE
    sNewRunupFolderPath = "P:\02\NY\Chautauqua_Co_36013C\STUDY__TO90\TECHNICAL\ENG_FLOOD_HAZ_DEV\COASTAL\WAVE_MODELING\CSHORE\STATS_2perRunup\output\after_applying_Roughness_coefficient"        'CHANGE
    'INPUT PARAMETERS - SHOULD BE CHANGED WHEN NEW AREAS ARE PROCESSED
    
    
    'Check if files and folders exist
    If pFSO.FileExists(sRunupRedFactorFilePath) = False Then
        MsgBox "Runup reduction file doesn't exist", vbOKOnly, "File doesn't exist"
       Exit Sub
    End If
    
    If pFSO.FolderExists(sSourceRunupFolderPath) = False Then
       MsgBox "Source Folder doesn't exist", vbOKOnly, "Folder doesn't exist"
       Exit Sub
    End If
     
    If pFSO.FolderExists(sNewRunupFolderPath) = False Then
       MsgBox "Destination Folder doesn't exist", vbOKOnly, "Folder doesn't exist"
       Exit Sub
    End If
     
    'Read Runup reduction factors
    Set pTextStream = pFSO.OpenTextFile(sRunupRedFactorFilePath, ForReading)
    Do While pTextStream.AtEndOfStream <> True
        sLine = Trim(pTextStream.ReadLine)
        If sLine <> "" Then
            sSplitLine = Split(sLine, ",") 'SplitString(sLine)
'            Debug.Print sSplitLine(0) & ":" & sSplitLine(1)
'            Debug.Print "Next"
            'DictRunupRedVals.Add Str(Trim(sSplitLine(0))), CDbl(sSplitLine(1))
            DictRunupRedVals.Add sSplitLine(0), sSplitLine(1)
'            Debug.Print sSplitLine(0) & "," & DictRunupRedVals.Item(sSplitLine(0))
        End If
    Loop
    
    pTextStream.Close
    
    'Check if there are runup reductions populated
    If DictRunupRedVals.Count = 0 Then
        MsgBox "Check runup reduction text file", vbOKOnly
        Exit Sub
    End If
    
    Dim pSrcFolder As Folder
    Dim pSrcFile As File
    Dim lFileCount As Long
    Dim sOPFile As String
    Dim linecount As Long
    Dim sRunupArray() As String
    Dim dblArray() As Double
    Dim sRevString As String
    Dim sTransectID As String
    
'    Dim pTargetFolder As Folder
'    Dim pTargetFile As File
    'Read Source Files
    Set pSrcFolder = pFSO.GetFolder(sSourceRunupFolderPath)
    For Each pSrcFile In pSrcFolder.Files
        lFileCount = lFileCount + 1
        'Debug.Print "Processing : " & pSrcFile.Name
        sOPFile = sNewRunupFolderPath & "\" & pSrcFile.Name
        sTransectID = Split(pSrcFile.Name, "_")(0)
        Debug.Print "Processing transect ID: " & sTransectID
        Open sOPFile For Output As #1
        Set pTextStream = pSrcFile.OpenAsTextStream
        linecount = 0
        Do While pTextStream.AtEndOfStream <> True
            sLine = pTextStream.ReadLine
            linecount = linecount + 1
            sRunupArray = Split(sLine, " ")
'            Debug.Print sRunupArray(0) & " : " & sRunupArray(1) & " : " & sRunupArray(2) & " : " & sRunupArray(3) & " : " & sRunupArray(4)
            If sRunupArray(1) <> "NaN" Then
                'Debug.Print FormatNumber(CDbl(sRunupArray(2)) + CDbl(sRunupArray(3)) * CDbl(DictRunupRedVals(sTransectID)), 6)
'                Debug.Print CDbl(DictRunupRedVals(sTransectID))
                sRevString = Replace(sLine, sRunupArray(1), FormatNumber(CDbl(sRunupArray(2)) + CDbl(sRunupArray(3)) * CDbl(DictRunupRedVals(sTransectID)), 6))
                sRevString = Replace(sRevString, sRunupArray(3), FormatNumber(CDbl(sRunupArray(3)) * CDbl(DictRunupRedVals(sTransectID)), 6))
'                Debug.Print sRevString
                Print #1, sRevString
            Else
                sRevString = sRunupArray(0) & " 0.000000 0.000000 0.000000 0.000000" 'Replace(sLine, sRunupArray(1), "0.000000")
                Print #1, sRevString
            End If
'            Debug.Print sLine
'            Debug.Print sRevString '& " " & sRunupArray(1)
            'Print #1, sRevString & " " & sRunupArray(1)
        Loop
        pTextStream.Close
        Close #1
    Next pSrcFile
 
 
End Sub
