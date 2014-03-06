module dlangui.widgets.styles;

import dlangui.core.types;
import dlangui.graphics.fonts;

immutable ubyte ALIGN_UNSPECIFIED = 0;
immutable uint COLOR_UNSPECIFIED = 0xFFDEADFF;
immutable uint COLOR_TRANSPARENT = 0xFFFFFFFF;
immutable ushort FONT_SIZE_UNSPECIFIED = 0xFFFF;
immutable ushort FONT_WEIGHT_UNSPECIFIED = 0x0000;
immutable ubyte FONT_STYLE_UNSPECIFIED = 0xFF;
immutable ubyte FONT_STYLE_NORMAL = 0x00;
immutable ubyte FONT_STYLE_ITALIC = 0x01;

enum Align : ubyte {
    Unspecified = ALIGN_UNSPECIFIED,
    Left = 1,
    Right = 2,
    HCenter = Left | Right,
    Top = 4,
    Bottom = 8,
    VCenter = Top | Bottom,
    Center = VCenter | HCenter,
	TopLeft = Left | Top,
}

/// style properties
class Style {
	protected string _id;
	protected Theme _theme;
	protected Style _parentStyle;
	protected string _parentId;
	protected ubyte _stateMask;
	protected ubyte _stateValue;
	protected ubyte _align = Align.TopLeft;
	protected uint _backgroundColor = COLOR_TRANSPARENT;
	protected uint _textColor = COLOR_UNSPECIFIED;
	protected ushort _fontSize = FONT_SIZE_UNSPECIFIED;
	protected ushort _fontWeight = FONT_WEIGHT_UNSPECIFIED;
	protected ubyte _fontStyle = FONT_STYLE_UNSPECIFIED;
	protected string _fontFace;
	protected FontFamily _fontFamily = FontFamily.Unspecified;
	protected Rect _padding;
	protected Rect _margins;

	protected Style[] _substates;
	protected Style[] _children;

	protected FontRef _font;

	@property const(Theme) theme() {
		if (_theme !is null)
			return _theme;
		return currentTheme;
	}

	@property string id() { return _id; }

	@property Style parentStyle() {
		if (_parentStyle !is null)
			return _parentStyle;
		if (_parentId !is null && currentTheme !is null)
			return currentTheme.get(_parentId);
		return null;
	}

	@property ref FontRef font() {
		if (!_font.isNull)
			return _font;
		string face = fontFace();
		int size = fontSize();
		ushort weight = fontWeight();
		bool italic = fontItalic();
		FontFamily family = fontFamily();
		_font = FontManager.instance.getFont(size, weight, italic, family, face);
		return _font;
	}

	/// font size
	@property FontFamily fontFamily() {
		Style p = this;
		while(p !is null) {
			if (p._fontFamily != FontFamily.Unspecified)
				return p._fontFamily;
			p = p.parentStyle;
		}
		return theme._fontFamily;
	}
	/// font size
	@property string fontFace() {
		Style p = this;
		while(p !is null) {
			if (p._fontFace !is null)
				return p._fontFace;
			p = p.parentStyle;
		}
		return theme._fontFace;
	}
	/// font style - italic
	@property bool fontItalic() {
		Style p = this;
		while(p !is null) {
			if (p._fontStyle != FONT_STYLE_UNSPECIFIED)
				return p._fontStyle == FONT_STYLE_ITALIC;
			p = p.parentStyle;
		}
		return theme._fontStyle == FONT_STYLE_ITALIC;
	}
	/// font weight
	@property ushort fontWeight() {
		Style p = this;
		while(p !is null) {
			if (p._fontWeight != FONT_WEIGHT_UNSPECIFIED)
				return p._fontWeight;
			p = p.parentStyle;
		}
		return theme._fontWeight;
	}
	/// font size
	@property ushort fontSize() {
		Style p = this;
		while(p !is null) {
			if (p._fontSize != FONT_SIZE_UNSPECIFIED)
				return p._fontSize;
			p = p.parentStyle;
		}
		return theme._fontSize;
	}
	/// padding
	@property ref const(Rect) padding() {
		if (_stateValue != 0)
			return parentStyle._padding;
		return _padding;
	}
	/// margins
	@property ref const(Rect) margins() {
		if (_stateValue != 0)
			return parentStyle._margins;
		return _margins;
	}
	/// text color
	@property uint textColor() {
		Style p = this;
		while(p !is null) {
			if (p._textColor != COLOR_UNSPECIFIED)
				return p._textColor;
			p = p.parentStyle;
		}
		return theme._textColor;
	}
	/// background color
	@property uint backgroundColor() {
		Style p = this;
		while(p !is null) {
			if (p._backgroundColor != COLOR_UNSPECIFIED)
				return p._backgroundColor;
			p = p.parentStyle;
		}
		return theme._textColor;
	}
	/// vertical alignment: Top / VCenter / Bottom
	@property ubyte valign() { return _align & Align.VCenter; }
	/// horizontal alignment: Left / HCenter / Right
	@property ubyte halign() { return _align & Align.HCenter; }

	@property Style fontFace(string face) {
		_fontFace = face;
		_font.clear();
		return this;
	}

	@property Style fontStyle(ubyte style) {
		_fontStyle = style;
		_font.clear();
		return this;
	}

	@property Style fontWeight(ushort weight) {
		_fontWeight = weight;
		_font.clear();
		return this;
	}

	@property Style fontSize(ushort size) {
		_fontSize = size;
		_font.clear();
		return this;
	}

	@property Style textColor(uint color) {
		_textColor = color;
		return this;
	}

	@property Style backgroundColor(uint color) {
		_backgroundColor = color;
		return this;
	}

	@property Style margins(Rect rc) {
		_margins = rc;
		return this;
	}

	@property Style padding(Rect rc) {
		_padding = rc;
		return this;
	}

	this(Theme theme, string id) {
		_theme = theme;
		_parentStyle = theme;
		_id = id;
	}

	/// create named substyle of this style
	Style createSubstyle(string id) {
		Style child = (_theme !is null ? _theme : currentTheme).createSubstyle(id);
		child._parentStyle = this;
		_children ~= child;
		return child;
	}

	/// create state substyle for this style
	Style createState(ubyte stateMask = 0, ubyte stateValue = 0) {
		Style child = createSubstyle(id);
		child._stateMask = stateMask;
		child._stateValue = stateValue;
		child._backgroundColor = COLOR_UNSPECIFIED;
		_substates ~= child;
		return child;
	}

	/// find substyle based on widget state (e.g. focused, pressed, ...)
	Style forState(ubyte state) {
		if (state == 0)
			return this;
		if (id is null && parentStyle !is null && _substates.length == 0)
			return parentStyle.forState(state);
		foreach(item; _substates) {
			if ((item._stateMask & state) == item._stateValue)
				return item;
		}
		return this; // fallback to current style
	}
}

class Theme : Style {
	protected Style[string] _byId;

	this(string id) {
		super(this, id);
		_parentStyle = null;
		_backgroundColor = 0xE0E0E0; // light gray
		_textColor = 0x000000; // black
		_align = Align.TopLeft;
		_fontSize = 24; // TODO: from settings or screen properties / DPI
		_fontStyle = FONT_STYLE_NORMAL;
		_fontWeight = 400;
		_fontFace = "Arial"; // TODO: from settings
	}

	/// create wrapper style which will have currentTheme.get(id) as parent instead of fixed parent - to modify some base style properties in widget
	Style modifyStyle(string id) {
		Style style = new Style(null, null);
		style._parentId = id;
		return style;
	}

	/// create new named style
	override Style createSubstyle(string id) {
		Style style = new Style(this, id);
		if (id !is null)
			_byId[id] = style;
		return style;
	}

	/// find style by id, returns theme if not style with specified ID is not found
	@property Style get(string id) {
		if (id !is null && id in _byId)
			return _byId[id];
		return this;
	}
}

__gshared Theme currentTheme;

static this() {
	currentTheme = new Theme("default");
}