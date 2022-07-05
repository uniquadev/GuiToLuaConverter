def SanitizeDump(DumpJSON:dict) -> dict[str, list[str]]:
    """Parse the json and remove all useless data such ReadOnly properties and more.."""

    JSON = {} # ClassName: {Superclass: ClassName1, Members: [Property1, Property2 ...]}
    
    for DumpObj in DumpJSON['Classes']: # loop trought the dump and save important instances
        # continue cases
        if 'Tags' in DumpObj and "Deprecated" in DumpObj['Tags']:
            continue
        # sanitized class obj
        Members : list[str] = []
        ClassObj = {
            'Superclass': DumpObj['Superclass'],
            'Members': Members
        }
        # load all members
        for Member in DumpObj['Members']:
            Members.append(Member['Name'])
        # store sanitized class obj
        JSON[DumpObj['Name']] = ClassObj

    return JSON
    