import type { Metadata, Viewport } from "next";
import { Bodoni_Moda, Hanken_Grotesk, Spline_Sans_Mono } from "next/font/google";
import { notFound } from "next/navigation";
import { COPY, type Lang } from "@/lib/copy";
import "../globals.css";

const display = Bodoni_Moda({
  subsets: ["latin", "latin-ext"],
  weight: ["500", "700"],
  style: ["normal", "italic"],
  variable: "--font-display",
  display: "swap",
});

const ui = Hanken_Grotesk({
  subsets: ["latin", "latin-ext"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-ui",
  display: "swap",
});

const mono = Spline_Sans_Mono({
  subsets: ["latin", "latin-ext"],
  weight: ["400", "500"],
  variable: "--font-mono",
  display: "swap",
});

export function generateStaticParams() {
  return [{ lang: "bg" }, { lang: "en" }];
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ lang: string }>;
}): Promise<Metadata> {
  const { lang } = await params;
  const copy = COPY[lang as Lang];
  if (!copy) return {};

  return {
    metadataBase: new URL("https://invexa.app"),
    title: copy.title,
    description: copy.description,
    // Казва на търсачките, че двете страници са една и съща на два езика —
    // иначе се броят като дублирано съдържание.
    alternates: {
      canonical: `/${lang}`,
      languages: { bg: "/bg", en: "/en" },
    },
    openGraph: {
      title: copy.title,
      description: copy.description,
      locale: lang === "bg" ? "bg_BG" : "en",
      type: "website",
    },
    robots: { index: true, follow: true },
  };
}

export const viewport: Viewport = {
  themeColor: "#0A0F1F",
  colorScheme: "dark",
};

export default async function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ lang: string }>;
}) {
  const { lang } = await params;
  if (!COPY[lang as Lang]) notFound();

  return (
    <html lang={lang} className={`${display.variable} ${ui.variable} ${mono.variable}`}>
      <body>
        <div className="field" aria-hidden="true" />
        {children}
      </body>
    </html>
  );
}
