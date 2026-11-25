import json
import unittest
from pathlib import Path
from ApiDumper.dump import SanitizeDump, is_content_mirror
from ApiDumper.api_v2 import RobloxStudioApi

ROOT_DIR = Path(__file__).parent.parent
DUMP_PATH = ROOT_DIR / "PluginPlace" / "src" / "assets" / "dump.json"

class TestGuiToLuaModernApi(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with open(DUMP_PATH, "r", encoding="utf-8") as f:
            cls.dump = json.load(f)

    def test_dump_not_empty(self):
        self.assertGreater(len(self.dump), 800)

    def test_modern_ui_classes_present(self):
        modern_classes = [
            "CanvasGroup",
            "Path2D",
            "UIFlexItem",
            "UIDragDetector",
            "UIListLayout",
            "UIStroke",
            "UICorner",
            "UIGradient",
            "UIPadding",
            "UIScale",
            "UIAspectRatioConstraint",
            "UISizeConstraint",
            "UITextSizeConstraint",
            "ScreenGui",
            "BillboardGui",
            "SurfaceGui",
            "Frame",
            "ScrollingFrame",
            "TextLabel",
            "TextButton",
            "TextBox",
            "ImageLabel",
            "ImageButton",
            "VideoFrame",
            "ViewportFrame",
        ]
        for cls_name in modern_classes:
            self.assertIn(cls_name, self.dump, f"Missing modern class: {cls_name}")

    def test_uiflexitem_properties(self):
        item = self.dump.get("UIFlexItem", {})
        members = set(item.get("Members", []))
        expected = {"FlexMode", "GrowRatio", "ItemLineAlignment", "ShrinkRatio"}
        self.assertTrue(expected.issubset(members), f"UIFlexItem missing: {expected - members}")

    def test_uilistlayout_flex_properties(self):
        item = self.dump.get("UIListLayout", {})
        members = set(item.get("Members", []))
        expected = {"HorizontalFlex", "VerticalFlex", "ItemLineAlignment", "Wraps"}
        self.assertTrue(expected.issubset(members), f"UIListLayout missing: {expected - members}")

    def test_guiobject_modern_properties(self):
        item = self.dump.get("GuiObject", {})
        members = set(item.get("Members", []))
        expected = {"Interactable", "AnchorPoint", "AutomaticSize", "BackgroundColor3", "Size", "Position"}
        self.assertTrue(expected.issubset(members), f"GuiObject missing: {expected - members}")

    def test_screengui_modern_properties(self):
        item = self.dump.get("ScreenGui", {})
        members = set(item.get("Members", []))
        expected = {"ScreenInsets", "SafeAreaCompatibility", "ClipToDeviceSafeArea"}
        self.assertTrue(expected.issubset(members), f"ScreenGui missing: {expected - members}")

    def test_canvasgroup_properties(self):
        item = self.dump.get("CanvasGroup", {})
        members = set(item.get("Members", []))
        expected = {"GroupColor3", "GroupTransparency"}
        self.assertTrue(expected.issubset(members), f"CanvasGroup missing: {expected - members}")

    def test_path2d_properties(self):
        item = self.dump.get("Path2D", {})
        members = set(item.get("Members", []))
        expected = {"Closed", "Color3", "Thickness", "Visible", "ZIndex"}
        self.assertTrue(expected.issubset(members), f"Path2D missing: {expected - members}")

    def test_uidragdetector_properties(self):
        item = self.dump.get("UIDragDetector", {})
        members = set(item.get("Members", []))
        expected = {"DragStyle", "DragAxis", "ResponseStyle", "Enabled"}
        self.assertTrue(expected.issubset(members), f"UIDragDetector missing: {expected - members}")

    def test_no_content_mirror_properties(self):
        for cls_name, cls_data in self.dump.items():
            members = cls_data["Members"]
            mirrors = [name for name in members if is_content_mirror(name, members)]
            self.assertEqual(mirrors, [], f"Class {cls_name} contains unneeded content mirrors: {mirrors}")

    def test_content_without_counterpart_is_kept(self):
        self.assertIn("VideoContent", self.dump["VideoPlayer"]["Members"])

    def test_plugin_only_properties_are_filtered(self):
        self.assertNotIn("InputSinkEnabled", self.dump["LayerCollector"]["Members"])
        self.assertNotIn("RunContext", self.dump["BaseScript"]["Members"])

    def test_superclass_chain_is_complete(self):
        for cls_name, cls_data in self.dump.items():
            superclass = cls_data["Superclass"]
            if superclass != "<<<ROOT>>>":
                self.assertIn(superclass, self.dump, f"{cls_name} has an unknown superclass")

    def test_api_v2_fetch(self):
        api = RobloxStudioApi()
        raw_dump = api.DumpJSON()
        self.assertIn("Classes", raw_dump)
        self.assertGreater(len(raw_dump["Classes"]), 800)

if __name__ == "__main__":
    unittest.main()
