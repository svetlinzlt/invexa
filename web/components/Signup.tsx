"use client";

import { useId, useRef, useState } from "react";
import type { Copy } from "@/lib/copy";
import type { Plan } from "@/lib/waitlist";

type Status =
  | { kind: "idle" }
  | { kind: "sending" }
  | { kind: "done"; duplicate: boolean }
  | { kind: "failed"; message: string };

export default function Signup({ copy }: { copy: Copy }) {
  const [plan, setPlan] = useState<Plan>("premium");
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<Status>({ kind: "idle" });
  const emailId = useId();
  const inputRef = useRef<HTMLInputElement>(null);

  const t = copy.form;
  const planWord = plan === "premium" ? t.premiumWord : t.freeWord;

  const cards: Array<{ id: Plan; card: Copy["plans"]["free"] }> = [
    { id: "free", card: copy.plans.free },
    { id: "premium", card: copy.plans.premium },
  ];

  function choose(next: Plan) {
    setPlan(next);
    if (status.kind !== "done") inputRef.current?.focus();
  }

  async function submit(event: React.FormEvent) {
    event.preventDefault();
    if (status.kind === "sending") return;
    setStatus({ kind: "sending" });

    try {
      const response = await fetch("/api/waitlist", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        // Езикът се записва заедно с имейла: показва дали българските или
        // англоезичните посетители се записват по-охотно, а това решава на
        // кой пазар да се насочи вниманието.
        body: JSON.stringify({ email, plan, lang: copy.lang }),
      });
      const data = (await response.json()) as { duplicate?: boolean; error?: string };

      if (!response.ok) {
        setStatus({ kind: "failed", message: data.error ?? t.errorGeneric });
        return;
      }
      setStatus({ kind: "done", duplicate: Boolean(data.duplicate) });
    } catch {
      setStatus({ kind: "failed", message: t.errorNetwork });
    }
  }

  return (
    <>
      <div className="plans">
        {cards.map(({ id, card }) => (
          <button
            key={id}
            type="button"
            className={`plan ${id}`}
            aria-pressed={plan === id}
            onClick={() => choose(id)}
          >
            <span className="plan-name">{card.name}</span>
            <span className="plan-price">
              {card.price}
              <small>{card.per}</small>
            </span>
            <ul>
              {card.features.map((feature) => (
                <li key={feature}>{feature}</li>
              ))}
            </ul>
            <span className="plan-pick">{card.pick}</span>
          </button>
        ))}
      </div>

      <form className="signup" onSubmit={submit}>
        {status.kind === "done" ? (
          <>
            <p className="notice good">
              {status.duplicate ? t.doneDuplicate : t.doneNew} {t.doneBody}
            </p>
            <p className="fineprint">
              {t.doneChoice} <strong style={{ color: "var(--pale)" }}>{planWord}</strong>. {t.doneFix}
            </p>
          </>
        ) : (
          <>
            <label htmlFor={emailId} className="fineprint">
              {t.chose} <strong style={{ color: "var(--pale)" }}>{planWord}</strong>. {t.prompt}
            </label>

            <div className="signup-row">
              <input
                id={emailId}
                ref={inputRef}
                type="email"
                name="email"
                inputMode="email"
                autoComplete="email"
                required
                placeholder={t.placeholder}
                value={email}
                onChange={(event) => setEmail(event.target.value)}
              />
              <button className="submit" type="submit" disabled={status.kind === "sending"}>
                {status.kind === "sending" ? t.sending : t.submit}
              </button>
            </div>

            {status.kind === "failed" && <p className="notice bad">{status.message}</p>}

            <p className="fineprint">{t.onlyEmail}</p>
          </>
        )}
      </form>
    </>
  );
}
