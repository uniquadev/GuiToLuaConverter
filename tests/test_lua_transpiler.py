import unittest

def prettify_number(n: float):
    if n != n:
        return "0/0"
    if n == float("inf"):
        return "math.huge"
    if n == float("-inf"):
        return "-math.huge"
    return round(n * 100000) / 100000

def encapsulate_string(s: str) -> str:
    level = ""
    while f"]{level}]" in s:
        level += "="
    return f"[{level}[{s}]{level}]"

class TestLuaTranspilerRules(unittest.TestCase):
    def test_prettify_numbers(self):
        self.assertEqual(prettify_number(1.2345678), 1.23457)
        self.assertEqual(prettify_number(float("inf")), "math.huge")
        self.assertEqual(prettify_number(float("-inf")), "-math.huge")
        self.assertEqual(prettify_number(float("nan")), "0/0")

    def test_encapsulate_string(self):
        self.assertEqual(encapsulate_string("hello"), "[[hello]]")
        self.assertEqual(encapsulate_string("a]b"), "[[a]b]]")
        self.assertEqual(encapsulate_string("a]]b"), "[=[a]]b]=]")
        self.assertEqual(encapsulate_string("a]=]b]]c"), "[==[a]=]b]]c]==]")

    def test_content_transpilation(self):
        def transpile_content(uri):
            if not uri:
                return "Content.none"
            return f"Content.fromUri({encapsulate_string(uri)})"

        self.assertEqual(transpile_content(""), "Content.none")
        self.assertEqual(transpile_content("rbxassetid://12345"), "Content.fromUri([[rbxassetid://12345]])")

    def test_path2d_control_point_transpilation(self):
        def transpile_point(pos, left, right):
            return f"Path2DControlPoint.new({pos}, {left}, {right})"

        point_lua = transpile_point("UDim2.new(0, 10, 0, 20)", "UDim2.new(0, -5, 0, 0)", "UDim2.new(0, 5, 0, 0)")
        self.assertEqual(
            point_lua,
            "Path2DControlPoint.new(UDim2.new(0, 10, 0, 20), UDim2.new(0, -5, 0, 0), UDim2.new(0, 5, 0, 0))"
        )

    def test_number_range_transpilation(self):
        def transpile_number_range(min_val, max_val):
            return f"NumberRange.new({prettify_number(min_val)}, {prettify_number(max_val)})"

        self.assertEqual(transpile_number_range(0.123456, 10.5), "NumberRange.new(0.12346, 10.5)")

    def test_brick_color_transpilation(self):
        def transpile_brick_color(name):
            return f"BrickColor.new({encapsulate_string(name)})"

        self.assertEqual(transpile_brick_color("Bright red"), "BrickColor.new([[Bright red]])")

    def test_axes_transpilation(self):
        def transpile_axes(x, y, z):
            args = []
            if x: args.append("Enum.Axis.X")
            if y: args.append("Enum.Axis.Y")
            if z: args.append("Enum.Axis.Z")
            return f"Axes.new({', '.join(args)})"

        self.assertEqual(transpile_axes(True, False, True), "Axes.new(Enum.Axis.X, Enum.Axis.Z)")

    def test_faces_transpilation(self):
        def transpile_faces(top=False, bottom=False, left=False, right=False, front=False, back=False):
            args = []
            if top: args.append("Enum.NormalId.Top")
            if bottom: args.append("Enum.NormalId.Bottom")
            if left: args.append("Enum.NormalId.Left")
            if right: args.append("Enum.NormalId.Right")
            if front: args.append("Enum.NormalId.Front")
            if back: args.append("Enum.NormalId.Back")
            return f"Faces.new({', '.join(args)})"

        self.assertEqual(transpile_faces(top=True, front=True), "Faces.new(Enum.NormalId.Top, Enum.NormalId.Front)")

if __name__ == "__main__":
    unittest.main()
