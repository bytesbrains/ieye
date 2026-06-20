import type { ReactNode } from "react";
import { useReveal } from "../lib/useReveal";

interface SectionProps {
  id?: string;
  className?: string;
  children: ReactNode;
  /** aria-labelledby target id for the section heading */
  labelledBy?: string;
}

export function Section({ id, className = "", children, labelledBy }: SectionProps) {
  const { ref, shown } = useReveal<HTMLElement>();
  return (
    <section
      id={id}
      ref={ref}
      aria-labelledby={labelledBy}
      className={`section ${shown ? "motion-safe:animate-fade-up" : "motion-safe:opacity-0"} ${className}`}
    >
      {children}
    </section>
  );
}
