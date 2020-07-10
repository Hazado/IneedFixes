{
	Purpose: Reference Replace
	Game: The Elder Scrolls V: Skyrim SE
	Author: Sandman53
	Version: 1.1
	Instructions:
	1. Add Editor IDs and Masters
	2. Apply Script
}

unit UserScript;

//-------------------------------------------------------------------------------
// Global Variables
//-------------------------------------------------------------------------------
var
	stReplaceReference, stRefName: TStringList;
	userFile, iReplaceRef: IInterface;
	sRefType: string;

//-------------------------------------------------------------------------------
// Initialize Variables and File
//-------------------------------------------------------------------------------
function Initialize: integer;
	var 
		stObjectEID, stSplitText: TStringList;
		i, n: integer;
		sModName, sRefName, sRefType: string;
		iRef, searchFile: IInterface;

	begin
		//-------------------------------------------------------------------------------
		// Setup Variables
		//-------------------------------------------------------------------------------
		// Mod Name
		sModName := 'iNeed - Extended.esp';

		// Base Objects that will replacing existing object. The delimiter seperates the objects type
		stObjectEID := TStringList.Create;
		stObjectEID.Add('_SNSnowDriftL01;ACTI'); // 0
		stObjectEID.Add('_SNSnowDriftL02;ACTI'); // 1
		stObjectEID.Add('_SNSnowDriftL03;ACTI'); // 2
		stObjectEID.Add('_SNSnowDriftL04;ACTI'); // 3
		stObjectEID.Add('_SNSnowDriftM01;ACTI'); // 4
		stObjectEID.Add('_SNSnowDriftM02;ACTI'); // 5
		stObjectEID.Add('_SNSnowDriftSm01;ACTI'); // 6
		stObjectEID.Add('_SNSnowDriftSm02;ACTI'); // 7
		stObjectEID.Add('_SNSnowDriftSm03;ACTI'); // 8
		stObjectEID.Add('_SNSnowDriftSm04;ACTI'); // 9
		stObjectEID.Add('_SNSnowDriftL01Interior;ACTI'); // 10
		stObjectEID.Add('_SNSnowDriftL02Interior;ACTI'); // 11
		stObjectEID.Add('_SNSnowDriftL03Interior;ACTI'); // 12
		stObjectEID.Add('_SNSnowDriftL04Interior;ACTI'); // 13
		stObjectEID.Add('_SNSnowDriftM01Interior;ACTI'); // 14
		stObjectEID.Add('_SNSnowDriftM02Interior;ACTI'); // 15
		stObjectEID.Add('_SNSnowDriftSm01Interior;ACTI'); // 16
		stObjectEID.Add('_SNSnowDriftSm02Interior;ACTI'); // 17
		stObjectEID.Add('_SNSnowDriftSm03Interior;ACTI'); // 18
		stObjectEID.Add('_SNSnowDriftSm04Interior;ACTI'); // 19

		// Editor ID of Objects to replace. Include the Type and the corresponding reference above to replace with
		stReplaceReference := TStringList.Create;
		stReplaceReference.Add('SnowDriftL01;STAT;0');
		stReplaceReference.Add('SnowDriftL02;STAT;1');
		stReplaceReference.Add('SnowDriftL03;STAT;2');
		stReplaceReference.Add('SnowDriftL04;STAT;3');
		stReplaceReference.Add('SnowDriftM01;STAT;4');
		stReplaceReference.Add('SnowDriftM02;STAT;5');
		stReplaceReference.Add('SnowDriftSm01;STAT;6');
		stReplaceReference.Add('SnowDriftSm02;STAT;7');
		stReplaceReference.Add('SnowDriftSm03;STAT;8');
		stReplaceReference.Add('SnowDriftSm04;STAT;9');
		stReplaceReference.Add('SnowDriftL01Interior;STAT;10');
		stReplaceReference.Add('SnowDriftL02Interior;STAT;11');
		stReplaceReference.Add('SnowDriftL03Interior;STAT;12');
		stReplaceReference.Add('SnowDriftL04Interior;STAT;13');
		stReplaceReference.Add('SnowDriftM01Interior;STAT;14');
		stReplaceReference.Add('SnowDriftM02Interior;STAT;15');
		stReplaceReference.Add('SnowDriftSm01Interior;STAT;16');
		stReplaceReference.Add('SnowDriftSm02Interior;STAT;17');
		stReplaceReference.Add('SnowDriftSm03Interior;STAT;18');
		stReplaceReference.Add('SnowDriftSm04Interior;STAT;19');
		
		//-------------------------------------------------------------------------------
		// Get Main Form IDs
		//-------------------------------------------------------------------------------
		// Save Main Editor FormIDs for later
		stRefName := TStringList.Create;
		for i := 0 to Pred(FileCount) do begin
			searchFile := FileByIndex(i);
			if (GetFileName(searchFile) = sModName) then begin
				RemoveNode(GroupBySignature(searchFile, 'CELL'));
				RemoveNode(GroupBySignature(searchFile, 'WRLD'));
				userFile := searchFile;
				for n := 0 to stObjectEID.Count-1 do begin
					// Split string for Name and Type
					stSplitText := TStringList.Create;
					SplitText(';', stObjectEID[n], stSplitText);
					sRefName := stSplitText[0];
					sRefType := stSplitText[1];
					iRef := MainRecordByEditorID(GroupBySignature(searchFile, sRefType), sRefName);
					stRefName.add(GetEditValue(ElementByPath(iRef, 'Record Header\FormID')));
				end;
			end;
		end;	

		//-------------------------------------------------------------------------------
		// File Creation
		//-------------------------------------------------------------------------------
		
		if not Assigned(userFile) then begin
			AddMessage('Failed to create patch.');
			exit;
		end;

		// Patch will be an ESL
		SetFlag(ElementByPath(ElementByIndex(userFile, 0), 'Record Header\Record Flags'), 9, true);
		
		// Add Base Masters
		CleanMasters(userFile);
		AddMasterIfMissing(userFile, 'Skyrim.esm');
		AddMasterIfMissing(userFile, 'Update.esm');
		AddMasterIfMissing(userFile, 'Dawnguard.esm');
		AddMasterIfMissing(userFile, 'HearthFires.esm');
		AddMasterIfMissing(userFile, 'Dragonborn.esm');
		//AddMasterIfMissing(userFile, sModName);
	 	SortMasters(userFile);
	end;

//-------------------------------------------------------------------------------
// Update all Objects
//-------------------------------------------------------------------------------
function Finalize: Integer;
	var
		stProcessedForms, stSplitText: TStringList;
		baseIndex, i, refIndex, recIndex, baseObject: integer;
		iSearchRef, iFoundRef, iNewRef, iRef, iCell, iCellCopy, iGroup: IInterface;
		sFormID, sRefName, sRefType: string;
		frm: TForm;
		clb: TCheckListBox;
	begin

		AddMessage('-------------------------------------------------------------------------------');
		AddMessage( 'Modifying References' );
		AddMessage('-------------------------------------------------------------------------------');

		// Setup Processed List
		stProcessedForms := TStringList.Create;

		// Process each Base Form
		for baseIndex := 0 to stReplaceReference.Count-1 do begin

			// Split the current string and extract Name, Type and the replacement object
			stSplitText := TStringList.Create;
			SplitText(';', stReplaceReference[baseIndex], stSplitText);
			sRefName := stSplitText[0];
			sRefType := stSplitText[1];
			baseObject := stSplitText[2];

			// Find the Base Form ID of the object we are working with
			for i := 0 to Pred(FileCount) do begin
				iSearchRef := MainRecordByEditorID(GroupBySignature(FileByIndex(i), sRefType), sRefName);

				if Assigned(iSearchRef) then
					break;
			end;

			// Get all of the references to the Base Form
			for refIndex := ReferencedByCount(MasterOrSelf(iSearchRef))-1 downto 0 do begin
				iFoundRef := ReferencedByIndex(MasterOrSelf(iSearchRef), refIndex);
				sFormID := GetEditValue(ElementByPath(iFoundRef, 'Record Header\FormID'));

				// If it is not a reference we skip it
				if Signature(iFoundRef) <> 'REFR' then
					continue;

				// Make sure we have not already processed it
				if (wbStringListInString(stProcessedForms, sFormID) = -1) then begin

					AddMessage('Comparing ' + sformId + ' element ' + Name(iSearchRef) + ', name ' + GetElementEditValues(iFoundRef, 'NAME'));
					if not ( IsWinningOverride(iFoundRef)) then begin
						AddMessage('Skipping reference ' + sformID); 
						stProcessedForms.add(sFormID);
						continue;
					end;
				
					// Copy Cell Data
					iCell := WinningOverride(LinksTo(ElementByName(iFoundRef, 'Cell')));
					UpdateMasters(iCell);
					
					iCellCopy := wbCopyElementToFile(iCell, userFile, false, true);

					// Add Required masters and copy element to our file
					UpdateMasters(iFoundRef);
					iNewRef := wbCopyElementToFile(iFoundRef, userFile, false, true);

					// Update the reference with the new name
					SetElementEditValues(iNewRef, 'NAME', stRefName[baseObject]);

					// Show Processing Message
					if GetElementEditValues(iCellCopy, 'FULL') = '' then
						AddMessage('Modified Reference at: ' + GetElementEditValues(iCellCopy, 'Worldspace'))
					else
						AddMessage('Modified Reference at: ' + GetElementEditValues(iCellCopy, 'FULL'));

					// Add the form we just processed
					stProcessedForms.add(sFormID);
				end;

			end;
			
			// Clean Masters
			CleanMasters(userFile);
		end;

		// Clean and Sort Masters
		CleanMasters(userFile);
	 	SortMasters(userFile);

		// Free Memory
		stProcessedForms.Free;

		AddMessage('-------------------------------------------------------------------------------');
		AddMessage('Processing Complete');
		AddMessage('-------------------------------------------------------------------------------');
	end;

//-------------------------------------------------------------------------------
// Split String
//-------------------------------------------------------------------------------
procedure SplitText(aDelimiter: Char; const s: String; aList: TStringList);
	begin
		aList.Delimiter := aDelimiter;
		aList.StrictDelimiter := True; // Spaces excluded from being a delimiter
		aList.DelimitedText := s;
	end;

//-------------------------------------------------------------------------------
// Set Flags
//-------------------------------------------------------------------------------
procedure SetFlag(element: IInterface; index: Integer; state: boolean);
	var
	  mask: Integer;
	begin
	  mask := 1 shl index;
	  if state then
	    SetNativeValue(element, GetNativeValue(element) or mask)
	  else
	    SetNativeValue(element, GetNativeValue(element) and not mask);
	end;

//-------------------------------------------------------------------------------
// Update Masters
//-------------------------------------------------------------------------------
procedure UpdateMasters(element: IInterface);
	var
	  i: Integer;
	  workFile: iwbFile;
	begin
		workFile := GetFile(element);
		for i := 0 to MasterCount(workFile) - 1 do begin
			AddMasterIfMissing(userFile, GetFileName(MasterByIndex(workFile, i)));
		end;
		AddMasterIfMissing(userFile, GetFileName(workFile));
	end;

end.