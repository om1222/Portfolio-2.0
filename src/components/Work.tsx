import "./styles/Work.css";
import WorkImage from "./WorkImage";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { useGSAP } from "@gsap/react";

gsap.registerPlugin(useGSAP, ScrollTrigger);

const Work = () => {
  useGSAP(() => {
    let container = document.querySelector(".work-flex") as HTMLElement;
    let boxes = gsap.utils.toArray(".work-box") as HTMLElement[];
    
    const getScrollAmount = () => {
      if (!container || boxes.length === 0) return 0;
      // Calculate total width explicitly from all boxes
      let totalWidth = 0;
      boxes.forEach(box => totalWidth += box.offsetWidth);
      
      let paddingOffset = window.innerWidth > 1024 ? 300 : 150; 
      return Math.max(0, totalWidth - window.innerWidth + paddingOffset);
    };

    let scrollTween = gsap.to(container, {
      x: () => -getScrollAmount(),
      ease: "none",
      scrollTrigger: {
        trigger: ".work-section",
        pin: true,
        scrub: 1,
        start: "top top",
        end: () => `+=${getScrollAmount()}`,
        invalidateOnRefresh: true,
      }
    });

    // Force refresh ScrollTrigger after a short delay in case of late image loads
    let timeoutId = setTimeout(() => {
      ScrollTrigger.refresh();
    }, 1500);

    return () => {
      clearTimeout(timeoutId);
      scrollTween.kill();
    };
  }, []);
  return (
    <div className="work-section" id="work">
      <div className="work-container section-container">
        <h2>
          My <span>Work</span>
        </h2>
        <div className="work-flex">
          {[
            { id: "netflix-analytics", name: "Netflix Content Analytics", category: "Product Analytics", tools: "MySQL, Power BI, DAX", img: "/images/netflix-n-seeklogo.png", dashboardUrl: "/netflix.html" },
            { id: "blinkit-eda", name: "Blinkit Retail EDA", category: "Data Analysis", tools: "Python, Pandas, Matplotlib", img: "/images/blinkit-seeklogo.png", dashboardUrl: "/blinkit.html" },
            { id: "uber-analytics", name: "Uber Ride Analytics", category: "Data Analytics", tools: "Python, SQL, Tableau", img: "/images/uber-seeklogo.png", dashboardUrl: "/uber.html" },
            { id: "bank-loan", name: "Bank Loan Dashboard", category: "Financial Analysis", tools: "SQL, Power BI, Excel", img: "/images/bank-seeklogo.png", dashboardUrl: "/bank.html" },
            { id: "nayaa-assistant", name: "Nayaa AI Shopping Assistant", category: "Product Development", tools: "OpenAI, n8n, Prompt Engineering", img: "/images/Nayaa.png" },
            { id: "matchup-recruitment", name: "MatchUp Marketplace", category: "Product Strategy", tools: "Figma, Blue Ocean, SWOT", img: "/images/MatchUp.png" }
          ].map((project, index) => (
            <div className="work-box" key={index} onClick={() => window.location.href = `/projects/${project.id}`} style={{ cursor: 'pointer' }}>
              <div className="work-info">
                <div className="work-title">
                  <h3>0{index + 1}</h3>

                  <div className="work-project-title-container">
                    <h4 className="work-project-name">{project.name}</h4>
                    <p className="work-project-category">{project.category}</p>
                  </div>
                </div>
                <div className="work-tools-container">
                  <h5 className="work-tools-heading">Tools & features</h5>
                  <p className="work-tools-list">{project.tools}</p>
                </div>
                {project.dashboardUrl && (
                  <button 
                    className="view-dashboard-btn" 
                    onClick={(e) => {
                      e.stopPropagation();
                      window.open(project.dashboardUrl, '_blank');
                    }}
                  >
                    View Project
                  </button>
                )}
              </div>
              {/* Fallback to placeholder if image not found initially, we can add images later */}
              <WorkImage image={project.img} alt={project.name} />
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default Work;
