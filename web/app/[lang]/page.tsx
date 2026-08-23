import { notFound } from "next/navigation";
import Landing from "@/components/Landing";
import { COPY, type Lang } from "@/lib/copy";

export function generateStaticParams() {
  return [{ lang: "bg" }, { lang: "en" }];
}

export default async function LocalePage({
  params,
}: {
  params: Promise<{ lang: string }>;
}) {
  const { lang } = await params;
  const copy = COPY[lang as Lang];
  if (!copy) notFound();

  return <Landing copy={copy} />;
}
