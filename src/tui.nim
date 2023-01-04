import std/terminal
import ./tui/frame

export frame


type
  Renderer* = ref object
    pos*: tuple[x, y: int]
    size*: tuple[x, y: int]
    backBuffer: Frame
    buffer: Frame


proc newRenderer*(x, y, width, height: int): Renderer =
  result = Renderer()
  result.pos = (x, y)
  result.size = (width, height)
  result.buffer = newFrame(width, height)
  result.backBuffer = newFrame(width, height)


# bug: when Y is too high, there is no space to draw, in this case
# is better to clear the screen and write at the top
proc newRenderer*(x, y: int): Renderer =
  result = Renderer()
  result.pos = (x, y)
  result.size = (terminalWidth() - x, terminalHeight() - y)
  result.buffer = newFrame(result.size.x, result.size.y)
  result.backBuffer = newFrame(result.size.x, result.size.y)


proc newRenderer*(): Renderer =
  newRenderer(0, 0, terminalWidth(), terminalHeight())


proc drawFrame*(self: Renderer, sx, sy: int, frame: Frame) =
  self.buffer.drawFrame(sx, sy, frame)


proc drawFrame*(self: Renderer, sx, sy: int, frame: Frame,
    bgColor: BackgroundColor, fgColor: ForegroundColor) =
  self.buffer.drawFrame(sx, sy, frame, bgColor, fgColor)


proc drawChar*(self: Renderer, x, y: int, `char`: char,
    fgColor: ForegroundColor) =
  self.buffer.drawChar(x, y, `char`, fgColor)


proc drawRect*(self: Renderer, sx, sy, width, height: int,
    color: BackgroundColor) =
  self.buffer.drawRect(sx, sy, width, height, color)


proc clear*(self: Renderer, color: BackgroundColor) =
  self.buffer.clear(color)


proc drawText*(self: Renderer, text: string, x, y: int,
    fgColor: ForegroundColor) =
  self.buffer.drawText(text, x, y, fgColor)


proc drawLine*(self: Renderer, `char`: char, sx, sy, ex, ey: int,
    color: ForegroundColor) =
  self.buffer.drawLine(`char`, sx, sy, ex, ey, color)


proc hasCellChanged(self: Renderer, a, b: Frame,
    x, y: int): bool =
  self.buffer[x][y].background != self.backBuffer[x][y].background or
      self.buffer[x][y].foreground != self.backBuffer[x][y].foreground or
      self.buffer[x][y].`char` != self.backBuffer[x][y].`char`


proc render*(self: Renderer) =
  for x, y in self.buffer.iter():
    if not self.hasCellChanged(self.buffer, self.backBuffer, x, y): continue

    self.backBuffer[x][y].background = self.buffer[x][y].background
    self.backBuffer[x][y].foreground = self.buffer[x][y].foreground
    self.backBuffer[x][y].`char` = self.buffer[x][y].`char`

    setCursorPos(self.pos.x + x, self.pos.y + y)
    setBackgroundColor(self.buffer[x][y].background)
    setForegroundColor(self.buffer[x][y].foreground)
    stdout.write(self.buffer[x][y].`char`)

  resetAttributes()


proc getFrame*(self: Renderer, x, y, width, height: int): Frame =
  result = newFrame(width, height)
  for x, y in self.buffer.iter(x, y, width, height):
    result[x][y] = Cell(
      background: self.buffer[x][y].background,
      foreground: self.buffer[x][y].foreground,
      `char`: self.buffer[x][y].`char`)


proc getFrame*(self: Renderer): Frame = self.getFrame(0, 0, self.size.x, self.size.y)
