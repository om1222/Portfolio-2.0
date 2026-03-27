import "./styles/Career.css";

const Career = () => {
  return (
    <div className="career-section section-container" id="experience">
      <div className="career-container">
        <h2>
          Professional <span>&</span>
          <br /> Experience
        </h2>
        <div className="career-info">
          <div className="career-timeline">
            <div className="career-dot" style={{ background: '#c481ff' }}></div>
          </div>
          <div className="career-info-box">
            <div className="career-info-in">
              <div className="career-role">
                <h4>Product Management Intern</h4>
                <h5>Kimbal</h5>
              </div>
              <h3>2025</h3>
            </div>
            <p>
              Sized the Australian Total Addressable Market at USD 350M for Smart Meters. Benchmarked 10+ competitors across pricing, features, and partnerships. Identified critical differentiation gaps and drafted a comprehensive GTM playbook and product roadmap.
            </p>
          </div>
          <div className="career-info-box">
            <div className="career-info-in">
              <div className="career-role">
                <h4>Founder's Office Intern</h4>
                <h5>Spilz</h5>
              </div>
              <h3>2023</h3>
            </div>
            <p>
              Increased the user base by 900% within a single month through strategic growth campaigns. Spearheaded campaigns that drove significant user engagement and retention improvements, gaining hands-on startup operations experience.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Career;
