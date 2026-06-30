import { Header } from "./components/Header";
import { Hero } from "./components/Hero";
import { Gap } from "./components/Gap";
import { HowItWorks } from "./components/HowItWorks";
import { Trust } from "./components/Trust";
import { Roadmap } from "./components/Roadmap";
import { Contribute } from "./components/Contribute";
import { SupporterWall } from "./components/SupporterWall";
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
        <Hero />
        <Gap />
        <HowItWorks />
        <Trust />
        <Roadmap />
        <Contribute />
        <SupporterWall />
      </main>

      <Footer />
    </>
  );
}
