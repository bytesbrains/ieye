// Calm, reduced-motion-aware loading spinner. No alarm colors.

export function Spinner({ className = "" }: { className?: string }) {
  return (
    <span
      role="status"
      aria-label="Loading"
      className={`inline-block h-6 w-6 animate-spin rounded-full border-[3px] border-charcoal/20 border-t-amber-deep motion-reduce:animate-none ${className}`}
    />
  );
}
