import { PropsWithChildren } from "react";
import "./styles/Landing.css";
import { smoother } from "./Navbar";

const Landing = ({ children }: PropsWithChildren) => {
  const handleNavClick = (e: React.MouseEvent<HTMLAnchorElement>, target: string) => {
    e.preventDefault();
    try {
      if (window.innerWidth > 1024 && smoother) {
        smoother.scrollTo(target, true, "top top");
        return;
      }
    } catch (err) {
      console.warn("GSAP ScrollSmoother bypassed", err);
    }
    
    // Fallback native scroll (works perfectly on mobile and when GSAP is disabled)
    const el = document.querySelector(target);
    if (el) {
      el.scrollIntoView({ behavior: "smooth" });
    } else {
      window.location.hash = target;
    }
  };

  return (
    <>
      <div className="landing-section" id="landingDiv">
        <div className="landing-container">
          <div className="landing-intro">
            <h2>Hello! I'm</h2>
            <h1>
              OM
              <br />
              <span>KUMAR</span>
              <div className="landing-iit">IIT DELHI</div>
            </h1>
          </div>
          <div className="landing-info">
            <h3>Product Manager &</h3>
            <h2 className="landing-info-h2">
              <div className="landing-h2-1">Data Analyst</div>
              <div className="landing-h2-2">Strategist</div>
            </h2>
            <h2>
              <div className="landing-h2-info">Strategist</div>
              <div className="landing-h2-info-1">Data Analyst</div>
            </h2>
            <div className="landing-tagline">
              <p>"Every product is a pitch. Every dashboard tells a story. I find the signal in the noise — then I build what people didn't know they needed."</p>
            </div>
            <div className="landing-cta-buttons">
              <a href="#work" data-cursor="pointer" onClick={(e) => handleNavClick(e, "#work")}>View My Work</a>
              <a href="#contact" data-cursor="pointer" onClick={(e) => handleNavClick(e, "#contact")}>Let's Connect</a>
            </div>
          </div>
        </div>
        {children}
      </div>
    </>
  );
};

export default Landing;
