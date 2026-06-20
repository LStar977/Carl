import math, zlib, struct

W = H = 1024
# Brand colors
NAVY  = (27, 42, 74)
CREAM = (244, 248, 255)
ROYAL = (37, 99, 235)
WHITE = (255, 255, 255)

buf = bytearray()
for _ in range(W*H):
    buf += bytes(NAVY)

def clamp(v, lo, hi): return lo if v < lo else hi if v > hi else v

def blend(x, y, col, a):
    if a <= 0: return
    i = (y*W + x)*3
    if a >= 1:
        buf[i], buf[i+1], buf[i+2] = col
        return
    ia = 1 - a
    buf[i]   = int(buf[i]*ia   + col[0]*a)
    buf[i+1] = int(buf[i+1]*ia + col[1]*a)
    buf[i+2] = int(buf[i+2]*ia + col[2]*a)

def circle(cx, cy, r, col):
    x0, x1 = int(cx-r-1), int(cx+r+2)
    y0, y1 = int(cy-r-1), int(cy+r+2)
    for y in range(max(0,y0), min(H,y1)):
        dy = y+0.5-cy
        for x in range(max(0,x0), min(W,x1)):
            dx = x+0.5-cx
            d = math.hypot(dx, dy) - r
            blend(x, y, col, clamp(0.5-d, 0, 1))

def rrect(cx, cy, hw, hh, rad, col):
    x0, x1 = int(cx-hw-1), int(cx+hw+2)
    y0, y1 = int(cy-hh-1), int(cy+hh+2)
    for y in range(max(0,y0), min(H,y1)):
        dy = abs(y+0.5-cy)
        for x in range(max(0,x0), min(W,x1)):
            dx = abs(x+0.5-cx)
            qx, qy = dx-(hw-rad), dy-(hh-rad)
            d = math.hypot(max(qx,0), max(qy,0)) + min(max(qx,qy),0) - rad
            blend(x, y, col, clamp(0.5-d, 0, 1))

def capsule(ax, ay, bx, by, rad, col):
    minx, maxx = int(min(ax,bx)-rad-1), int(max(ax,bx)+rad+2)
    miny, maxy = int(min(ay,by)-rad-1), int(max(ay,by)+rad+2)
    vx, vy = bx-ax, by-ay
    vv = vx*vx + vy*vy
    for y in range(max(0,miny), min(H,maxy)):
        for x in range(max(0,minx), min(W,maxx)):
            px, py = x+0.5-ax, y+0.5-ay
            t = clamp((px*vx+py*vy)/vv, 0, 1) if vv else 0
            d = math.hypot(px-vx*t, py-vy*t) - rad
            blend(x, y, col, clamp(0.5-d, 0, 1))

cx, cy = 512, 470
R = 300

# motion dashes (left, royal) — speed/AI cue
rrect(150, 405, 52, 16, 16, ROYAL)
rrect(168, 470, 40, 16, 16, ROYAL)
rrect(186, 535, 28, 16, 16, ROYAL)

# magnifier handle (under the lens, royal so it reads on navy)
p1 = (cx + R*math.cos(math.radians(45)), cy + R*math.sin(math.radians(45)))
capsule(p1[0], p1[1], p1[0]+180, p1[1]+180, 54, ROYAL)

# lens face
circle(cx, cy, R, CREAM)

# eyes
circle(cx-70, cy-34, 42, NAVY)
circle(cx+70, cy-34, 42, NAVY)
circle(cx-82, cy-48, 14, WHITE)
circle(cx+58, cy-48, 14, WHITE)

# briefcase clasp (royal outline) + body
rrect(cx, cy+40, 34, 26, 14, ROYAL)
rrect(cx, cy+40, 22, 15, 8, CREAM)
rrect(cx, cy+150, 108, 78, 26, ROYAL)
# clasp/latch detail
rrect(cx, cy+150, 108, 8, 0, NAVY)
rrect(cx, cy+138, 20, 22, 6, CREAM)

# encode PNG
def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag+data) & 0xffffffff)

raw = bytearray()
for y in range(H):
    raw.append(0)
    raw += buf[y*W*3:(y+1)*W*3]

png = b"\x89PNG\r\n\x1a\n"
png += chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
png += chunk(b"IEND", b"")

out = "/home/user/Carl/ios/Carl/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
open(out, "wb").write(png)
print("wrote", out, len(png), "bytes")
