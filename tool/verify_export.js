// 用游戏 ranger2.js 的真实 gg() 判断式校验一份导出存档是否会被判死。
// 用法: node verify_export.js <saveString>
// 只复刻 gg() 中的范围检查与 wf 比对（不含分桶数据表校验，那与存档无关）。

const fs = require('fs');
const path = process.argv[2];

const ALPHABET = '01WtCplxayfTvqchHmA9*JZOri6VN7L4w8dUGe.S3FIDzsnPbEkQXYMRgu25BjoK';
const vf = {};
for (let i = 0; i < 64; i++) vf[ALPHABET[i]] = i;

function Df(a, b) {
  a += (b | 1) * ((a & 255) | 1);
  return (a >> 16) + (a & 65535);
}
function u(x) { return Math.floor(x); }
const D = () => 0; // Ef 的随机初值，对范围检查无影响

function decode(str) {
  const d = str.length - 4;
  if (d <= 0) return { err: 1 };
  if (!/^[0-9A-Za-z.*]+$/.test(str)) return { err: 2 };
  if (d < 10 || d > 5000) return { err: 3 };
  const b = vf[str[d]], h = vf[str[d + 1]];
  let c = (b + d) & 63;
  const of = new Array(d);
  for (let i = 0; i < d; i++) {
    of[i] = (vf[str[i]] - c) & 63;
    c = (((c * c) >> 4) + of[i] + i + h) & 65535;
  }
  if (vf[str[d + 2]] !== ((c >> 6) & 63) || vf[str[d + 3]] !== (c & 63)) return { err: 4 };
  const C = [];
  let a = 0, o = 0;
  while (a < d) {
    const v = of[a++];
    C[o++] = v;
    if (v <= 1) { const f = of[a++]; for (let k = 0; k < f; k++) C[o++] = v; }
  }
  let sum = 0;
  for (let i = 3; i < C.length; i++) sum += C[i];
  if (C[1] !== ((sum >> 6) & 63) || C[2] !== (sum & 63)) return { err: 4 };
  return { C };
}

// 按游戏 uf() 的字段顺序从 C[] 还原成命名变量
// C[0]=version C[1..2]=checksum C[3..4]=salt C[5..12]=userId C[13]=0 C[14..15]=q
function parse(C) {
  let a = 0;
  a++; a++; a++; a++; a++;    // 跳过 0..4
  const da = []; for (let b = 0; b < 8; b++) da.push(C[a++]);
  a++;                          // 13
  const q = (C[a++] << 6) + C[a++];
  for (let b = 0; b < 4; b++) { a++; a++; a++; }
  const Wa = C[a++];
  const Xa = (C[a++] << 6) + C[a++];
  const Ya = (C[a++] << 18) + (C[a++] << 12) + (C[a++] << 6) + C[a++];
  const Za = (C[a++] << 18) + (C[a++] << 12) + (C[a++] << 6) + C[a++];
  const $a = []; for (let b = 0; b < 4; b++) $a.push((C[a++] << 6) + C[a++]);
  const ab = []; for (let b = 0; b < 4; b++) ab.push((C[a++] << 12) + (C[a++] << 6) + C[a++]);
  const wb = [[], [], [], [], [], [], []];
  for (let b = 0; b < 4; b++) for (let c2 = 0; c2 < 7; c2++) wb[c2][b] = (C[a++] << 6) + C[a++];
  const ac = []; for (let b = 0; b < 4; b++) { ac.push([]); for (let c2 = 0; c2 < 8; c2++) ac[b].push((C[a++] << 6) + C[a++]); }
  let f = (C[a++] << 6) + C[a++];
  const cc = []; for (let b = 0; b < f; b++) cc.push(C[a++]);
  f = (C[a++] << 6) + C[a++];
  const ib = []; for (let b = 0; b < 9; b++) ib.push(C[a++]);
  const jb = C[a++];
  f = (C[a++] << 6) + C[a++];
  const hc = []; for (let b = 0; b < f; b++) hc.push(C[a++]);
  f = (C[a++] << 6) + C[a++];
  const jc = []; for (let b = 0; b < f; b++) jc.push(C[a++]);
  f = (C[a++] << 6) + C[a++];
  const mb = [], nb = { v: 0 };
  if (f >= 5) { for (let b = 0; b < 4; b++) mb.push(C[a++]); nb.v = C[a++]; }
  f = (C[a++] << 6) + C[a++];
  const lc = []; for (let b = 0; b < f; b++) lc.push(C[a++]);
  f = (C[a++] << 6) + C[a++];
  const nc = []; for (let b = 0; b < f; b++) nc.push(C[a++]);
  f = (C[a++] << 6) + C[a++];
  const rf = []; for (let b = 0; b < f; b++) rf.push(C[a++]);
  return { q, Wa, Xa, Ya, Za, $a, ab, wb, ac, cc, ib, jb, hc, jc, lc, nc, da };
}

// 复刻 gg() 的范围检查，返回被触发的条件列表
function check(s) {
  const v = [];
  const { q, Wa, Xa, Ya, Za, $a, wb, ib, ac, cc } = s;
  if (0 > Wa || 4 < Wa) v.push(`Wa(队伍人数)=${Wa}`);
  if (0 > Xa || 99 < Xa) v.push(`Xa(等级)=${Xa}`);
  if (0 > Ya || 9999999 < Ya) v.push(`Ya(经验)=${Ya}`);
  if (0 > Za || 9999999 < Za) v.push(`Za(金币)=${Za}`);
  for (let a = 0; a < 4; a++) {
    if (0 > $a[a] || 196 < $a[a]) v.push(`$a[${a}](技能点)=${$a[a]}`);
    const names = ['近战', '中程', '远程', '物理', '元素', '未用', '闪避'];
    for (let k = 0; k < 7; k++) {
      const lim = k === 6 ? 25 : 196;
      if (0 > wb[k][a] || lim < wb[k][a]) v.push(`wb.${names[k]}[${a}]=${wb[k][a]} 上限${lim}`);
    }
  }
  let lb = 0; for (let a = 0; a < 9; a++) if (1 == ib[a]) lb++;
  if (0 > lb || 9 < lb) v.push(`lb(技能数)=${lb}`);
  if (0 > q || 21 < q) v.push(`q(关卡)=${q} 超出 G[] 定义范围 0..21`);
  // 物品 ID 越界：游戏读 r[id] 会 undefined 解引用
  const DEF = (id) => (id >= 0 && id <= 141) || (id >= 145 && id <= 151) || (id >= 160 && id <= 164);
  for (let a = 0; a < 4; a++) for (let b = 0; b < 8; b++) {
    const id = ac[a][b];
    if (id !== 0 && !DEF(id)) v.push(`ac[${a}][${b}]=(装备物品ID)${id} 未定义`);
  }
  return v;
}

const str = fs.readFileSync(path, 'utf8').trim();
const dec = decode(str);
if (dec.err) { console.log(`❌ 解码失败，uf() 返回 ${dec.err}`); process.exit(1); }
const s = parse(dec.C);
const fails = check(s);
console.log(`存档长度 ${str.length}，展开 ${dec.C.length} 个 6-bit 值`);
console.log(`金币=${s.Za} 经验=${s.Ya} 等级=${s.Xa} 队伍=${s.Wa} 关卡=${s.q}`);
if (fails.length === 0) {
  console.log('✅ gg() 全部范围检查通过，游戏不会卡死');
} else {
  console.log('❌ 以下检查会触发 E=null（游戏卡死）：');
  for (const f of fails) console.log('   - ' + f);
  process.exit(1);
}
