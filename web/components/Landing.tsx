import Link from "next/link";
import MonthCurve from "@/components/MonthCurve";
import Signup from "@/components/Signup";
import type { Copy } from "@/lib/copy";

/**
 * Страницата, споделена от двата езика. Текстовете идват отвън, за да няма
 * два леко разминаващи се файла, които трябва да се поддържат заедно.
 */
export default function Landing({ copy }: { copy: Copy }) {
  const [captionTop, captionBottom] = copy.plate.caption.split("\n");

  return (
    <main className="shell">
      <div className="mark">
        <svg width="15" height="26" viewBox="0 0 15 26" fill="none" aria-hidden="true">
          <rect x=".5" y=".5" width="14" height="25" rx="4" stroke="#8F7BFF" strokeOpacity=".55" />
          <path
            d="M3 18 Q5.2 8 7.5 13 T12 7"
            stroke="#8F7BFF"
            strokeWidth="1.4"
            fill="none"
            strokeLinecap="round"
          />
        </svg>
        Invexa
        <Link className="lang" href={copy.switchTo.href} hrefLang={copy.lang === "bg" ? "en" : "bg"}>
          {copy.switchTo.label}
        </Link>
      </div>

      <header className="hero">
        <h1>
          {copy.hero.headline} <i>{copy.hero.accent}</i>
        </h1>

        <p className="lead">{copy.hero.lead}</p>

        <div className="plate">
          <div className="plate-top">
            <div className="plate-sum">
              {copy.plate.amount}
              <sup>€</sup>
            </div>
            <div className="plate-note">
              {captionTop}
              <br />
              {captionBottom}
            </div>
          </div>
          <MonthCurve />
          <div className="plate-axis">
            <span>{copy.plate.from}</span>
            <span>{copy.plate.today}</span>
            <span>{copy.plate.to}</span>
          </div>
        </div>
      </header>

      <section className="band">
        <div className="eyebrow">{copy.what.eyebrow}</div>
        <h2>{copy.what.heading}</h2>
        <p>{copy.what.lead}</p>

        <ul className="points">
          {copy.what.points.map((point) => (
            <li className="point" key={point.title}>
              <b>{point.title}</b>
              <span>{point.body}</span>
            </li>
          ))}
        </ul>
      </section>

      <section className="band">
        <div className="eyebrow">{copy.honest.eyebrow}</div>
        <h2>{copy.honest.heading}</h2>
        <p>{copy.honest.lead}</p>

        <ul className="plain">
          {copy.honest.rows.map((row) => (
            <li key={row.when}>
              <b>{row.when}</b>
              <span>{row.body}</span>
            </li>
          ))}
        </ul>
      </section>

      <section className="band">
        <div className="eyebrow">{copy.price.eyebrow}</div>
        <h2>{copy.price.heading}</h2>
        <p>{copy.price.lead}</p>

        <Signup copy={copy} />
      </section>

      <footer className="foot">
        {copy.footer.body}
        <a href={`mailto:${copy.footer.writeTo}`}>{copy.footer.writeTo}</a>.
      </footer>
    </main>
  );
}
