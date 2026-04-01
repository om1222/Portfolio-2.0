import "./styles/Career.css";

const Achievements = () => {
  return (
    <div className="career-section section-container" id="achievements">
      <div className="career-container">
        <h2>
          Key <span>Achievements</span>
        </h2>
        <div className="career-info">
          <div className="career-timeline">
            <div className="career-dot" style={{ background: '#c481ff' }}></div>
          </div>
          
          <div className="career-info-box">
            <div className="career-info-in">
              <div className="career-role">
                <h4>Best Presenter & Qualifier</h4>
                <h5>European Hyperloop Week, Zürich</h5>
              </div>
              <h3>2024</h3>
            </div>
            <p>
              Won Best Presenter among 400+ students globally for pitching thermal solutions. Qualified for Würth Elektronik Thermal Workshop, solving battery challenges alongside 25+ international teams. Represented India & IIT Delhi, improving design efficiency by 15%.
            </p>
          </div>

          <div className="career-info-box">
            <div className="career-info-in">
              <div className="career-role">
                <h4>SQL (Intermediate)</h4>
                <h5>HackerRank Certification</h5>
              </div>
              <h3>2024</h3>
            </div>
            <p>
              Certified in SQL (Intermediate), demonstrating proficiency in complex queries, joins, and data manipulation. Successfully solved advanced data retrieval and management challenges.
            </p>
          </div>

          <div className="career-info-box">
            <div className="career-info-in">
              <div className="career-role">
                <h4>Generative AI Masterminds</h4>
                <h5>GrowthSchool Certification</h5>
              </div>
              <h3>2023</h3>
            </div>
            <p>
              Certified in Generative AI, covering advanced prompt engineering, automation workflows, and real-world AI use cases strategy and execution.
            </p>
          </div>

          <div className="career-info-box">
            <div className="career-info-in">
              <div className="career-role">
                <h4>Chassis Junior Engineer</h4>
                <h5>Infinity Hyperloop</h5>
              </div>
              <h3>2023 - 2024</h3>
            </div>
            <p>
              Designed and tested chassis components boosting performance by 20%. Managed a ₹22.5 Lakh budget and co-led the recruitment of 200+ freshers for the team.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Achievements;
