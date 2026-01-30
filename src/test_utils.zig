const std = @import("std");
const mem = std.mem;
const json = std.json;

const App = @import("app.zig");
const TextFrame = @import("text_frame.zig");
const screen = @import("screen");
const mainloop = @import("mainloop.zig");

const CharacterArray2D = TextFrame.CPDArray2D;
const Character = screen.CPD;

// ============================================================
// JSON出力用の構造体
// ============================================================

pub const CursorState = struct {
    pos: usize,
    line: usize,
    col: usize,
};

pub const CursorPair = struct {
    user: CursorState,
    screen: CursorState,
};

pub const Viewport = struct {
    width: usize,
    height: usize,
};

pub const BufferState = struct {
    length: usize,
    content: []const u8,
};

pub const EditorState = struct {
    viewport: Viewport,
    cursor: CursorPair,
    buffer: BufferState,
    frame_buffer: []const []const u8,

    pub fn deinit(self: *EditorState, allocator: mem.Allocator) void {
        allocator.free(self.buffer.content);
        for (self.frame_buffer) |line| {
            allocator.free(line);
        }
        allocator.free(self.frame_buffer);
    }
};

// ============================================================
// TestApp
// ============================================================

/// テスト用Appラッパー
/// 本番のI/Oを必要とせず、固定サイズのフレームバッファでテスト可能
pub const TestApp = struct {
    app: App,
    allocator: mem.Allocator,

    /// テスト用の初期化（I/Oなし、固定サイズのフレームバッファ）
    pub fn init(allocator: mem.Allocator, width: usize, height: usize, source: []const u8) !TestApp {
        var buf: CharacterArray2D = try .init(allocator, width, height);
        buf.fill(Character{ .chr = ' ', .attr = 0, .color = 0 });

        const commands = try std.ArrayList(App.KeyBindingCommand).initCapacity(allocator, 100);

        const current_frame = try allocator.create(TextFrame);
        current_frame.* = try TextFrame.init(allocator, source);

        return TestApp{
            .allocator = allocator,
            .app = App{
                .io = undefined,
                .gpa = allocator,
                .fb = buf,
                .stdout_buffer = &[_]u8{},
                .stdout_file_writer = undefined,
                .stdin_buffer = &[_]u8{},
                .stdin_file_reader = undefined,
                .commands = commands,
                .current_frame = current_frame,
            },
        };
    }

    pub fn deinit(self: *TestApp) void {
        self.app.fb.deinit();
        self.app.commands.deinit(self.allocator);
        self.app.current_frame.deinit();
        self.allocator.destroy(self.app.current_frame);
    }

    /// フレームバッファを再描画
    pub fn redraw(self: *TestApp) !void {
        try mainloop.redraw(&self.app);
    }

    /// 内部のAppへのアクセス
    pub fn getApp(self: *TestApp) *App {
        return &self.app;
    }

    /// TextFrameへのアクセス
    pub fn frame(self: *TestApp) *TextFrame {
        return self.app.current_frame;
    }

    // ============================================================
    // 状態取得
    // ============================================================

    /// エディタの状態を構造体として取得
    pub fn getState(self: *const TestApp) !EditorState {
        const fb = &self.app.fb;
        const text_frame = self.app.current_frame;
        const user_cur = text_frame.user_cursor();
        const screen_cur = text_frame.screen_cursor();

        // バッファ内容を取得
        const buf_len = text_frame.buf.len();
        const content = try self.allocator.alloc(u8, buf_len);
        errdefer self.allocator.free(content);
        for (0..buf_len) |i| {
            content[i] = text_frame.buf.get(i) orelse ' ';
        }

        // フレームバッファの各行を取得
        var lines = try self.allocator.alloc([]const u8, fb.height);
        errdefer {
            for (lines) |line| {
                self.allocator.free(line);
            }
            self.allocator.free(lines);
        }

        for (0..fb.height) |y| {
            // 行の末尾の空白を除去
            var last_non_space: usize = 0;
            for (0..fb.width) |x| {
                if (fb.get(x, y)) |cpd| {
                    if (cpd.chr != ' ') {
                        last_non_space = x + 1;
                    }
                }
            }

            const line = try self.allocator.alloc(u8, last_non_space);
            for (0..last_non_space) |x| {
                line[x] = if (fb.get(x, y)) |cpd| cpd.chr else ' ';
            }
            lines[y] = line;
        }

        return EditorState{
            .viewport = .{
                .width = fb.width,
                .height = fb.height,
            },
            .cursor = .{
                .user = .{
                    .pos = user_cur.pos,
                    .line = user_cur.line,
                    .col = user_cur.column,
                },
                .screen = .{
                    .pos = screen_cur.pos,
                    .line = screen_cur.line,
                    .col = screen_cur.column,
                },
            },
            .buffer = .{
                .length = buf_len,
                .content = content,
            },
            .frame_buffer = lines,
        };
    }

    /// エディタの状態をJSON文字列として取得
    pub fn dumpJson(self: *const TestApp) ![]u8 {
        var state = try self.getState();
        defer state.deinit(self.allocator);

        return json.Stringify.valueAlloc(self.allocator, state, .{ .whitespace = .indent_2 });
    }

    // ============================================================
    // 便利メソッド
    // ============================================================

    /// ユーザーカーソルの状態を取得
    pub fn getUserCursor(self: *const TestApp) CursorState {
        const cur = self.app.current_frame.user_cursor();
        return .{
            .pos = cur.pos,
            .line = cur.line,
            .col = cur.column,
        };
    }

    /// スクリーンカーソルの状態を取得
    pub fn getScreenCursor(self: *const TestApp) CursorState {
        const cur = self.app.current_frame.screen_cursor();
        return .{
            .pos = cur.pos,
            .line = cur.line,
            .col = cur.column,
        };
    }

    /// フレームバッファの指定行を取得（末尾空白除去）
    pub fn getFrameBufferLine(self: *const TestApp, line_num: usize) ![]u8 {
        const fb = &self.app.fb;
        if (line_num >= fb.height) return error.OutOfBounds;

        var last_non_space: usize = 0;
        for (0..fb.width) |x| {
            if (fb.get(x, line_num)) |cpd| {
                if (cpd.chr != ' ') {
                    last_non_space = x + 1;
                }
            }
        }

        const line = try self.allocator.alloc(u8, last_non_space);
        for (0..last_non_space) |x| {
            line[x] = if (fb.get(x, line_num)) |cpd| cpd.chr else ' ';
        }
        return line;
    }

    /// バッファの内容を文字列として取得
    pub fn getBufferContent(self: *const TestApp) ![]u8 {
        const text_frame = self.app.current_frame;
        const buf_len = text_frame.buf.len();
        const content = try self.allocator.alloc(u8, buf_len);
        for (0..buf_len) |i| {
            content[i] = text_frame.buf.get(i) orelse ' ';
        }
        return content;
    }
};

// ============================================================
// テスト
// ============================================================

test "getState basic" {
    const allocator = std.testing.allocator;
    var ta = try TestApp.init(allocator, 10, 3, "Hello\nWorld");
    defer ta.deinit();

    try ta.redraw();

    var state = try ta.getState();
    defer state.deinit(allocator);

    // ビューポート
    try std.testing.expectEqual(10, state.viewport.width);
    try std.testing.expectEqual(3, state.viewport.height);

    // カーソル初期位置
    try std.testing.expectEqual(0, state.cursor.user.pos);
    try std.testing.expectEqual(0, state.cursor.user.line);
    try std.testing.expectEqual(0, state.cursor.user.col);

    // バッファ内容
    try std.testing.expectEqualStrings("Hello\nWorld", state.buffer.content);

    // フレームバッファ
    try std.testing.expectEqualStrings("Hello", state.frame_buffer[0]);
    try std.testing.expectEqualStrings("World", state.frame_buffer[1]);
    try std.testing.expectEqualStrings("", state.frame_buffer[2]);
}

test "cursor position" {
    const allocator = std.testing.allocator;
    var ta = try TestApp.init(allocator, 10, 3, "Hello");
    defer ta.deinit();

    // カーソルを位置3に移動
    ta.frame().user_cursor().pos = 3;
    try ta.frame().updateCursor(ta.frame().user_cursor(), 3);

    try ta.redraw();

    const cursor = ta.getUserCursor();
    try std.testing.expectEqual(3, cursor.pos);
    try std.testing.expectEqual(0, cursor.line);
    try std.testing.expectEqual(3, cursor.col);
}

test "dumpJson" {
    const allocator = std.testing.allocator;
    var ta = try TestApp.init(allocator, 10, 3, "Test");
    defer ta.deinit();

    try ta.redraw();

    const json_str = try ta.dumpJson();
    defer allocator.free(json_str);

    // デバッグ用出力（通常は非表示）
    // std.debug.print("\n{s}\n", .{json_str});

    // JSONとしてパース可能か確認
    const parsed = try json.parseFromSlice(EditorState, allocator, json_str, .{});
    defer parsed.deinit();

    try std.testing.expectEqual(10, parsed.value.viewport.width);
    try std.testing.expectEqual(3, parsed.value.viewport.height);
}

test "getFrameBufferLine" {
    const allocator = std.testing.allocator;
    var ta = try TestApp.init(allocator, 10, 3, "Hello\nWorld");
    defer ta.deinit();

    try ta.redraw();

    const line0 = try ta.getFrameBufferLine(0);
    defer allocator.free(line0);
    try std.testing.expectEqualStrings("Hello", line0);

    const line1 = try ta.getFrameBufferLine(1);
    defer allocator.free(line1);
    try std.testing.expectEqualStrings("World", line1);
}
