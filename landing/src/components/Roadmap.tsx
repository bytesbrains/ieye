import { Section } from "./Section";
import { HonestyLine } from "./HonestyLine";

// Where iEye is going (#61, content from #60). The thesis: more senses, never
// more surveillance — each tier buys a *specific* precision/latency win, and the
// plan needs capex spent honestly. Glyphs are abstract palette-only SVG (no
// camera / eye / lens / human / red, ever); the lighthouse stays reserved for the
// brand hero, so Tier-3 uses a concentric-care pebble instead.

// Phone (floor / today): device outline + one soft teal presence-ripple arc.
function PhoneGlyph() {
  return (
    <svg viewBox="0 0 48 48" className="h-10 w-10" aria-hidden="true">
      <rect x="16" y="6" width="16" height="30" rx="3" className="fill-none stroke-teal-deep" strokeWidth="2.5" />
      <path d="M30 38 a8 8 0 0 1 8 0" className="fill-none stroke-teal-deep/60" strokeWidth="2.5" strokeLinecap="round" />
      <path d="M28 42 a12 12 0 0 1 14 0" className="fill-none stroke-teal-deep/30" strokeWidth="2.5" strokeLinecap="round" />
    </svg>
  );
}

// Tier 1 (home): roofline with receding presence-dots inside (reuses SlowGlyph
// opacities) = "a home is lived-in" without seeing inside it.
function HomeGlyph() {
  return (
    <svg viewBox="0 0 48 48" className="h-10 w-10" aria-hidden="true">
      <path d="M8 22 L24 8 L40 22 V42 H8 Z" className="fill-none stroke-teal-deep" strokeWidth="2.5" strokeLinejoin="round" />
      <circle cx="17" cy="32" r="2.5" className="fill-teal-deep" />
      <circle cx="24" cy="32" r="2.5" className="fill-teal-deep/70" />
      <circle cx="31" cy="32" r="2.5" className="fill-teal-deep/40" />
    </svg>
  );
}

// Tier 2 (wrist): band + a single short pulse tick, with one amber accent —
// the "can save a life" tier.
function WristGlyph() {
  return (
    <svg viewBox="0 0 48 48" className="h-10 w-10" aria-hidden="true">
      <rect x="14" y="14" width="20" height="20" rx="5" className="fill-none stroke-teal-deep" strokeWidth="2.5" />
      <path d="M20 4 h8 l-1 9 h-6 Z" className="fill-teal-deep/40" />
      <path d="M20 44 h8 l-1 -9 h-6 Z" className="fill-teal-deep/40" />
      <path d="M16 24 h4 l3 -5 l3 10 l2 -5 h4" className="fill-none stroke-amber-deep" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

// Tier 3 (purpose-built): a bedside pebble with concentric arcs radiating into
// the room — contactless-as-care. Lighthouse stays reserved for the hero.
function HubGlyph() {
  return (
    <svg viewBox="0 0 48 48" className="h-10 w-10" aria-hidden="true">
      <ellipse cx="24" cy="38" rx="9" ry="5" className="fill-teal-deep" />
      <path d="M14 28 a14 14 0 0 1 20 0" className="fill-none stroke-teal-deep/60" strokeWidth="2.5" strokeLinecap="round" />
      <path d="M10 22 a20 20 0 0 1 28 0" className="fill-none stroke-teal-deep/30" strokeWidth="2.5" strokeLinecap="round" />
    </svg>
  );
}

// Invisible layer: a gentle rhythm waveform (not a clock / grid / calendar —
// rhythm, never a profile).
function RhythmGlyph() {
  return (
    <svg viewBox="0 0 48 48" className="h-10 w-10" aria-hidden="true">
      <path
        d="M4 24 q5 -14 10 0 t10 0 t10 0 t10 0"
        className="fill-none stroke-teal-deep"
        strokeWidth="2.5"
        strokeLinecap="round"
      />
    </svg>
  );
}

type TierState = "Here today" | "Next" | "Later";

interface Tier {
  label: string;
  state: TierState;
  glyph: () => JSX.Element;
  what: string;
  payoff: string;
}

const TIERS: Tier[] = [
  {
    label: "The phone in your pocket",
    state: "Here today",
    glyph: PhoneGlyph,
    what:
      "iEye starts with the phone someone already carries — no purchase, nothing to wear, nothing to remember. It quietly learns the rhythm of an ordinary day and feels when that rhythm goes quiet.",
    payoff:
      "The payoff: weeks of going unnoticed become hours — starting today, with nothing to buy.",
  },
  {
    label: "Quiet helpers around the home",
    state: "Next",
    glyph: HomeGlyph,
    what:
      "Small everyday signs that life is carrying on: a kettle switched on, a hallway light, a ripple in the Wi-Fi as someone crosses the room. These are presence senses — no camera, no microphone, nothing identifiable. They can tell a home is lived-in without ever seeing inside it. So when the phone dies, iEye doesn’t panic — because the home is still alive.",
    payoff:
      "The payoff: far fewer false alarms, because the most common false alert of all — a flat battery — gets quietly ruled out.",
  },
  {
    label: "The helper on your wrist",
    state: "Next",
    glyph: WristGlyph,
    what:
      "A watch can feel for a steady pulse of life — and tell resting from unresponsive, so it lets you sleep and only acts when something’s truly wrong. Optional, opt-in, and the strongest watching-over iEye can offer.",
    payoff:
      "The payoff: a hard fall is noticed the moment it happens — help in minutes instead of hours.",
  },
  {
    label: "A purpose-built guardian",
    state: "Later",
    glyph: HubGlyph,
    what:
      "One day, a calm device made for this: a quiet light in the home that watches over the room and never records it — no wearable to charge, nothing to remember, nothing for the person to do. The lighthouse, made real.",
    payoff: "If it ever has a camera, it isn’t iEye.",
  },
];

// State pills carry the meaning in TEXT (color is never the only signal).
function statePillClasses(state: TierState): string {
  return state === "Here today"
    ? "border-amber-deep/40 text-amber-deep"
    : "border-charcoal/20 text-charcoal-muted";
}
function dotClasses(state: TierState): string {
  return state === "Here today"
    ? "border-amber-deep bg-amber-deep"
    : "border-charcoal/30 bg-paper";
}

export function Roadmap() {
  return (
    <Section id="roadmap" labelledBy="roadmap-heading">
      <div className="container-wide">
        <div className="container-prose px-0">
          <p className="mb-3 text-sm font-semibold uppercase tracking-wide text-teal-deep">
            Where iEye is going
          </p>
          <h2 id="roadmap-heading" className="text-3xl font-semibold sm:text-4xl">
            More senses. Never less privacy.
          </h2>
          <p className="mt-5 text-lg leading-relaxed text-charcoal-soft">
            Today iEye watches over someone through a single phone — enough to turn weeks into hours,
            but a phone can be in another room, or dead at 2%. Here&rsquo;s how we make the sign of
            life dependable: a quiet mesh of helpers, each answering one question —{" "}
            <em>is there a sign of life?</em> — and forgetting everything else.
          </p>
        </div>

        {/* The ladder — ordered and cumulative (phone → home → wrist → purpose-
            built), on a presence-spine. One calm section fade only (Section);
            no per-card stagger, so prefers-reduced-motion is fully honored. */}
        <div className="relative mt-12">
          {/* presence-spine behind the cards — decorative, and kept OUTSIDE the
              <ul> so the list has only <li> children (valid list semantics). */}
          <span aria-hidden="true" className="absolute left-[7px] top-6 bottom-6 w-0.5 bg-charcoal/10" />
          <ul role="list" className="space-y-6">
          {TIERS.map((tier) => {
            const Glyph = tier.glyph;
            return (
              <li key={tier.label} className="relative pl-10">
                {/* spine dot — amber + filled for "here today", hollow for future */}
                <span
                  aria-hidden="true"
                  className={`absolute left-[1px] top-8 h-3.5 w-3.5 rounded-full border-2 ${dotClasses(tier.state)}`}
                />
                <div className="rounded-2xl border-2 border-charcoal/10 bg-paper-dim p-7 sm:p-8">
                  <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:gap-6">
                    <div className="flex items-center gap-3 sm:w-48 sm:shrink-0 sm:flex-col sm:items-start sm:gap-3">
                      <Glyph />
                      <div>
                        <span
                          className={`inline-block rounded-full border px-2.5 py-0.5 text-xs font-semibold uppercase tracking-wide ${statePillClasses(tier.state)}`}
                        >
                          {tier.state}
                        </span>
                        <h3 className="mt-2 text-xl font-semibold text-charcoal">{tier.label}</h3>
                      </div>
                    </div>
                    <div className="flex-1">
                      <p className="text-base leading-relaxed text-charcoal-soft">{tier.what}</p>
                      <p className="mt-3 text-base font-medium text-charcoal">{tier.payoff}</p>
                    </div>
                  </div>
                </div>
              </li>
            );
          })}
          </ul>
        </div>

        {/* The invisible layer — learning + rehearsal. A calmer full-width band,
            not a device card (it isn't a sensor). */}
        <div className="mt-6 rounded-2xl border-2 border-teal/30 bg-teal/5 p-7 sm:p-8">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:gap-6">
            <RhythmGlyph />
            <div>
              <h3 className="text-xl font-semibold text-charcoal">
                Underneath it all — it learns your rhythm, and rehearses the emergency
              </h3>
              <p className="mt-3 text-base leading-relaxed text-charcoal-soft">
                iEye learns your normal <em>rhythm</em> — so it can feel when the rhythm breaks. That
                learning stays on your device, always. And we make iEye more precise the honest way:
                it <strong className="font-semibold text-charcoal">rehearses emergencies in software
                so it never has to learn them on you.</strong> We get sharper by practising harder —
                never by watching you more closely.
              </p>
            </div>
          </div>
        </div>

        {/* Why it costs money — the load-bearing link between the roadmap and the
            ask. A quiet three-part band, never a fundraising thermometer. */}
        <div className="container-prose mt-10 px-0">
          <p className="mb-3 text-sm font-semibold uppercase tracking-wide text-charcoal-muted">
            Why it costs money
          </p>
          <div className="grid gap-4 sm:grid-cols-3">
            <div className="rounded-2xl border-2 border-charcoal/10 bg-paper p-5">
              <p className="text-base font-semibold text-charcoal">Hardware buys signal</p>
              <p className="mt-2 text-sm leading-relaxed text-charcoal-soft">
                More independent senses, so a dead phone doesn&rsquo;t blind us.
              </p>
            </div>
            <div className="rounded-2xl border-2 border-charcoal/10 bg-paper p-5">
              <p className="text-base font-semibold text-charcoal">The model buys precision</p>
              <p className="mt-2 text-sm leading-relaxed text-charcoal-soft">
                Learning <em>your</em> rhythm is the biggest lever on false alarms.
              </p>
            </div>
            <div className="rounded-2xl border-2 border-charcoal/10 bg-paper p-5">
              <p className="text-base font-semibold text-charcoal">Simulation buys safe iteration</p>
              <p className="mt-2 text-sm leading-relaxed text-charcoal-soft">
                We can&rsquo;t ethically wait for someone to fall to test fall detection — so we
                rehearse it instead.
              </p>
            </div>
          </div>
          <HonestyLine className="mt-6" />
        </div>
      </div>
    </Section>
  );
}
