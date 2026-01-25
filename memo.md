

* スクロール
* Cursorを実装
* 色を付ける
* 拡張子によるモード変更
* コピー＆ペースト
* Undo/Redo
- Commandを整備する

* Copy
* Cut
* Paste
* Save
* Load
* Ctrl+L
* PageUp
* PageDown

- logging
- KeyBindingの処理
- Buffer
- Buffer.modify
- lineFromBuffer
- 上下左右,Enter,DEL,BS

- Home
- End
- C-K
- Quit

## モジュール構造

corelib
screen -> corelib
neki_core -> corelib, screen
    App
    Buffer
    TextFrame
neki_editor
neki_commands
    エディターコマンド
  


## 全体の流れ

Buffer -> LineBuffer（１行ごと、文字の数、色などを判別） -> FrameBuffer（１画面）

## Cursor

buf: *Buffer
pos: usize

fn next(n:int)
fn prev(n:int)
fn row() int
fn col() int

## Command

コマンド