/**
 * Прави иконата на приложението като PNG, без графична програма.
 *
 *     node tools/make-icon.mjs
 *
 * PNG е прост формат: подпис, заглавен блок, компресирани редове пиксели и
 * край. Node носи zlib вградено, значи целият кодер се събира в петдесетина
 * реда и иконата се поражда от кода, вместо да се пази двоичен файл, който
 * никой не може да редактира.
 *
 * Рисува знака на приложението: кривата на месеца върху мастилен фон.
 */
import { deflateSync } from "node:zlib";
import { writeFileSync, mkdirSync } from "node:fs";
import { dirname } from "node:path";

const SIZE = 1024;
const SS = 3;                     // подпикселни проби на страна, за загладени ръбове

/* ── Цветовете от визуалния език ─────────────────────────────── */
const INK_TOP = [0x18, 0x21, 0x3f];
const INK_BOT = [0x0a, 0x0f, 0x1f];
const VIOLET  = [0x8f, 0x7b, 0xff];
const MINT    = [0x4f, 0xe3, 0xc1];

/* Иконата иска силует, а не данни.
 *
 * Първият опит ползваше истинските 31 дни: на 60 пиксела 31 шипа стават каша,
 * а крайните върхове опират ръба. Тук са пет спокойни възвишения и плоската
 * опашка — разпознаваемото е формата, не точността. */
const VALUES = [30, 70, 34, 88, 40, 76, 46, 0, 0, 0];
const TODAY = 7;

/* Отстъп встрани, за да не се докосва нищо до ръба — iOS реже ъглите. */
const INSET = 0.12;

/* ── Кривата като функция y(x) ───────────────────────────────── */
function polyline() {
  const peak = Math.max(...VALUES);
  const top = SIZE * 0.28, bottom = SIZE * 0.70;
  const left = SIZE * INSET, span = SIZE * (1 - INSET * 2);
  const pts = VALUES.map((v, i) => ({
    x: left + (i / (VALUES.length - 1)) * span,
    y: bottom - (v / peak) * (bottom - top),
  }));

  // Катмул-Ром, разложен на много малки отсечки. За рисуване по пиксели е
  // по-удобно от криви на Безие: питаме за y при дадено x.
  const dense = [];
  for (let i = 0; i < pts.length - 1; i++) {
    const p0 = pts[i - 1] ?? pts[i], p1 = pts[i], p2 = pts[i + 1], p3 = pts[i + 2] ?? p2;
    for (let t = 0; t < 1; t += 0.004) {
      const t2 = t * t, t3 = t2 * t;
      dense.push({
        x: 0.5*((2*p1.x)+(-p0.x+p2.x)*t+(2*p0.x-5*p1.x+4*p2.x-p3.x)*t2+(-p0.x+3*p1.x-3*p2.x+p3.x)*t3),
        y: 0.5*((2*p1.y)+(-p0.y+p2.y)*t+(2*p0.y-5*p1.y+4*p2.y-p3.y)*t2+(-p0.y+3*p1.y-3*p2.y+p3.y)*t3),
      });
    }
  }
  dense.push(pts[pts.length - 1]);
  return dense;
}

const CURVE = polyline();
function yAt(x) {
  if (x <= CURVE[0].x) return CURVE[0].y;
  let lo = 0, hi = CURVE.length - 1;
  while (hi - lo > 1) {
    const mid = (lo + hi) >> 1;
    if (CURVE[mid].x <= x) lo = mid; else hi = mid;
  }
  const a = CURVE[lo], b = CURVE[hi];
  const k = b.x === a.x ? 0 : (x - a.x) / (b.x - a.x);
  return a.y + (b.y - a.y) * k;
}

/* ── Рисуване ────────────────────────────────────────────────── */
const STROKE = SIZE * 0.040;
const MARK_X = SIZE * INSET + ((TODAY - 1) / (VALUES.length - 1)) * SIZE * (1 - INSET * 2);
const MARK_R = SIZE * 0.052;

const mix = (a, b, k) => a.map((v, i) => Math.round(v + (b[i] - v) * k));

function sample(x, y) {
  const bg = mix(INK_TOP, INK_BOT, Math.min(1, y / SIZE));
  // Встрани от кривата остава само заливката: тя стига до ръба, за да няма
  // тъмни ивици, но щрихът и точката спират, за да не опират в ъглите.
  const inside = x >= SIZE * INSET && x <= SIZE * (1 - INSET);
  const cy = yAt(x);
  if (!inside) return y > cy ? mix(bg, VIOLET, 0.22) : bg;

  // Точката за днешния ден стои най-отгоре.
  const dx = x - MARK_X, dy = y - yAt(MARK_X);
  if (dx * dx + dy * dy <= MARK_R * MARK_R) return MINT;

  if (Math.abs(y - cy) <= STROKE / 2) return VIOLET;
  if (y > cy) return mix(bg, VIOLET, 0.22);   // заливката под кривата
  return bg;
}

const pixels = Buffer.alloc(SIZE * (SIZE * 3 + 1));
for (let py = 0; py < SIZE; py++) {
  const row = py * (SIZE * 3 + 1);
  pixels[row] = 0;                              // филтър „без филтър"
  for (let px = 0; px < SIZE; px++) {
    let r = 0, g = 0, b = 0;
    for (let sy = 0; sy < SS; sy++) {
      for (let sx = 0; sx < SS; sx++) {
        const c = sample(px + (sx + 0.5) / SS, py + (sy + 0.5) / SS);
        r += c[0]; g += c[1]; b += c[2];
      }
    }
    const n = SS * SS, at = row + 1 + px * 3;
    pixels[at] = Math.round(r / n);
    pixels[at + 1] = Math.round(g / n);
    pixels[at + 2] = Math.round(b / n);
  }
}

/* ── PNG ─────────────────────────────────────────────────────── */
const CRC = (() => {
  const t = new Int32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c;
  }
  return buf => {
    let c = -1;
    for (const byte of buf) c = t[(c ^ byte) & 0xff] ^ (c >>> 8);
    return (c ^ -1) >>> 0;
  };
})();

function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, "ascii"), data]);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(CRC(body));
  return Buffer.concat([len, body, crc]);
}

const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(SIZE, 0);
ihdr.writeUInt32BE(SIZE, 4);
ihdr[8] = 8;    // 8 бита на канал
ihdr[9] = 2;    // истински цвят, без прозрачност — iOS не приема прозрачни икони
ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;

const png = Buffer.concat([
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  chunk("IHDR", ihdr),
  chunk("IDAT", deflateSync(pixels, { level: 9 })),
  chunk("IEND", Buffer.alloc(0)),
]);

const out = "ios/Invexa/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png";
mkdirSync(dirname(out), { recursive: true });
writeFileSync(out, png);
console.log(`${out} · ${SIZE}×${SIZE} · ${(png.length / 1024).toFixed(1)} KB`);
