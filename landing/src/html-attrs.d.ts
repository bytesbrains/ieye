// Type the lowercase `fetchpriority` HTML attribute on <img>. React 18 emits the
// lowercase form to the DOM, but @types/react only ships the camelCase
// `fetchPriority`. This augmentation lets us write `fetchpriority="high"`
// directly — type-checked, no untyped cast. (Removable once on React 19, whose
// camelCase fetchPriority maps correctly.)
import "react";

declare module "react" {
  interface ImgHTMLAttributes<T> {
    fetchpriority?: "high" | "low" | "auto";
  }
}
