export type Plan = "free" | "premium";

export type WaitlistEntry = {
  email: string;
  plan: Plan;
  /** Езикът на страницата, от която е дошъл записът. */
  lang: string;
  country: string | null;
  referrer: string | null;
  user_agent: string | null;
};

export type SaveResult =
  | { ok: true; duplicate: boolean }
  | { ok: false; reason: "not_configured" | "upstream"; detail: string };

/**
 * Записва един ред в таблицата waitlist през REST интерфейса на Supabase.
 *
 * Нарочно без клиентската библиотека на Supabase: една вмъкната заявка не
 * оправдава още една зависимост, а така се вижда точно какво се изпраща.
 */
export async function saveEntry(entry: WaitlistEntry): Promise<SaveResult> {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !key) {
    return {
      ok: false,
      reason: "not_configured",
      detail:
        "Липсват NEXT_PUBLIC_SUPABASE_URL или SUPABASE_SERVICE_ROLE_KEY. Виж web/README.md.",
    };
  }

  let response: Response;
  try {
    response = await fetch(`${url}/rest/v1/waitlist`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: key,
        Authorization: `Bearer ${key}`,
        Prefer: "return=minimal",
      },
      body: JSON.stringify(entry),
      cache: "no-store",
    });
  } catch (error) {
    return {
      ok: false,
      reason: "upstream",
      detail: error instanceof Error ? error.message : "Няма връзка със Supabase.",
    };
  }

  if (response.ok) return { ok: true, duplicate: false };

  const body = await response.text();

  // 23505 = нарушен уникален индекс, тоест имейлът вече е в списъка.
  // Това не е грешка за човека отсреща — той е записан.
  if (response.status === 409 || body.includes("23505")) {
    return { ok: true, duplicate: true };
  }

  return { ok: false, reason: "upstream", detail: `${response.status} ${body}` };
}

/**
 * Съзнателно е по-хлабава от пълния стандарт: целта е да улови печатни
 * грешки, не да отсъди кои адреси са валидни. Истинската проверка е дали
 * писмото стига.
 */
export function looksLikeEmail(value: string): boolean {
  const trimmed = value.trim();
  if (trimmed.length < 6 || trimmed.length > 254) return false;
  if (/\s/.test(trimmed)) return false;
  const at = trimmed.indexOf("@");
  if (at < 1 || at !== trimmed.lastIndexOf("@")) return false;
  const domain = trimmed.slice(at + 1);
  return domain.includes(".") && !domain.startsWith(".") && !domain.endsWith(".");
}
