unit UMapParser;
{ This unit is based on Vitaly Miryanov's excellent article on Run-Time
  Location Information as published in issue 22 of The Delphi Magazine. }

interface

uses
  SysUtils
 ,Classes
 ;

type
  EMapParserError = class(Exception);

type
  TMapParser = class
  { This class represents a parsed detailed .map file which the Delphi linker
    generates }
  private
    FMapFilename: String;
    FMapFile: TextFile;
    FLine: String;
    FLineNr: Integer;
    FPublicsByValue: TStringList;
    FUnits: TStringList;
    FLineNumbers: TStringList;
  protected
    procedure Parse;
    procedure ParseMapOfSegments;
    procedure ParsePublicsByValue;
    procedure ParseLineNumbers;
    procedure InvalidMapFile;
    function ReadLine: Boolean;
    function FindSection(const Section: String): Boolean;
  public
    constructor Create(const AMapFilename: String);
    { Parse the map file AMapFilename, after which you can use the functions
      FindSymbol and FindLineNr to retrieve information from this file }
    destructor Destroy; override;

    function FindSymbol(const Address: Longword; out Symbol: String): Boolean;
    { Given a code address in Address, this function tries to find the
      routine or method at this address and returns its name in Symbol }
    function FindLineNr(const Address: Longword; out UnitName: String;
      out LineNr: Integer): Boolean;
    { Given a code address in Address, this function tries to find the
      corresponding unit name and line number within this unit }
  end;

implementation

{ TMapParser }

constructor TMapParser.Create(const AMapFilename: String);
begin
  inherited Create;
  FMapFilename := AMapFilename;

  FPublicsByValue := TStringList.Create;
  FPublicsByValue.Sorted := True;
  FPublicsByValue.Duplicates := dupError;

  FUnits := TStringList.Create;
  FUnits.Sorted := True;
  FUnits.Duplicates := dupError;

  FLineNumbers := TStringList.Create;
  FLineNumbers.Sorted := True;
  FLineNumbers.Duplicates := dupError;

  Parse;
end;

destructor TMapParser.Destroy;
begin
  FPublicsByValue.Free;
  FUnits.Free;
  FLineNumbers.Free;
  inherited;
end;

function TMapParser.FindLineNr(const Address: Longword;
  out UnitName: String; out LineNr: Integer): Boolean;
var
  S1: String;
  Index: Integer;

  function CheckAddress(const Index: Integer): Boolean;
  var
    S, S2: String;
    I, UnitIndex: Integer;
    Start, Length: Longword;
  begin
    Result := (Index >= 0) and (Index < FLineNumbers.Count);
    if Result then begin
      S := FLineNumbers[Index];
      { Extract the start address of the line number. The source address must
        be greater than or equal to this address }
      S2 := Copy(S,1,8);
      Result := (S1 >= S2);
      if Result then begin
        { Extract the unit index }
        UnitIndex := StrToInt(Copy(S,9,4));
        Result := (UnitIndex >= 0) and (UnitIndex < FUnits.Count);
        if Result then begin
          { Lookup the unit name }
          UnitName := FUnits[UnitIndex];
          I := Pos(':',UnitName);
          if I > 0 then begin
            { Extract start address and length of unit segment and check if
              address falls inside this range }
            Start := StrToInt('$' + Copy(UnitName,I + 1,8));
            Length := StrToInt('$' + Copy(UnitName,I + 9,8));
            Result := (Address >= Start) and (Address < Start + Length);
            if Result then begin
              UnitName := Copy(UnitName,1,I - 1);
              LineNr := StrToInt(Copy(S,13,MaxInt)) - 1;
            end;
          end;
        end;
      end;
    end;
  end;

begin
  UnitName := ''; LineNr := 0;
  S1 := Format('%.8x',[Address]);
  FLineNumbers.Find(S1,Index);
  Result := CheckAddress(Index) or CheckAddress(Index - 1);
end;

function TMapParser.FindSection(const Section: String): Boolean;
{ Reads the map file until section Section is found }
begin
  Result := True;
  while ReadLine do
    if Pos(Section,FLine) <> 0 then
      Exit;
  Result := False;
end;

function TMapParser.FindSymbol(const Address: Longword;
  out Symbol: String): Boolean;
var
  S1: String;
  Index: Integer;

  function CheckAddress(const Index: Integer): Boolean;
  var
    S2: String;
  begin
    Result := (Index >= 0) and (Index < FPublicsByValue.Count);
    if Result then begin
      { Lookup the symbol and check its address }
      S2 := Copy(FPublicsByValue[Index],1,8);
      Result := (S1 >= S2);
      if Result then
        Symbol := Copy(FPublicsByValue[Index],9,MaxInt);
    end;
  end;

begin
  Symbol := '';
  S1 := Format('%.8x',[Address]);
  FPublicsByValue.Find(S1,Index);
  Result := CheckAddress(Index) or CheckAddress(Index - 1);
end;

procedure TMapParser.InvalidMapFile;
begin
  raise EMapParserError.CreateFmt('Invalid map file "%s" at line %d',
    [FMapFilename,FLineNr]);
end;

procedure TMapParser.Parse;
begin
  AssignFile(FMapFile,FMapFilename);
  Reset(FMapFile);
  try
    ParseMapOfSegments;
    ParsePublicsByValue;
    ParseLineNumbers;
  finally
    CloseFile(FMapFile);
  end;
end;

procedure TMapParser.ParseLineNumbers;
var
  UnitName, UnitIndex, LineNr, Address: String;
  I: Integer;
begin
  { There are one or more line number sections in the map file, in the
    following format:

    Line numbers for Forms(Forms.pas) segment .text

      1336 0001:00045894  1337 0001:00045899  1341 0001:0004589C  1342 0001:000458A1
      1353 0001:000458A4  1354 0001:000458AA  1356 0001:000458AE  1357 0001:000458B6

    After the header ("Line numbers for...") are some lines with up to four
    entries per line, each in the following format:
      1336 0001:00045894
    1336: The line number
    0001: A four digit segment index (always 0001 for code segments)
    00045894: The address of the line numer within the segment }
  while Copy(FLine,1,16) = 'Line numbers for' do begin
    // Extract unit name and locate it in the FUnits stringlist
    I := Pos('(',FLine);
    if I = 0 then
      InvalidMapFile;
    UnitName := Copy(FLine,18,I - 18);
    FUnits.Find(UnitName,I);
    if (I >= FUnits.Count)
      or (not SameText(UnitName,Copy(FUnits[I],1,Length(UnitName)))) then begin
      Dec(I);
      if not SameText(UnitName,Copy(FUnits[I],1,Length(UnitName))) then
        InvalidMapFile;
    end;
    UnitIndex := Format('%.4d',[I]);

    while ReadLine do begin
      if not (FLine[1] in ['0'..'9']) then
        Break;
      // Parse up to four line number entries per line
      while FLine <> '' do begin
        I := Pos(' ',FLine);
        if I = 0 then
          InvalidMapFile;
        if Copy(FLine,I,6) = ' 0001:' then begin
          LineNr := Copy(FLine,1,I - 1);
          Address := Copy(FLine,I + 6,8);
          { Add the line number entry to the FLineNumbers stringlist in the
            following format:
             xxxxxxxxyyyyzzz
            xxxxxxxx: The address (always 8 digits)
            yyyy: The index of the unit in the FUnits stringlist (4 digits)
            zzz: the line number (variable number of digits)
            This way, the TStringList.Find method can perform a fast binary
            search on the address. }
          FLineNumbers.Add(Address + UnitIndex + LineNr)
        end;
        FLine := Trim(Copy(FLine,I + 14,MaxInt));
      end;
    end;
  end;
end;

procedure TMapParser.ParseMapOfSegments;
var
  Start, Length, UnitName: String;
  I: Integer;
begin
  if not FindSection('Detailed map of segments') then
    InvalidMapFile;
  { Each line in this section has the following format:
     0001:00010934 0000978A C=CODE     S=.text    G=(none)   M=Classes  ACBP=A9
    0001: A four digit segment index (always 0001 for code segments)
    00010934: Start address of the segment
    0000978A: Length of segment
    C=CODE: Segment class (CODE, DATA or BSS)
    S=.text: Name of segment (usually .text, .data or .bss)
    G=(none): Group to which segment belongs (usually (none) for code segments)
    M=Classes: Name of the unit
    ACBP=A9: Alignment Combination Big inPage (always A9) }

  while ReadLine do begin
    if Copy(FLine,1,5) <> '0001:' then
      Break;
    Start := Copy(FLine,6,8);
    Length := Copy(FLine,15,8);
    I := Pos('M=',FLine);
    if I = 0 then
      InvalidMapFile;
    Delete(FLine,1,I + 1);
    I := Pos(' ',FLine);
    if I = 0 then
      InvalidMapFile;
    UnitName := Copy(FLine,1,I - 1);
    { Add unit to the FUnits stringlist in the following format:
       nnnn:ssssssssllllllll
      nnnn: Name of the unit
      ssssssss: Start address
      llllllll: Length }
    FUnits.Add(UnitName + ':' + Start + Length)
  end;
end;

procedure TMapParser.ParsePublicsByValue;
begin
  if not FindSection('Publics by Value') then
    InvalidMapFile;

  { Each line in this section has the following format:
     0001:00034564       TControlCanvas.Destroy
    0001: A four digit segment index (always 0001 for code segments)
    00034564: The address of the symbol within the segment
    TControlCanvas.Destroy: Name of the symbol }

  while ReadLine do begin
    if (Length(FLine) < 21) or (FLine[5] <> ':') then
      Break;
    if Copy(FLine,1,4) = '0001' then begin
      { Add symbol to the FPublicsByValue stringlist in the following format:
        00034564TControlCanvas.Destroy
        The first 8 characters are the address, followed by the symbol name.
        This way, the TStringList.Find method can perform a fast binary
        search on the address. }
      FLine := Copy(FLine,6,8) + Copy(FLine,21,MaxInt);
      FPublicsByValue.Add(FLine);
    end;
  end;
end;

function TMapParser.ReadLine: Boolean;
begin
  repeat
    Result := not Eof(FMapFile);
    if Result then begin
      ReadLn(FMapFile,FLine);
      FLine := Trim(FLine);
      Inc(FLineNr);
    end;
  until (not Result) or (FLine <> '');
end;

end.
