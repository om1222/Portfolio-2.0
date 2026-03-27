import "./styles/About.css";

const About = () => {
  return (
    <div className="about-section" id="about">
      <div className="about-me">
        <h3 className="title">About Me</h3>
        <p className="para">
          I'm Om Kumar — a B.Tech Mechanical Engineering student at IIT Delhi, turning data into strategy and user needs into products.
        </p>
        <p className="para">
          I believe the best products come from understanding people deeply — what I call "attunement." Before writing a PRD or building a dashboard, I ask: who is this really for, and what decision will it drive?
        </p>
        <p className="para">
          My journey spans product strategy at Kimbal (sizing a $350M market), growth hacking at Spilz (scaling users by 900% in a month), and building AI shopping assistants and analytics dashboards. At IIT Delhi, I led Infinity Hyperloop's chassis division, managed a ₹22.5 Lakh budget, and won Best Presenter at European Hyperloop Week in Zürich.
        </p>
        <p className="para">
          I approach every problem the same way: understand the human, find the insight, ship the solution.
        </p>
        <div className="about-skills">
          {[
            "Product Strategy", "Data Analytics", "SQL", "Python", "Power BI", "Tableau", 
            "Figma", "GTM Strategy", "User Research", "RICE Prioritization", "A/B Testing", 
            "Market Sizing", "Competitive Analysis", "Wireframing", "Dashboard Design", 
            "Agile/Scrum", "Excel/VBA", "Google Analytics", "n8n Workflows", "MATLAB"
          ].map((skill, index) => (
            <span key={index} className="skill-pill">{skill}</span>
          ))}
        </div>
      </div>
    </div>
  );
};

export default About;
