import { useParams, Link } from "react-router-dom";
import { useEffect, useState } from "react";
import "./ProjectDetail.css";
import { FaArrowLeft } from "react-icons/fa6";

const projectData: Record<string, any> = {
  "netflix-analytics": {
    name: "Netflix Content Analytics",
    category: "Product Analytics",
    timeline: "May 2025 – Jun 2025",
    description: "A comprehensive analytics dashboard analyzing 7,000+ titles across 190+ countries to surface content strategy insights.",
    built: "Analyzed Netflix's 7,000+ content catalog in MySQL with 15+ advanced queries extracting insights on genre mix, release trends, and content gaps. Built a Power BI dashboard with DAX featuring 4 interactive visualizations and KPIs enabling real-time insights across 190+ countries.",
    impact: [
      "Enabled cross-filtering & drill-down analytics, reducing data retrieval time by ~60%",
      "Surfaced opportunities to optimize content strategy across regions",
      "Fixed regional catalog inconsistencies via SQL and DAX, boosting geo-insight accuracy by 35%"
    ],
    tools: "MySQL, Power BI, DAX, SQL",
    proofText: "The SQL queries, Power BI dashboards, datasets, and screenshots are available in the Netflix/ folder.",
    link: "/projects-data/Netflix/index.html"
  },
  "blinkit-eda": {
    name: "Blinkit Retail Performance & Customer Insights",
    category: "Exploratory Data Analysis",
    timeline: "Mar 2025 – Apr 2025",
    description: "Deep-dive analysis of 8,500+ Blinkit sales records uncovering customer preferences and shaping inventory strategy.",
    built: "Cleaned & standardized 8,500+ sales records in Python, resolving categorical inconsistencies. Computed 4 KPIs ($1.2M total sales, $141 avg. order value, 4.0/5 avg. rating). Developed 6+ visualizations analyzing sales by product, location, and establishment year.",
    impact: [
      "Low Fat products accounted for 65% of sales — a finding that directly shaped inventory and marketing strategy recommendations."
    ],
    tools: "Python, Pandas, Matplotlib, Data Cleaning",
    proofText: "The Python notebooks, cleaned datasets, visualizations, and analysis outputs are available in the blinkit-retail-eda/ folder.",
    link: "/projects-data/blinkit-retail-eda/dashboard/index.html"
  },
  "uber-analytics": {
    name: "Uber Ride Operations & Profitability Analysis",
    category: "Data Analytics",
    timeline: "Jan 2025 – Feb 2025",
    description: "Analysis of 148K+ ride records to uncover cancellation patterns and optimize revenue — with a live Tableau dashboard.",
    built: "Analyzed 148K+ ride records with Python & SQL to uncover patterns in cancellations, revenue, and rider/driver satisfaction.",
    impact: [
      "Identified 25% cancellation rate root causes; proposed address verification to cut cancellations by 5–7%",
      "Found UPI at 40% of payments; recommended targeted promotions to lift avg. ride revenue by ~4%",
      "Built Tableau dashboard automating KPIs, saving 10+ hrs/month reporting time"
    ],
    tools: "Python, SQL, Tableau, Data Visualization",
    proofText: "The Python scripts, SQL queries, Tableau dashboards, and datasets are available in the uber-ride-analytics/ folder.",
    link: "/projects-data/uber-ride-analytics/dashboard/index.html"
  },
  "bank-loan": {
    name: "Bank Loan & Repayment Dashboard",
    category: "Financial Analysis",
    timeline: "Dec 2024 – Jan 2025",
    description: "Multi-platform financial dashboard tracking $435.8M in loans with automated KPIs exposing a 13.8% bad loan ratio.",
    built: "Cleaned & validated 38.6K+ loan records in SQL, engineered 15+ KPIs ensuring 100% accurate financial reporting. Developed 3 dashboards across Power BI, Tableau, and Excel.",
    impact: [
      "Automated MoM/MTD KPI tracking: $435.8M funded, $473.9M received",
      "Exposed a 13.8% bad loan ratio ($65.5M at risk)",
      "Uncovered 13.3% MoM loan growth and 15.8% MoM repayment growth"
    ],
    tools: "SQL, Power BI, Tableau, Excel",
    proofText: "The SQL scripts, Power BI/Tableau dashboards, Excel workbooks, and datasets are available in the bank-loan-analytics/ folder.",
    link: "/projects-data/bank-loan-analytics/dashboard/index.html"
  },
  "nayaa-assistant": {
    name: "\"Nayaa\" — AI Shopping Assistant",
    category: "Product Development | AI/ML",
    timeline: "Jun 2025 – Jul 2025",
    description: "An AI-powered shopping assistant that eliminates scroll fatigue and cluttered UIs through conversational commerce.",
    built: "Built an MVP chatbot using OpenAI APIs, n8n workflows, Cursor & Lovable, integrating prompt engineering and vector search. Simulated real-time recommendations and checkout flows on a 500+ product dataset.",
    impact: [
      "Mapped 4 key UX gaps across 10+ e-commerce platforms",
      "Applied RICE prioritization to feature roadmap, projecting +20% adoption",
      "Defined key success metrics: NPS >50, latency <2s"
    ],
    tools: "OpenAI APIs, n8n Workflows, Cursor, Lovable, Prompt Engineering",
    proofText: "Live demo simulation available."
  },
  "matchup-recruitment": {
    name: "\"MatchUp\" — Internship Recruitment Marketplace",
    category: "Product Strategy & Design",
    timeline: "Mar 2025 – Apr 2025",
    description: "A swipe-based recruitment marketplace that fixes the broken internship hiring process through double opt-in matching.",
    built: "Benchmarked 6 leading job platforms, identified 6 systemic hiring inefficiencies via SWOT & Blue Ocean strategy. Built a swipe-based double opt-in MVP with 20+ Figma wireframes.",
    impact: [
      "Designed flows aiming to cut irrelevant applications by ~70%",
      "Applied MoSCoW prioritization for feature scope",
      "Validating feature scope through 50+ usability walkthroughs"
    ],
    tools: "Figma, SWOT Analysis, Blue Ocean Strategy, MoSCoW Framework",
    proofText: "MVP presentation and Figma wireframes available."
  }
};

const ProjectDetail = () => {
  const { id } = useParams<{ id: string }>();
  const [project, setProject] = useState<any>(null);

  useEffect(() => {
    if (id && projectData[id]) {
      setProject(projectData[id]);
      window.scrollTo(0, 0);
    }
  }, [id]);

  if (!project) {
    return (
      <div className="project-detail-loading">
        <h2>Project not found</h2>
        <Link to="/" className="back-link"><FaArrowLeft /> Back to Home</Link>
      </div>
    );
  }

  return (
    <div className="project-detail-page">
      <div className="project-nav">
        <Link to="/" className="back-link"><FaArrowLeft /> Back to Home</Link>
      </div>
      
      <div className="project-header">
        <div className="project-tags">
          <span className="project-category">{project.category}</span>
          <span className="project-timeline">{project.timeline}</span>
        </div>
        <h1>{project.name}</h1>
        <p className="project-subtitle">{project.description}</p>
      </div>

      <div className="project-content">
        <div className="content-section">
          <h2>What I Built</h2>
          <p>{project.built}</p>
        </div>

        <div className="content-section">
          <h2>Impact & Key Findings</h2>
          <ul>
            {project.impact.map((item: string, i: number) => (
              <li key={i}>{item}</li>
            ))}
          </ul>
        </div>

        <div className="content-section">
          <h2>Tools Used</h2>
          <p className="tools-text">{project.tools}</p>
        </div>

        <div className="content-section proof-section">
          <h2>Proof of Work</h2>
          <div className="proof-box">
            <p>{project.proofText}</p>
            {project.link && (
              <a href={project.link} target="_blank" rel="noopener noreferrer" className="proof-link-btn">
                View Live Dashboard / Artifact
              </a>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default ProjectDetail;
