/**
 * Кривата на месеца — същият знак като в приложението.
 *
 * Дните текат отляво надясно, височината е дневният разход. След днешния
 * ден линията ляга, защото месецът още не се е случил; точно този плосък
 * участък прави силуета разпознаваем.
 *
 * Изчислява се на сървъра — няма JavaScript в браузъра за това.
 */

const AUGUST = [88, 22, 14, 41, 30, 18, 55, 26, 12, 34, 47, 20, 29, 63, 16, 24, 38, 44, 58, 31, 27];
const DAYS_IN_MONTH = 31;
const TODAY = 21;

const VALUES = [...AUGUST, ...Array<number>(DAYS_IN_MONTH - AUGUST.length).fill(0)];

type Point = { x: number; y: number };

function toPoints(values: number[], width: number, height: number, pad: number): Point[] {
  const max = Math.max(...values, 1);
  const base = height - pad;
  const span = height - pad * 2;
  return values.map((value, index) => ({
    x: (index / (values.length - 1)) * width,
    y: base - (value / max) * span,
  }));
}

/** Катмул-Ром през контролни точки на Безие — гладка крива без превишения. */
function smooth(points: Point[]): string {
  if (points.length < 2) return "";
  let d = `M${points[0].x.toFixed(2)},${points[0].y.toFixed(2)}`;
  for (let i = 0; i < points.length - 1; i++) {
    const p0 = points[i - 1] ?? points[i];
    const p1 = points[i];
    const p2 = points[i + 1];
    const p3 = points[i + 2] ?? p2;
    const c1x = p1.x + (p2.x - p0.x) / 6;
    const c1y = p1.y + (p2.y - p0.y) / 6;
    const c2x = p2.x - (p3.x - p1.x) / 6;
    const c2y = p2.y - (p3.y - p1.y) / 6;
    d += ` C${c1x.toFixed(2)},${c1y.toFixed(2)} ${c2x.toFixed(2)},${c2y.toFixed(2)} ${p2.x.toFixed(2)},${p2.y.toFixed(2)}`;
  }
  return d;
}

export default function MonthCurve() {
  const width = 640;
  const height = 128;
  const pad = height * 0.12;

  const points = toPoints(VALUES, width, height, pad);
  const line = smooth(points);
  const markerX = ((TODAY - 1) / (VALUES.length - 1)) * width;

  return (
    <svg
      viewBox={`0 0 ${width} ${height}`}
      preserveAspectRatio="none"
      role="img"
      aria-label="Дневните разходи за август. Днес е 21-и; след него кривата е плоска, защото месецът още не се е случил."
    >
      <path d={`${line} L${width},${height} L0,${height} Z`} fill="rgba(143,123,255,.22)" />
      <path
        d={line}
        fill="none"
        stroke="#8F7BFF"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <line
        x1={markerX}
        y1={0}
        x2={markerX}
        y2={height}
        stroke="#4FE3C1"
        strokeWidth="0.9"
        strokeOpacity="0.5"
        strokeDasharray="2 3"
      />
      <circle cx={markerX} cy={points[TODAY - 1].y} r="3.4" fill="#4FE3C1" />
    </svg>
  );
}
