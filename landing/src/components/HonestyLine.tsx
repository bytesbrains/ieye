// The shared honest-promise line. Capability, never guarantee (#28/#40 §5).
// "iEye can save lives — not a substitute for emergency services."
// Kept as one component so the wording is consistent everywhere it appears.

export function HonestyLine({ className = "" }: { className?: string }) {
  return (
    <p className={`text-base text-charcoal-muted ${className}`}>
      iEye <span className="font-semibold text-charcoal">can</span> save a life when a life can be
      saved — it is <span className="font-semibold text-charcoal">not a substitute for emergency
      services</span>. And if it ever can&rsquo;t, no one is left undiscovered.
    </p>
  );
}
