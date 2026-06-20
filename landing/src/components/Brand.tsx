// Brand primitives: the lighthouse mark and the small "i = lighthouse" wordmark.
// Lighthouse / beacon only — never a camera lens or staring eye (brand guardrail).

export function LighthouseMark({ className = "" }: { className?: string }) {
  // Simplified charcoal tower with an amber lamp as the dot of a lowercase "i".
  return (
    <svg
      viewBox="0 0 48 64"
      className={className}
      role="img"
      aria-label="iEye lighthouse mark"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      {/* amber lamp = the dot of the "i" */}
      <circle cx="24" cy="9" r="6.5" className="fill-amber" />
      {/* lantern housing */}
      <path d="M16 20 L24 15 L32 20 Z" className="fill-charcoal" />
      <rect x="18" y="20" width="12" height="6" rx="1" className="fill-charcoal" />
      {/* tapered tower = the stem of the "i" */}
      <path d="M19 26 L29 26 L31 54 L17 54 Z" className="fill-charcoal" />
      {/* base */}
      <rect x="14" y="54" width="20" height="5" rx="1.5" className="fill-charcoal" />
    </svg>
  );
}

export function Wordmark({ className = "" }: { className?: string }) {
  return (
    <span className={`inline-flex items-center gap-2 ${className}`}>
      <LighthouseMark className="h-7 w-auto" />
      <span className="font-serif text-2xl font-semibold tracking-tight text-charcoal">
        i<span className="text-charcoal">Eye</span>
      </span>
    </span>
  );
}
