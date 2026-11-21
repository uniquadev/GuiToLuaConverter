CONTENT_MIRROR_PROPERTIES = {
    "ImageContent",
    "HoverImageContent",
    "PressedImageContent",
    "TopImageContent",
    "MidImageContent",
    "BottomImageContent",
    "VideoContent",
    "CursorIconContent",
    "ActivatedCursorIconContent",
    "FallbackImageContent",
}

BLOCKED_TAGS = {"Deprecated", "ReadOnly", "Hidden", "NotScriptable"}

def SanitizeDump(dump_json: dict) -> dict[str, dict]:
    sanitized: dict[str, dict] = {}

    for class_obj in dump_json.get("Classes", []):
        class_tags = set(class_obj.get("Tags", []))
        if "Deprecated" in class_tags:
            continue

        members: list[str] = []
        for member in class_obj.get("Members", []):
            if member.get("MemberType") != "Property":
                continue

            member_name = member.get("Name", "")
            if member_name in CONTENT_MIRROR_PROPERTIES:
                continue

            member_tags = set(member.get("Tags", []))
            if member_tags & BLOCKED_TAGS:
                continue

            security = member.get("Security", {})
            if security.get("Write", "None") != "None" or security.get("Read", "None") != "None":
                continue

            members.append(member_name)

        sanitized[class_obj["Name"]] = {
            "Superclass": class_obj.get("Superclass"),
            "Members": members,
        }

    return sanitized
