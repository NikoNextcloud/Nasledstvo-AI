import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "НАСЛЕДСТВО AI — дигитален архив на семейната история" },
      { name: "description", content: "Пазете снимки, разкази, документи и семейното дърво на едно сигурно място." },
      { property: "og:title", content: "НАСЛЕДСТВО AI" },
      { property: "og:description", content: "Дигитален архив на семейната история." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: Index,
});

type Product = { id: string; name: string; description: string | null; price_cents: number; discount_percent: number; interval: string | null; kind: string; features: string[] };

const eur = (c: number) => (c / 100).toLocaleString("bg-BG", { style: "currency", currency: "EUR" });

function Index() {
  const [products, setProducts] = useState<Product[] | null>(null);
  useEffect(() => {
    supabase.from("products").select("*").eq("active", true).order("position").then(({ data }) => setProducts((data as Product[]) ?? []));
  }, []);
  return (
    <main className="min-h-screen bg-background text-foreground">
      <section className="mx-auto max-w-4xl px-6 py-24 text-center">
        <p className="text-sm uppercase tracking-widest text-muted-foreground">Наследство AI</p>
        <h1 className="mt-4 font-serif text-4xl md:text-6xl">Историята на вашето семейство, запазена за поколенията</h1>
        <p className="mt-6 text-lg text-muted-foreground">Снимки, разкази, писма и родословно дърво — в личен, защитен архив.</p>
      </section>
      <section className="mx-auto max-w-5xl px-6 pb-24">
        <h2 className="mb-8 text-center font-serif text-3xl">Тарифи</h2>
        {products === null ? <p className="text-center text-muted-foreground">Зареждане…</p> : (
          <div className="grid gap-6 md:grid-cols-3">
            {products.map((p) => {
              const final = Math.round(p.price_cents * (100 - p.discount_percent) / 100);
              return (
                <div key={p.id} className="rounded-lg border bg-card p-6">
                  <h3 className="font-serif text-xl">{p.name}</h3>
                  <p className="mt-2 text-sm text-muted-foreground">{p.description}</p>
                  <p className="mt-4 text-3xl">{p.kind === "book" ? "от " : ""}{eur(final)}{p.interval === "month" ? " / месец" : ""}</p>
                  <ul className="mt-4 space-y-1 text-sm">{p.features.map((f) => <li key={f}>• {f}</li>)}</ul>
                </div>
              );
            })}
          </div>
        )}
        <p className="mt-8 text-center text-sm text-muted-foreground">Плащанията все още не са активирани.</p>
      </section>
    </main>
  );
}