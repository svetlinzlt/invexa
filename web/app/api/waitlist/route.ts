import { NextResponse } from "next/server";
import { looksLikeEmail, saveEntry, type Plan } from "@/lib/waitlist";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

function truncate(value: string | null, max: number): string | null {
  if (!value) return null;
  return value.length > max ? value.slice(0, max) : value;
}

export async function POST(request: Request) {
  let payload: unknown;
  try {
    payload = await request.json();
  } catch {
    return NextResponse.json(
      { error: "Заявката не е валиден JSON." },
      { status: 400 },
    );
  }

  const body = payload as { email?: unknown; plan?: unknown; lang?: unknown };
  const email = typeof body.email === "string" ? body.email.trim() : "";
  const plan: Plan = body.plan === "premium" ? "premium" : "free";
  const lang = body.lang === "en" ? "en" : "bg";

  if (!looksLikeEmail(email)) {
    return NextResponse.json(
      { error: "Този адрес не изглежда пълен. Провери го и опитай пак." },
      { status: 400 },
    );
  }

  const headers = request.headers;

  const result = await saveEntry({
    email,
    plan,
    lang,
    // Vercel слага държавата на всяка заявка. Локално я няма и остава празна.
    country: headers.get("x-vercel-ip-country"),
    referrer: truncate(headers.get("referer"), 500),
    user_agent: truncate(headers.get("user-agent"), 500),
  });

  if (!result.ok) {
    // Причината отива в лога за теб, не към човека отсреща.
    console.error("[waitlist]", result.reason, result.detail);
    return NextResponse.json(
      {
        error:
          "Записът не мина. Опитай пак след минута или ми пиши на hello@invexa.app.",
      },
      { status: 502 },
    );
  }

  return NextResponse.json({ ok: true, duplicate: result.duplicate });
}
