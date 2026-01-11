

* 上下左右,Enter,DEL,BS,HOME,END
* Buffer
* Buffer.modify
* lineFromBuffer

## 全体の流れ

Buffer -> LineBuffer（１行ごと、文字の数、色などを判別） -> FrameBuffer（１画面）


fn lineFromBuffer(out: []Character, buf: Buffer, start: int, end: int) ![]Character
fn screen


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

## Buffer

ファイルに対応する

gap buffer構造

buf: []u8
gap_start: usize
gap_end: usize
cursors: []*Cursor

fn createCursor() !*Cursor
//  文字列の削除、追加を行う
fn modify(pos: usize, remove: int, insert: []u8) !BufferCommand
fn insertString(pos: usize, str: []u8)
fn removeString(pos: usize, n: usize)

BufferCommand 文字の挿入などのコマンド

## Cursor

buf: *Buffer
pos: usize

fn next(n:int)
fn prev(n:int)
fn row() int
fn col() int

## Command

コマンド