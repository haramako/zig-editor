# Zig Editor

Zigで開発中のテキストエディタ

## プロジェクト概要

- **言語**: Zig
- **目的**: ターミナルベースのテキストエディタ
- **対応プラットフォーム**: Windows / POSIX

## ディレクトリ構造

```
zig-editor/
├── build.zig              # ビルド設定（3モジュール定義）
├── memo.md                # 開発メモ・TODO
├── corelib/               # コアユーティリティライブラリ
│   ├── root.zig           # モジュールエントリ
│   ├── arrays.zig         # Array2D - 2D配列（フレームバッファ用）
│   ├── deque.zig          # Deque - リングバッファベースの双方向キュー
│   └── log.zig            # ログシステム（zig_editor.log出力）
├── screen/                # ターミナル描画ライブラリ
│   ├── root.zig           # モジュールエントリ
│   ├── screen.zig         # Windows Console API / POSIX termios
│   ├── vt100.zig          # VT100エスケープシーケンス
│   └── key_sequence_processor.zig  # キー入力パーサー（状態機械）
└── src/                   # エディタアプリケーション
    ├── root.zig           # モジュールエントリ
    ├── main.zig           # エントリーポイント
    ├── app.zig            # App構造体（アプリ状態管理）
    ├── buffer.zig         # ギャップバッファ実装
    ├── bufutil.zig        # バッファユーティリティ関数
    ├── text_frame.zig     # TextFrame（ビューポート管理）
    ├── keybinding.zig     # KeyBinding（キーバインド解析）
    ├── mainloop.zig       # メインループ・画面更新
    └── basic_commands.zig # コマンド実装
```

## モジュール依存関係

```
corelib（依存なし）
    ↓
screen → corelib
    ↓
src (zig_editor) → corelib, screen
```

## アーキテクチャ

### データフロー

```
User Input → stdin → KeySequenceProcessor → Key
    → KeyBinding照合 → Command実行
    → Buffer/TextFrame更新
    → redraw() → refresh() → Terminal
```

### 主要コンポーネント

| コンポーネント | 責務 |
|--------------|------|
| **Buffer** | ギャップバッファによるテキスト格納 |
| **TextFrame** | ビューポート管理、デュアルカーソル（screen/user） |
| **App** | アプリ状態、コマンドレジストリ、フレームバッファ |
| **KeySequenceProcessor** | VT100エスケープシーケンス解析 |
| **KeyBinding** | キーシーケンス→コマンドのマッピング |

### デザインパターン

- **ギャップバッファ**: 編集位置に空隙を移動させる効率的なテキスト構造
- **デュアルカーソル**: screen_cursor（ビューポート開始）とuser_cursor（編集位置）
- **コマンドパターン**: `CommandFunc = *const fn (ctx: Ctx) anyerror!void`
- **状態機械**: キー入力解析（Normal → Escape → Escape2 → Escape3）

## ビルド・実行

```bash
# ビルド
zig build

# 実行
zig build run

# テスト
zig build test

# VT100テストモード
zig build run -- --vt100
```

## 実装済み機能

- 基本編集（挿入、削除、バックスペース、改行）
- カーソル移動（上下左右、Home、End）
- 行削除（C-k）
- スクロール
- キーバインド処理
- ログ出力

## 未実装・TODO（memo.md参照）

- ファイル保存・読み込み
- コピー＆ペースト
- Undo/Redo
- PageUp/PageDown
- 拡張子によるモード変更
- シンタックスハイライト

## コーディング規約

- Zigの標準スタイルに従う
- エラーは`anyerror`で伝播、適切な箇所でハンドリング
- モジュール公開は`root.zig`経由で再エクスポート
- コマンド関数は`do_`プレフィックス（例: `do_up`, `do_save`）

## キーバインド形式

```
"C-x"     → Ctrl+x
"M-x"     → Alt+x
"C-x C-s" → Ctrl+x followed by Ctrl+s（コードシーケンス）
"Up"      → 上矢印キー
```
