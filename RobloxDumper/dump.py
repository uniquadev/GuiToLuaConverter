def SanitizeDump(DumpJSON:dict) -> dict[str, list[str]]:
    """Parse the json and remove all useless data such ReadOnly properties and more.."""

    Properties : list[str] = []
    
    for DumpObj in DumpJSON['Classes']: # loop trought the dump and save important instances
        # continue cases
        
        for Member in DumpObj['Members']:
            
            if 'Tags' in DumpObj:
                if "Deprecated" in DumpObj['Tags'] or "ReadOnly" in DumpObj['Tags']:
                    continue
                
            if Member["MemberType"] != "Property":
                continue
            
            # Using .Capitalize() to makes only the first letter of the name capital
            # 'canvasSize' => 'Canvassize' but we need 'CanvasSize'       
            CapitalizedName = Member["Name"][0].upper() + Member["Name"][1:]
            Properties.append(CapitalizedName)

    return Properties
    