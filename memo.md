

* logging
* KeyBindingの処理
* Commandを整備する
* Cursorを実装
* スクロール
- Buffer
- Buffer.modify
- lineFromBuffer
- 上下左右,Enter,DEL,BS

* Home
* End
* C-K
* Copy
* Cut
* Paste
* Save
* Load
* Quit
* Ctrl+L
* PageUp
* PageDown


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