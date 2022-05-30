{.experimental: "overloadableEnums".}

import std/unicode
import winim/lean as win32
import ./base; export base
import ../tmath; export tmath

const WM_DPICHANGED* = 0x02E0
const DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = -4

type Proc_SetProcessDpiAwarenessContext = proc(value: int): BOOL {.stdcall.}
var SetProcessDpiAwarenessContext: Proc_SetProcessDpiAwarenessContext
type Proc_GetDpiForWindow = proc(hWnd: HWND): UINT {.stdcall.}
var GetDpiForWindow: Proc_GetDpiForWindow

var librariesAreLoaded = false
proc loadLibraries() =
  if not librariesAreLoaded:
    let user32 = LoadLibraryA("user32.dll")
    if user32 == 0:
      quit("Error loading user32.dll")

    SetProcessDpiAwarenessContext = cast[Proc_SetProcessDpiAwarenessContext](
      GetProcAddress(user32, "SetProcessDpiAwarenessContext")
    )
    GetDpiForWindow = cast[Proc_GetDpiForWindow](
      GetProcAddress(user32, "GetDpiForWindow")
    )
    librariesAreLoaded = true

proc windowProc(hwnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.}

const windowClassName = "Default Canvas Class"
var canvasCount = 0

func hwnd(canvas: Canvas): HWND =
  cast[HWND](canvas.handle)

proc pollEvents(canvas: Canvas) =
  var msg: MSG
  while PeekMessage(msg, canvas.hwnd, 0, 0, PM_REMOVE) != 0:
    TranslateMessage(msg)
    DispatchMessage(msg)

proc updateBounds(canvas: Canvas) =
  var rect: RECT
  GetClientRect(canvas.hwnd, rect.addr)
  ClientToScreen(canvas.hwnd, cast[ptr POINT](rect.left.addr))
  ClientToScreen(canvas.hwnd, cast[ptr POINT](rect.right.addr))
  canvas.positionPixels = vec2(rect.left.float, rect.top.float)
  canvas.sizePixels = vec2((rect.right - rect.left).float, (rect.bottom - rect.top).float)

func toMouseButton(msg: UINT, wParam: WPARAM): MouseButton =
  case msg:
  of WM_LBUTTONDOWN, WM_LBUTTONUP, WM_LBUTTONDBLCLK:
    MouseButton.Left
  of WM_MBUTTONDOWN, WM_MBUTTONUP, WM_MBUTTONDBLCLK:
    MouseButton.Middle
  of WM_RBUTTONDOWN, WM_RBUTTONUP, WM_RBUTTONDBLCLK:
    MouseButton.Right
  of WM_XBUTTONDOWN, WM_XBUTTONUP, WM_XBUTTONDBLCLK:
    if HIWORD(wParam) == 1:
      MouseButton.Extra1
    else:
      MouseButton.Extra2
  else:
    MouseButton.Unknown

func toKeyboardKey(wParam: WPARAM, lParam: LPARAM): KeyboardKey =
  let scanCode = LOBYTE(HIWORD(lParam))
  let isRight = (HIWORD(lParam) and KF_EXTENDED) == KF_EXTENDED
  case scanCode:
    of 42: KeyboardKey.LeftShift
    of 54: KeyboardKey.RightShift
    of 29:
      if isRight: KeyboardKey.RightControl else: KeyboardKey.LeftControl
    of 56:
      if isRight: KeyboardKey.RightAlt else: KeyboardKey.LeftAlt
    else:
      case wParam.int:
      of 8: KeyboardKey.Backspace
      of 9: KeyboardKey.Tab
      of 13: KeyboardKey.Enter
      of 19: KeyboardKey.Pause
      of 20: KeyboardKey.CapsLock
      of 27: KeyboardKey.Escape
      of 32: KeyboardKey.Space
      of 33: KeyboardKey.PageUp
      of 34: KeyboardKey.PageDown
      of 35: KeyboardKey.End
      of 36: KeyboardKey.Home
      of 37: KeyboardKey.LeftArrow
      of 38: KeyboardKey.UpArrow
      of 39: KeyboardKey.RightArrow
      of 40: KeyboardKey.DownArrow
      of 45: KeyboardKey.Insert
      of 46: KeyboardKey.Delete
      of 48: KeyboardKey.Key0
      of 49: KeyboardKey.Key1
      of 50: KeyboardKey.Key2
      of 51: KeyboardKey.Key3
      of 52: KeyboardKey.Key4
      of 53: KeyboardKey.Key5
      of 54: KeyboardKey.Key6
      of 55: KeyboardKey.Key7
      of 56: KeyboardKey.Key8
      of 57: KeyboardKey.Key9
      of 65: KeyboardKey.A
      of 66: KeyboardKey.B
      of 67: KeyboardKey.C
      of 68: KeyboardKey.D
      of 69: KeyboardKey.E
      of 70: KeyboardKey.F
      of 71: KeyboardKey.G
      of 72: KeyboardKey.H
      of 73: KeyboardKey.I
      of 74: KeyboardKey.J
      of 75: KeyboardKey.K
      of 76: KeyboardKey.L
      of 77: KeyboardKey.M
      of 78: KeyboardKey.N
      of 79: KeyboardKey.O
      of 80: KeyboardKey.P
      of 81: KeyboardKey.Q
      of 82: KeyboardKey.R
      of 83: KeyboardKey.S
      of 84: KeyboardKey.T
      of 85: KeyboardKey.U
      of 86: KeyboardKey.V
      of 87: KeyboardKey.W
      of 88: KeyboardKey.X
      of 89: KeyboardKey.Y
      of 90: KeyboardKey.Z
      of 91: KeyboardKey.LeftMeta
      of 92: KeyboardKey.RightMeta
      of 96: KeyboardKey.Pad0
      of 97: KeyboardKey.Pad1
      of 98: KeyboardKey.Pad2
      of 99: KeyboardKey.Pad3
      of 100: KeyboardKey.Pad4
      of 101: KeyboardKey.Pad5
      of 102: KeyboardKey.Pad6
      of 103: KeyboardKey.Pad7
      of 104: KeyboardKey.Pad8
      of 105: KeyboardKey.Pad9
      of 106: KeyboardKey.PadMultiply
      of 107: KeyboardKey.PadAdd
      of 109: KeyboardKey.PadSubtract
      of 110: KeyboardKey.PadPeriod
      of 111: KeyboardKey.PadDivide
      of 112: KeyboardKey.F1
      of 113: KeyboardKey.F2
      of 114: KeyboardKey.F3
      of 115: KeyboardKey.F4
      of 116: KeyboardKey.F5
      of 117: KeyboardKey.F6
      of 118: KeyboardKey.F7
      of 119: KeyboardKey.F8
      of 120: KeyboardKey.F9
      of 121: KeyboardKey.F10
      of 122: KeyboardKey.F11
      of 123: KeyboardKey.F12
      of 144: KeyboardKey.NumLock
      of 145: KeyboardKey.ScrollLock
      of 186: KeyboardKey.Semicolon
      of 187: KeyboardKey.Equal
      of 188: KeyboardKey.Comma
      of 189: KeyboardKey.Minus
      of 190: KeyboardKey.Period
      of 191: KeyboardKey.Slash
      of 192: KeyboardKey.Backtick
      of 219: KeyboardKey.LeftBracket
      of 220: KeyboardKey.BackSlash
      of 221: KeyboardKey.RightBracket
      of 222: KeyboardKey.Quote
      else: KeyboardKey.Unknown

template processFrame(canvas: Canvas, stateChanges: untyped)=
  canvas.updatePreviousState()
  stateChanges
  canvas.beginFrameBase()
  if canvas.onFrame != nil:
    canvas.onFrame()
  canvas.endFrameBase()

proc update*(canvas: Canvas) =
  canvas.processFrame:
    canvas.pollEvents()

proc close*(canvas: Canvas) =
  if canvas.isOpen:
    DestroyWindow(canvas.hwnd)
    canvas.isOpen = false

proc newCanvas*(parentHandle: pointer = nil): Canvas =
  loadLibraries()

  result = cast[Canvas](newCanvasBase())
  result.isOpen = true

  if canvasCount == 0:
    var windowClass = WNDCLASSEX(
      cbSize: WNDCLASSEX.sizeof.UINT,
      style: CS_OWNDC,
      lpfnWndProc: windowProc,
      cbClsExtra: 0,
      cbWndExtra: 0,
      hInstance: GetModuleHandle(nil),
      hIcon: 0,
      hCursor: LoadCursor(0, IDC_ARROW),
      hbrBackground: CreateSolidBrush(RGB(0, 0, 0)),
      lpszMenuName: nil,
      lpszClassName: windowClassName,
      hIconSm: 0,
    )
    RegisterClassEx(windowClass)

  let isChild = parentHandle != nil
  let windowStyle =
    if isChild:
      WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or WS_CLIPSIBLINGS
    else:
      WS_OVERLAPPEDWINDOW or WS_VISIBLE

  result.isChild = isChild

  let hwnd = CreateWindow(
    lpClassName = windowClassName,
    lpWindowName = "Canvas",
    dwStyle = windowStyle.int32,
    x = 0,
    y = 0,
    nWidth = 800,
    nHeight = 600,
    hWndParent = cast[HWND](parentHandle),
    hMenu = 0,
    hInstance = GetModuleHandle(nil),
    lpParam = cast[pointer](result),
  )
  result.handle = cast[pointer](hwnd)

  discard SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)

  result.updateBounds()
  result.initBase()

  inc canvasCount

proc windowProc(hwnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
  if msg == WM_CREATE:
    var lpcs = cast[LPCREATESTRUCT](lParam)
    SetWindowLongPtr(hwnd, GWLP_USERDATA, cast[LONG_PTR](lpcs.lpCreateParams))

  let canvas = cast[Canvas](GetWindowLongPtr(hwnd, GWLP_USERDATA))
  if canvas == nil or hwnd != canvas.hwnd:
    return DefWindowProc(hwnd, msg, wParam, lParam)

  case msg:

  of WM_MOVE:
    canvas.updateBounds()

  of WM_SIZE:
    canvas.processFrame:
      canvas.updateBounds()

  # of WM_ENTERSIZEMOVE:
  #   canvas.platform.moveTimer = SetTimer(canvas.hwnd, 1, USER_TIMER_MINIMUM, nil)

  # of WM_EXITSIZEMOVE:
  #   KillTimer(canvas.hwnd, canvas.platform.moveTimer)

  # of WM_TIMER:
  #   if wParam == canvas.platform.moveTimer:
  #     canvas.processFrame:
  #       canvas.updateBounds()

  # of WM_WINDOWPOSCHANGED:
  #   canvas.processFrame:
  #     canvas.updateBounds()
  #   return 0

  of WM_CLOSE:
    canvas.close()

  of WM_DESTROY:
    dec canvasCount
    canvasCount = canvasCount.max(0)
    if canvasCount == 0:
      UnregisterClass(windowClassName, GetModuleHandle(nil))

  of WM_DPICHANGED:
    canvas.dpi = GetDpiForWindow(canvas.hwnd).float

  of WM_MOUSEMOVE:
    canvas.mousePositionPixels = vec2(GET_X_LPARAM(lParam).float, GET_Y_LPARAM(lParam).float)

  of WM_MOUSEWHEEL:
    canvas.mouseWheel.y += GET_WHEEL_DELTA_WPARAM(wParam).float / WHEEL_DELTA.float

  of WM_MOUSEHWHEEL:
    canvas.mouseWheel.x += GET_WHEEL_DELTA_WPARAM(wParam).float / WHEEL_DELTA.float

  of WM_LBUTTONDOWN, WM_LBUTTONDBLCLK,
     WM_MBUTTONDOWN, WM_MBUTTONDBLCLK,
     WM_RBUTTONDOWN, WM_RBUTTONDBLCLK,
     WM_XBUTTONDOWN, WM_XBUTTONDBLCLK:
    SetCapture(canvas.hwnd)
    let button = toMouseButton(msg, wParam)
    canvas.mousePresses.add button
    canvas.mouseDownStates[button] = true

  of WM_LBUTTONUP, WM_MBUTTONUP, WM_RBUTTONUP, WM_XBUTTONUP:
    ReleaseCapture()
    let button = toMouseButton(msg, wParam)
    canvas.mouseReleases.add button
    canvas.mouseDownStates[toMouseButton(msg, wParam)] = false

  of WM_KEYDOWN, WM_SYSKEYDOWN:
    let key = toKeyboardKey(wParam, lParam)
    canvas.keyPresses.add key
    canvas.keyDownStates[key] = true

  of WM_KEYUP, WM_SYSKEYUP:
    let key = toKeyboardKey(wParam, lParam)
    canvas.keyReleases.add key
    canvas.keyDownStates[key] = false

  of WM_CHAR, WM_SYSCHAR:
    if wParam > 0 and wParam < 0x10000:
      canvas.textInput &= cast[Rune](wParam).toUTF8

  else:
    discard

  DefWindowProc(hwnd, msg, wParam, lParam)