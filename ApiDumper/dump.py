# Content properties mirroring a string property which doesn't share their name
CONTENT_ALIASES = {
    "AudioContent": {"SoundId", "Asset"},
}

BLOCKED_TAGS = {"Deprecated", "ReadOnly", "Hidden", "NotScriptable"}

# capabilities never granted to game scripts
BLOCKED_CAPABILITIES = {"PluginOrOpenCloud", "InternalTest"}

def is_content_mirror(name: str, members: list[str]) -> bool:
    """Check if a Content property has a string counterpart in the same class, ex: ImageContent => Image"""
    if not name.endswith("Content"):
        return False
    base = name.removesuffix("Content")
    counterparts = {base, base + "Id", base + "ID"} | CONTENT_ALIASES.get(name, set())
    return not counterparts.isdisjoint(members)

def SanitizeDump(dump_json: dict) -> dict[str, dict]:
    sanitized: dict[str, dict] = {}

    for class_obj in dump_json.get("Classes", []):
        class_tags = set(class_obj.get("Tags", []))
        members: list[str] = []

        # deprecated classes are kept without members to not break the superclass chain
        for member in [] if "Deprecated" in class_tags else class_obj.get("Members", []):
            if member.get("MemberType") != "Property":
                continue

            member_name = member.get("Name", "")
            member_tags = set(member.get("Tags", []))
            if member_tags & BLOCKED_TAGS:
                continue

            security = member.get("Security", {})
            if security.get("Write", "None") != "None" or security.get("Read", "None") != "None":
                continue

            capabilities = member.get("Capabilities", {})
            if isinstance(capabilities, dict) and BLOCKED_CAPABILITIES & set(capabilities.get("Write", [])):
                continue

            members.append(member_name)

        members = [name for name in members if not is_content_mirror(name, members)]

        sanitized[class_obj["Name"]] = {
            "Superclass": class_obj.get("Superclass"),
            "Members": members,
        }

    return sanitized
