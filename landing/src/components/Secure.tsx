import { Link } from "react-router-dom";
import { Section } from "./Section";

// iEye Secure — the front-foot capability. Finds what's exposed in a home
// network. Same guardian promise (protect you FROM being watched), pointed at a
// threat people can feel today. On-device, passive, never signs in.
export function Secure() {
  return (
    <Section id="secure" labelledBy="secure-heading">
      <div className="container-wide">
        <div className="container-prose px-0">
          <p className="mb-3 text-sm font-semibold uppercase tracking-wide text-teal-deep">
            iEye Secure — check your home today
          </p>
          <h2 id="secure-heading" className="text-3xl font-semibold sm:text-4xl">
            See what a stranger could reach in your home.
          </h2>
          <p className="mt-5 text-lg leading-relaxed text-charcoal-soft">
            Cheap cameras and smart gadgets often ship wide open — a blank password, a cloud feature
            that quietly makes them viewable from the internet. iEye looks at the devices on your
            Wi-Fi and tells you, in two taps, what&rsquo;s exposed — and how to close it.
          </p>
        </div>

        <div className="mt-12 grid gap-6 md:grid-cols-3">
          {[
            {
              t: "Finds exposed cameras & devices",
              d: "It spots the camera family behind the big botnets, and flags the ones a stranger could likely reach from the internet.",
            },
            {
              t: "Checks your Wi-Fi",
              d: "Open or weakly-encrypted Wi-Fi lets anyone nearby onto your network. iEye reads the encryption and says so plainly.",
            },
            {
              t: "Plain fixes — or expert help",
              d: "Most findings you can fix yourself with a step-by-step. For the hard ones, BytesBrains can secure it for you.",
            },
          ].map((c) => (
            <div key={c.t} className="rounded-2xl border-2 border-charcoal/10 bg-paper-dim p-7">
              <p className="text-lg font-semibold text-charcoal">{c.t}</p>
              <p className="mt-2 text-base leading-relaxed text-charcoal-soft">{c.d}</p>
            </div>
          ))}
        </div>

        <div className="mt-10 flex flex-wrap items-center gap-4">
          <Link to="/app" className="btn btn-primary">
            Scan your home
          </Link>
          <a href="#bytesbrains" className="btn btn-secondary">
            Get it secured
          </a>
        </div>

        <p className="container-prose mt-6 px-0 text-base text-charcoal-muted">
          The scan runs on your own device and reads only what each gadget volunteers — it{" "}
          <span className="font-medium text-charcoal-soft">never signs in to anything</span>, nothing
          it finds leaves your phone, and it can&rsquo;t promise your home is safe. It shows you
          what&rsquo;s worth fixing.
        </p>
      </div>
    </Section>
  );
}
