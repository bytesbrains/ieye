import { Header } from "./components/Header";
import { Hero } from "./components/Hero";
import { Secure } from "./components/Secure";
import { Gap } from "./components/Gap";
import { HowItWorks } from "./components/HowItWorks";
import { Trust } from "./components/Trust";
import { BytesBrains } from "./components/BytesBrains";
import { Roadmap } from "./components/Roadmap";
import { OpenSource } from "./components/OpenSource";
import { Footer } from "./components/Footer";

export default function App() {
  return (
    <>
      {/* Skip link for keyboard / screen-reader users */}
      <a
        href="#main"
        className="sr-only focus:not-sr-only focus:absolute focus:left-4 focus:top-4 focus:z-[100] focus:rounded-md focus:bg-charcoal focus:px-4 focus:py-2 focus:text-paper"
      >
        Skip to content
      </a>

      <Header />

      <main id="main">
        {/* Front foot: iEye Secure (home security — value today, the funnel). */}
        <Hero />
        <Secure />
        {/* The deeper why: iEye Watch (welfare) — sequenced, never dropped. */}
        <Gap />
        <HowItWorks />
        <Trust />
        {/* The commercial layer that funds the mission. */}
        <BytesBrains />
        <Roadmap />
        <OpenSource />
      </main>

      <Footer />
    </>
  );
}
