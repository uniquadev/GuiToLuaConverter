def SanitizeDump(DumpJSON:dict) -> str:
    """Parse the json and remove all useless data such ReadOnly properties and more.."""

    properties = []
    
    for i in range(len(DumpJSON["Classes"])):
        for j in DumpJSON["Classes"][i]["Members"]:
            if j["MemberType"] != "Property":
                continue
                
            if "Tags" in j:
                if "ReadOnly" in j["Tags"] or "Deprecated" in j["Tags"]:
                    continue    
            properties.append(j["Name"].capitalize()) 

    return properties
    