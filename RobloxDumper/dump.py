def SanitizeDump(DumpJSON:dict) -> dict[str, list[str]]:
    """Parse the json and remove all useless data such ReadOnly properties and more.."""

    JSON : dict[str, list] = {}
    
    for ClassObj in DumpJSON['Classes']: # loop trought the dump and save important instances
        # continue cases
        
        Members : list[str] = []
        for Member in ClassObj['Members']:
            
            if 'Tags' in ClassObj:
                if "Deprecated" in ClassObj['Tags'] or "ReadOnly" in ClassObj['Tags']:
                    continue
                
            if Member["MemberType"] != "Property":
                continue
            
            # Using .Capitalize() to makes only the first letter of the name capital
            # 'canvasSize' => 'Canvassize' but we need 'CanvasSize'       
            CapitalizedName = Member["Name"][0].upper() + Member["Name"][1:]
            Members.append(CapitalizedName)
        
        JSON[ClassObj['Name']] = {
            'Superclass': ClassObj['Superclass'],
            'Members': Members
        }

    return JSON
    