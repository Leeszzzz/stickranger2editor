"""生成 pixel_icons.dart 的图标字形表。

每个图标 16x16，`#` 实心像素、`.` 透明。
风格：实心剪影、单色、**左右镜像对称**。

对称策略：所有图标都按左半边（x=0..7）绘制，再由 mirror() 镜像到右半边，
从构造上杜绝不对称。因此不要用会跨中轴的浮点圆，改用 2 格对齐的整数图元。
"""
import io
import math

W = H = 16
HALF = W // 2          # 8：左半边宽度
SOLID, EMPTY = '#', '.'


def blank():
    return [[EMPTY] * W for _ in range(H)]


def mirror(g):
    """把左半边镜像到右半边，保证严格左右对称。"""
    for y in range(H):
        for x in range(HALF):
            g[y][W - 1 - x] = g[y][x]
    return g


def rect(g, x0, y0, x1, y1, val=SOLID):
    """含首含尾的实心矩形。"""
    for y in range(max(0, y0), min(H - 1, y1) + 1):
        for x in range(max(0, x0), min(W - 1, x1) + 1):
            g[y][x] = val


def row(g, y, x0, x1, val=SOLID):
    rect(g, x0, y, x1, y, val)


def col(g, x, y0, y1, val=SOLID):
    rect(g, x, y0, x, y1, val)


def mirror_rect(g, x0, y0, x1, y1, val=SOLID):
    """画一个矩形，同时画它的镜像（用于只定义左半边的场景）。"""
    rect(g, x0, y0, x1, y1, val)
    rect(g, W - 1 - x1, y0, W - 1 - x0, y1, val)


def centered_rect(g, half_w, y0, y1, val=SOLID):
    """以中轴对称、宽度为 2*half_w 的矩形（居中于 x=7.5）。"""
    mirror_rect(g, HALF - half_w, y0, HALF - 1, y1, val)


def half_disc(g, cy, r, val=SOLID, cx=HALF):
    """以左边 x=8 处为圆心画半圆（配合 mirror 得到完整圆）。"""
    for y in range(H):
        for x in range(cx):
            if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r:
                g[y][x] = val


def centered_disc(g, cy, r, val=SOLID):
    half_disc(g, cy, r, val)


def centered_ring(g, cy, ro, ri, val=SOLID):
    for y in range(H):
        for x in range(HALF):
            d = (x + 0.5 - HALF) ** 2 + (y + 0.5 - cy) ** 2
            if ri * ri <= d <= ro * ro:
                g[y][x] = val


def centered_star(g, cy, ro, ri, points=5):
    """以中轴对称的星形：只算左半边再镜像。"""
    pts = []
    for i in range(points * 2):
        ang = -math.pi / 2 + i * math.pi / points
        r = ro if i % 2 == 0 else ri
        pts.append((HALF + r * math.cos(ang), cy + r * math.sin(ang)))
    ys = [p[1] for p in pts]
    for y in range(int(min(ys)), int(max(ys)) + 1):
        xs = []
        for i in range(len(pts)):
            x1, y1 = pts[i]
            x2, y2 = pts[(i + 1) % len(pts)]
            if y1 == y2:
                continue
            if min(y1, y2) <= y < max(y1, y2):
                t = (y - y1) / (y2 - y1)
                xs.append(x1 + t * (x2 - x1))
        xs.sort()
        for i in range(0, len(xs) - 1, 2):
            for x in range(int(math.ceil(xs[i])), int(math.floor(xs[i + 1])) + 1):
                if 0 <= x < HALF:
                    g[y][x] = SOLID


# ---------------------------------------------------------------- 图标

def logo():
    g = blank()
    # 书壳
    rect(g, 2, 4, 13, 14)
    # 书页横线（负空间）
    row(g, 7, 4, 11, EMPTY)
    row(g, 10, 4, 11, EMPTY)
    row(g, 13, 4, 9, EMPTY)
    mirror(g)
    # 顶部星：最后叠加，压在书壳上沿
    centered_star(g, 3.0, 3.4, 1.4)
    return mirror(g)


def save():
    g = blank()
    rect(g, 2, 2, 13, 13)
    # 顶部滑片（负空间）
    rect(g, 5, 2, 10, 6, EMPTY)
    rect(g, 6, 3, 9, 4)
    # 底部标签（负空间）
    rect(g, 4, 9, 11, 13, EMPTY)
    rect(g, 5, 10, 10, 11)
    return mirror(g)


def grid():
    g = blank()
    for y0 in (2, 9):
        for x0 in (2, 9):
            rect(g, x0, y0, x0 + 4, y0 + 4)
    return mirror(g)


def person():
    g = blank()
    centered_disc(g, 5.0, 3.2)
    # 肩部：上窄下宽
    mirror_rect(g, 4, 10, 7, 10)
    mirror_rect(g, 3, 11, 7, 11)
    mirror_rect(g, 2, 12, 7, 14)
    return mirror(g)


def bag():
    g = blank()
    # 提手（负空间挖空）
    rect(g, 4, 2, 11, 4, EMPTY)
    rect(g, 2, 5, 13, 14)
    rect(g, 5, 3, 10, 4, EMPTY)
    # 提手两竖
    col(g, 5, 3, 4)
    col(g, 10, 3, 4)
    # 口袋
    rect(g, 5, 8, 10, 11, EMPTY)
    return mirror(g)


def trophy():
    g = blank()
    # 杯口
    row(g, 2, 4, 11)
    # 杯身逐行收窄
    row(g, 3, 3, 12)
    row(g, 4, 3, 12)
    row(g, 5, 4, 11)
    row(g, 6, 4, 11)
    row(g, 7, 5, 10)
    row(g, 8, 6, 9)
    # 双耳
    col(g, 1, 4, 6)
    col(g, 14, 4, 6)
    row(g, 4, 1, 1)
    row(g, 6, 1, 2)
    # 柄 + 底座
    col(g, 7, 9, 11)
    row(g, 12, 5, 10)
    row(g, 13, 4, 11)
    return mirror(g)


def book():
    g = blank()
    rect(g, 2, 2, 13, 13)
    # 书页负空间
    rect(g, 4, 4, 11, 11, EMPTY)
    # 书脊
    col(g, 2, 2, 13)
    col(g, 3, 2, 13)
    row(g, 6, 6, 9, EMPTY)
    return mirror(g)


def book_open():
    g = blank()
    # 左右两页 + 中缝
    mirror_rect(g, 1, 5, 6, 12)
    mirror_rect(g, 1, 4, 4, 4)
    mirror_rect(g, 2, 13, 6, 13)
    col(g, 7, 3, 13)
    col(g, 8, 3, 13)
    return mirror(g)


def coin():
    g = blank()
    centered_disc(g, 8.0, 6.4)
    centered_ring(g, 8.0, 2.8, 1.8, EMPTY)
    # 中心竖条（钱币的孔/纹）
    centered_rect(g, 1, 5, 10)
    return mirror(g)


def bolt():
    g = blank()
    # 实心闪电：上宽下窄，中段收腰，再镜像成对称双雷
    widths = {1: 3, 2: 3, 3: 2, 4: 2, 5: 3, 6: 3, 7: 2, 8: 2,
              9: 3, 10: 3, 11: 2, 12: 2}
    for y, w in widths.items():
        mirror_rect(g, HALF - w, y, HALF - 1, y)
    return mirror(g)


def star_icon():
    g = blank()
    centered_star(g, 8.0, 7.0, 3.0)
    return mirror(g)


def heart():
    g = blank()
    # 两个肩 + 下尖，肩部用整数矩形堆叠保证对称
    mirror_rect(g, 2, 4, 7, 4)
    mirror_rect(g, 1, 5, 7, 8)
    mirror_rect(g, 2, 9, 7, 9)
    mirror_rect(g, 3, 10, 7, 10)
    mirror_rect(g, 4, 11, 7, 11)
    mirror_rect(g, 5, 12, 7, 12)
    mirror_rect(g, 6, 13, 7, 13)
    return mirror(g)


def sword():
    g = blank()
    # 竖直刀身，带尖
    col(g, 7, 1, 1)
    col(g, 7, 2, 9)
    col(g, 8, 2, 9)
    row(g, 0, 7, 8)
    # 护手
    row(g, 10, 2, 13)
    row(g, 11, 3, 12)
    # 柄
    col(g, 7, 12, 14)
    col(g, 8, 12, 14)
    # 柄头
    row(g, 15, 6, 9)
    return mirror(g)


def shield():
    g = blank()
    row(g, 1, 3, 12)
    row(g, 2, 2, 13)
    row(g, 3, 2, 13)
    for y in range(4, 14):
        inset = (y - 3) // 2
        mirror_rect(g, 2 + inset, y, 7, y)
    # 中央十字负空间
    col(g, 7, 5, 10, EMPTY)
    col(g, 8, 5, 10, EMPTY)
    row(g, 6, 5, 10, EMPTY)
    return mirror(g)


def ring_icon():
    g = blank()
    centered_ring(g, 9.0, 6.0, 3.6)
    # 顶部宝石
    mirror_rect(g, 6, 1, 7, 3)
    return mirror(g)


def amulet():
    g = blank()
    # 链条
    mirror_rect(g, 3, 1, 7, 1)
    col(g, 3, 2, 5)
    col(g, 4, 6, 7)
    # 吊坠
    mirror_rect(g, 5, 8, 7, 12)
    mirror_rect(g, 6, 13, 7, 13)
    return mirror(g)


def hat():
    g = blank()
    # 帽冠
    mirror_rect(g, 5, 3, 7, 9)
    mirror_rect(g, 6, 2, 7, 2)
    # 帽檐
    row(g, 10, 1, 14)
    row(g, 11, 2, 13)
    return mirror(g)


def spark():
    g = blank()
    # 菱形四芒
    col(g, 7, 1, 14)
    col(g, 8, 1, 14)
    row(g, 7, 1, 14)
    row(g, 8, 1, 14)
    # 收窄两端形成菱形
    mirror_rect(g, 5, 3, 7, 5)
    mirror_rect(g, 5, 10, 7, 12)
    return mirror(g)


def potion():
    g = blank()
    # 瓶颈
    mirror_rect(g, 6, 1, 7, 3)
    # 瓶身
    row(g, 4, 5, 10)
    row(g, 5, 4, 11)
    for y in range(6, 14):
        mirror_rect(g, 2, y, 7, y)
    row(g, 14, 3, 12)
    # 液面（负空间）
    row(g, 8, 4, 11, EMPTY)
    row(g, 8, 3, 12, EMPTY)
    return mirror(g)


def map():
    g = blank()
    # 折叠地图：三竖条 + 折痕负空间
    rect(g, 1, 4, 4, 12)
    rect(g, 6, 6, 9, 14)
    rect(g, 11, 4, 14, 12)
    return mirror(g)


def flag():
    g = blank()
    # 旗杆
    col(g, 3, 1, 14)
    col(g, 4, 1, 14)
    # 旗面
    row(g, 2, 5, 12)
    row(g, 3, 5, 12)
    row(g, 4, 5, 11)
    row(g, 5, 5, 11)
    row(g, 6, 5, 10)
    row(g, 7, 5, 10)
    row(g, 8, 5, 9)
    return mirror(g)


def skull():
    g = blank()
    centered_disc(g, 6.0, 5.5)
    # 眼窝
    mirror_rect(g, 3, 5, 5, 7, EMPTY)
    # 下颌
    row(g, 11, 5, 10)
    row(g, 12, 5, 10)
    row(g, 13, 6, 9)
    # 牙缝
    col(g, 7, 11, 13, EMPTY)
    return mirror(g)


def eye():
    g = blank()
    # 眼形：上下收窄
    row(g, 6, 2, 13)
    row(g, 7, 1, 14)
    row(g, 8, 1, 14)
    row(g, 9, 2, 13)
    # 瞳孔
    centered_disc(g, 8.0, 2.6, EMPTY)
    centered_disc(g, 8.0, 1.4)
    return mirror(g)


def dice():
    g = blank()
    rect(g, 2, 2, 13, 13)
    # 五点：中心 + 四角
    centered_rect(g, 1, 7, 8, EMPTY)
    for (x, y) in [(5, 4), (10, 4), (5, 11), (10, 11)]:
        rect(g, x, y, x + 1, y + 1, EMPTY)
    return mirror(g)


def clock():
    g = blank()
    centered_ring(g, 8.0, 6.8, 4.4)
    # 指针：12 点与 3 点方向
    col(g, 7, 4, 8)
    col(g, 8, 4, 8)
    row(g, 7, 8, 11)
    row(g, 8, 8, 11)
    return mirror(g)


def gear():
    # 中心圆盘 + 四向粗齿，先画圆再补齿，轮廓连贯
    g = blank()
    centered_disc(g, 8.0, 4.6)
    # 上下齿（与圆盘相接）
    mirror_rect(g, 6, 1, 7, 3)
    mirror_rect(g, 6, 12, 7, 14)
    # 左右齿
    mirror_rect(g, 1, 6, 3, 9)
    # 中心孔
    centered_disc(g, 8.0, 1.9, EMPTY)
    return mirror(g)


def search():
    g = blank()
    # 镜圈
    centered_ring(g, 6.5, 5.6, 3.2)
    # 手柄（斜向右下，镜像后成对称的双尾）
    for i in range(4):
        rect(g, 10 + i, 10 + i, 11 + i, 11 + i)
    return mirror(g)


def sun():
    g = blank()
    centered_disc(g, 8.0, 3.4)
    # 八方向光芒
    mirror_rect(g, 7, 0, 7, 1)
    mirror_rect(g, 7, 14, 7, 15)
    mirror_rect(g, 0, 7, 1, 8)
    mirror_rect(g, 3, 3, 4, 4)
    mirror_rect(g, 3, 11, 4, 12)
    return mirror(g)


def moon():
    g = blank()
    centered_disc(g, 8.0, 6.4)
    # 用偏右的圆挖出月牙（镜像后仍对称）
    for y in range(H):
        for x in range(HALF, W):
            if (x + 0.5 - 10.0) ** 2 + (y + 0.5 - 6.0) ** 2 <= 5.4 ** 2:
                g[y][x] = EMPTY
    return mirror(g)


def monitor():
    g = blank()
    rect(g, 1, 2, 14, 10)
    rect(g, 2, 3, 13, 9, EMPTY)
    # 支架
    mirror_rect(g, 7, 11, 7, 12)
    row(g, 13, 4, 11)
    row(g, 14, 3, 12)
    return mirror(g)


def lock():
    g = blank()
    # 锁梁（上半环）
    centered_ring(g, 6.0, 4.4, 2.6)
    row(g, 6, 3, 12, EMPTY)
    # 锁体
    rect(g, 2, 7, 13, 14)
    # 钥匙孔
    centered_rect(g, 1, 9, 11, EMPTY)
    return mirror(g)


def unlock():
    g = blank()
    # 开锁梁：只有右半边，镜像后成两根短柱（表示脱开）
    mirror_rect(g, 3, 4, 4, 6)
    # 锁体
    rect(g, 2, 7, 13, 14)
    centered_rect(g, 1, 9, 11, EMPTY)
    return mirror(g)


def check():
    g = blank()
    # 对勾：左短斜 + 右长斜
    for i in range(3):
        rect(g, 3 + i, 8 + i, 4 + i, 9 + i)
    for i in range(6):
        rect(g, 6 + i, 10 - i, 7 + i, 11 - i)
    return mirror(g)


def close():
    g = blank()
    for i in range(10):
        rect(g, 3 + i, 3 + i, 4 + i, 4 + i)
        rect(g, 12 - i, 3 + i, 13 - i, 4 + i)
    return mirror(g)


def plus():
    g = blank()
    centered_rect(g, 2, 2, 13)
    row(g, 7, 2, 13)
    row(g, 8, 2, 13)
    return mirror(g)


def minus():
    g = blank()
    row(g, 7, 2, 13)
    row(g, 8, 2, 13)
    return mirror(g)


def arrow_right():
    # 实心右指箭头：粗杆 + 实心三角头
    g = blank()
    # 杆（从左侧到三角根部）
    for y in (6, 7, 8, 9):
        for x in range(1, 10):
            g[y][x] = SOLID
    # 三角头：以 x=10 为底，尖端 x=15
    head = {
        2: (10, 10), 3: (10, 11), 4: (10, 12),
        5: (10, 13), 6: (10, 14), 7: (10, 15),
        8: (10, 15), 9: (10, 14), 10: (10, 13),
        11: (10, 12), 12: (10, 11), 13: (10, 10),
    }
    for y, (x0, x1) in head.items():
        for x in range(x0, x1 + 1):
            g[y][x] = SOLID
    return g  # 方向性图标，天然不对称，不做镜像


def chevron_down():
    g = blank()
    # 对称 V 形
    for i in range(5):
        mirror_rect(g, 3 + i, 6 + i, 4 + i, 7 + i)
    return mirror(g)


def chevron_up():
    g = blank()
    for i in range(5):
        mirror_rect(g, 3 + i, 10 - i, 4 + i, 11 - i)
    return mirror(g)


def upload():
    g = blank()
    # 托盘
    mirror_rect(g, 2, 11, 4, 14)
    row(g, 14, 2, 13)
    # 上箭头
    centered_rect(g, 1, 5, 11)
    for i in range(4):
        mirror_rect(g, 4 + i, 5 - i, 7, 6 - i)
    return mirror(g)


def download():
    g = blank()
    mirror_rect(g, 2, 11, 4, 14)
    row(g, 14, 2, 13)
    centered_rect(g, 1, 2, 8)
    for i in range(4):
        mirror_rect(g, 4 + i, 8 + i, 7, 9 + i)
    return mirror(g)


def copy():
    g = blank()
    rect(g, 1, 1, 9, 9)
    rect(g, 3, 3, 7, 7, EMPTY)
    rect(g, 6, 6, 14, 14)
    rect(g, 8, 8, 12, 12, EMPTY)
    return mirror(g)


def trash():
    g = blank()
    # 盖
    row(g, 1, 3, 12)
    row(g, 2, 4, 11)
    # 提手
    mirror_rect(g, 6, 0, 7, 0)
    # 桶身
    rect(g, 3, 3, 12, 14)
    # 桶身两条负空间竖纹
    col(g, 6, 5, 12, EMPTY)
    col(g, 9, 5, 12, EMPTY)
    return mirror(g)


def info():
    g = blank()
    centered_ring(g, 8.0, 6.8, 0.0)
    # 挖出圆环内部，只留 2px 边
    for y in range(H):
        for x in range(HALF):
            d = (x + 0.5 - HALF) ** 2 + (y + 0.5 - 8.0) ** 2
            if d <= 5.0 ** 2:
                g[y][x] = EMPTY
    # 圆点 + 竖条
    centered_rect(g, 1, 4, 5)
    centered_rect(g, 1, 7, 12)
    return mirror(g)


def warning():
    g = blank()
    # 三角
    for i in range(13):
        y = 2 + i
        half = (i + 1) // 2 + 1
        mirror_rect(g, HALF - half, y, HALF - 1, y)
    # 感叹号负空间
    centered_rect(g, 1, 6, 10, EMPTY)
    centered_rect(g, 1, 12, 13, EMPTY)
    return mirror(g)


def external():
    g = blank()
    rect(g, 1, 5, 10, 14)
    rect(g, 3, 7, 8, 12, EMPTY)
    # 右上角外链箭头
    rect(g, 9, 1, 14, 1)
    col(g, 14, 1, 6)
    for i in range(4):
        rect(g, 9 + i, 6 - i, 10 + i, 7 - i)
    return mirror(g)


def scroll():
    g = blank()
    # 卷轴主体
    rect(g, 3, 3, 12, 12)
    # 上下卷边
    row(g, 1, 1, 14)
    row(g, 2, 2, 13)
    row(g, 13, 2, 13)
    row(g, 14, 1, 14)
    # 文字行负空间
    row(g, 5, 5, 10, EMPTY)
    row(g, 7, 5, 10, EMPTY)
    row(g, 9, 5, 8, EMPTY)
    return mirror(g)


ICONS = [
    ('logo', '书 + 星：SR2 EDITOR 标识', logo),
    ('save', '软盘：保存存档', save),
    ('grid', '四宫格：总览', grid),
    ('person', '人形：角色', person),
    ('bag', '背包：物品数据库', bag),
    ('trophy', '奖杯：进度', trophy),
    ('book', '书本：数据源', book),
    ('bookOpen', '翻开的书', book_open),
    ('coin', '钱币：金币', coin),
    ('bolt', '闪电：经验', bolt),
    ('star', '星形', star_icon),
    ('heart', '心形：生命', heart),
    ('sword', '剑：武器', sword),
    ('shield', '盾：防御', shield),
    ('ring', '戒指', ring_icon),
    ('amulet', '护符', amulet),
    ('hat', '帽子', hat),
    ('spark', '四芒星：快捷', spark),
    ('potion', '药瓶：饭团', potion),
    ('map', '地图：关卡', map),
    ('flag', '旗帜', flag),
    ('skull', '骷髅：怪物', skull),
    ('eye', '眼睛：图鉴', eye),
    ('dice', '骰子：队伍', dice),
    ('clock', '时钟', clock),
    ('gear', '齿轮：设置', gear),
    ('search', '放大镜：搜索', search),
    ('sun', '太阳：浅色', sun),
    ('moon', '月亮：深色', moon),
    ('monitor', '显示器：跟随系统', monitor),
    ('lock', '锁', lock),
    ('unlock', '开锁', unlock),
    ('check', '对勾', check),
    ('close', '叉号', close),
    ('plus', '加号', plus),
    ('minus', '减号', minus),
    ('arrowRight', '右箭头', arrow_right),
    ('chevronDown', '下折角', chevron_down),
    ('chevronUp', '上折角', chevron_up),
    ('upload', '上传', upload),
    ('download', '下载', download),
    ('copy', '复制', copy),
    ('trash', '删除', trash),
    ('info', '信息', info),
    ('warning', '警告', warning),
    ('external', '外部链接', external),
    ('scroll', '卷轴', scroll),
]


# 方向性图标天然单向，不参与对称校验
ASYMMETRIC = {'arrowRight', 'external'}


def audit():
    """检查尺寸、对称性与可见像素数。"""
    problems = []
    for name, _, fn in ICONS:
        g = fn()
        if len(g) != H:
            problems.append(f'{name}: {len(g)} rows')
            continue
        for i, r in enumerate(g):
            if len(r) != W:
                problems.append(f'{name} row {i}: {len(r)} cols')
        # 对称性（方向性图标跳过）
        for y in range(H) if name not in ASYMMETRIC else ():
            for x in range(HALF):
                if g[y][x] != g[y][W - 1 - x]:
                    problems.append(f'{name}: 不对称 at ({x},{y})')
                    break
            else:
                continue
            break
        filled = sum(1 for r in g for c in r if c == SOLID)
        if filled < 20:
            problems.append(f'{name}: 仅 {filled} 个实心像素，可能过空')
        if filled > 200:
            problems.append(f'{name}: {filled} 个实心像素，可能过满')
    return problems


def main():
    problems = audit()
    if problems:
        print('=== 问题 ===')
        for p in problems:
            print(' ', p)
        print()

    if '--preview' in __import__('sys').argv:
        for name, _, fn in ICONS:
            print(f'--- {name} ---')
            for r in fn():
                print(''.join(r))
            print()

    out = ['''/// 16×16 像素图标（实心剪影，单色，左右对称）。
///
/// 每个图标由 16 行、每行 16 个字符组成：
/// `#` 实心像素（取用色）、`.` 透明。
/// 只靠轮廓与负空间表达形状，不含高光/阴影分色，因此整体跟随取用色。
/// 字形由 tool/gen_icons.py 生成，改动请改脚本后重新生成。
library;

import 'package:flutter/material.dart';

import '../../theme/pixel_theme.dart';

class PixelGlyphData {
  const PixelGlyphData(this.rows);
  final List<String> rows;
}

abstract final class PixelIcons {''']
    for name, doc, fn in ICONS:
        g = fn()
        out.append(f'\n  /// {doc}。')
        out.append(f'  static const {name} = PixelGlyphData([')
        for r in g:
            out.append(f"    '{''.join(r)}',")
        out.append('  ]);')
    out.append('''
}

/// 绘制一个像素图标。
///
/// 字形是纯剪影，只有 `#` 一种实心像素，因此颜色完全由 [color] 决定；
/// [accent] 仅保留在签名中以兼容既有调用点，当前不参与绘制。
class PixelGlyph extends StatelessWidget {
  const PixelGlyph(
    this.data, {
    super.key,
    this.size = 16,
    this.color,
    this.accent,
  });

  final PixelGlyphData data;
  final double size;
  final Color? color;

  /// 兼容参数：实心剪影风格下不使用。
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final main = color ?? p.ink;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        isComplex: false,
        painter: _GlyphPainter(data, main: main),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.data, {required this.main});

  final PixelGlyphData data;
  final Color main;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.shortestSide / 16.0;
    final paint = Paint()
      ..isAntiAlias = false
      ..color = main;
    for (var y = 0; y < data.rows.length; y++) {
      final row = data.rows[y];
      for (var x = 0; x < row.length && x < 16; x++) {
        if (row[x] != '#') continue;
        canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.main != main;
}
''')

    io.open('lib/ui/widgets/pixel_icons.dart', 'w', encoding='utf-8').write(
        '\n'.join(out) + '\n'
    )
    print(f'生成完成：{len(ICONS)} 个图标')


main()
