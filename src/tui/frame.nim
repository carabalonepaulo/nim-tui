import std/terminal
import buffers


type
  Cell* = ref object
    background*: BackgroundColor
    foreground*: ForegroundColor
    `char`*: char

  Frame* = seq[seq[Cell]]


proc newFrame*(filePath: string): Frame =
  let reader = newBinaryReader(readFile(filePath))

  var width = reader.readU16().int
  var height = reader.readU16().int
  echo width, height

  result = newSeq[seq[Cell]](width)

  for x in 0..<width:
    result[x] = newSeq[Cell](height)
    for y in 0..<height:
      result[x][y] = Cell()
      result[x][y].background = BackgroundColor(reader.readU16())
      result[x][y].foreground = ForegroundColor(reader.readU16())
      result[x][y].`char` = reader.readU8().char


proc newFrame*(width, height: int, bgColor = bgBlack,
    fgColor = fgWhite, `char` = ' '): Frame =
  result = newSeq[seq[Cell]](width)

  for x in 0..<width:
    result[x] = newSeq[Cell](height)
    for y in 0..<height:
      result[x][y] = Cell(background: bgColor, foreground: fgColor,
          `char`: `char`)


proc width*(self: Frame): int = self.len


proc height*(self: Frame): int = self[0].len


iterator iter*(self: Frame, sx: int, sy: int, width: int,
    height: int): tuple[x, y: int] =
  for x in sx..<min(self.width - sx, width):
    for y in sy..<min(self.height - sy, height):
      yield (x, y)


iterator iter*(self: Frame, sx: int, sy: int): tuple[x, y: int] =
  for x in sx..<self.width:
    for y in sy..<self.height:
      yield (x, y)


iterator iter*(self: Frame): tuple[x, y: int] =
  for x in 0..<self.width:
    for y in 0..<self.height:
      yield(x, y)


proc drawChar*(self: Frame, x, y: int, `char`: char, fgColor: ForegroundColor) =
  self[x][y].`char` = `char`
  self[x][y].foreground = fgColor


proc drawFrame*(self: Frame, sx, sy: int, frame: Frame) =
  for x, y in self.iter(sx, sy, frame.width, frame.height):
    self[x][y].background = frame[x - sx][y - sy].background
    self[x][y].foreground = frame[x - sx][y - sy].foreground
    self[x][y].`char` = frame[x - sx][y - sy].`char`


proc drawFrame*(self: Frame, sx, sy: int, frame: Frame,
    bgColor: BackgroundColor, fgColor: ForegroundColor) =
  for x, y in self.iter(sx, sy, frame.width, frame.height):
    self[x][y].background = bgColor
    self[x][y].foreground = fgColor
    self[x][y].`char` = frame[x - sx][y - sy].`char`


proc drawLine*(self: Frame, `char`: char, sx, sy, ex, ey: int,
    color: ForegroundColor) =
  var
    x = sx
    y = sy

  while not (x == ex and y == ey):
    self[x][y].foreground = color
    self[x][y].`char` = `char`

    if ex > x:
      inc x
    elif x > ex:
      dec x

    if ey > y:
      inc y
    elif y > ey:
      dec y


proc drawRect*(self: Frame, sx, sy, width, height: int,
    color: BackgroundColor, onTop = true) =
  for x, y in self.iter(sx, sy, width, height):
    self[x][y].background = color
    if onTop:
      self[x][y].`char` = ' '


proc clear*(self: Frame, bgColor = bgBlack, fgColor = fgWhite, `char` = ' ') =
  for x, y in self.iter():
    self[x][y].background = bgColor
    self[x][y].foreground = fgWhite
    self[x][y].`char` = `char`


proc drawText*(self: Frame, text: string, x, y: int,
    fgColor: ForegroundColor) =
  var x = x
  for c in text.items():
    self[x][y].foreground = fgColor
    self[x][y].`char` = c
    inc x


proc save*(self: Frame, filePath: string) =
  let writer = newBinaryWriter()

  writer.write(self.width.uint16)
  writer.write(self.height.uint16)

  for x in 0..<self.width:
    for y in 0..<self.height:
      writer.write(self[x][y].background.uint16)
      writer.write(self[x][y].foreground.uint16)
      writer.write(self[x][y].`char`.uint8)

  writeFile(filePath, $writer)
