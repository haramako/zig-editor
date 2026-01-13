

* 上下左右,Enter,DEL,BS,HOME,END
* Commandを整備する
* Cursorを実装
- Buffer
- Buffer.modify
- lineFromBuffer

## 全体の流れ

Buffer -> LineBuffer（１行ごと、文字の数、色などを判別） -> FrameBuffer（１画面）

## FrameBuffer

画面の情報

chr: Array2D(Character)

Character = struct {
    c: u8       # Unicodeならu32?
    color: u8
    flag: Flag
}

## LineFrameBuffer

chr: []Character

## Cursor

buf: *Buffer
pos: usize

fn next(n:int)
fn prev(n:int)
fn row() int
fn col() int

## Command

コマンド