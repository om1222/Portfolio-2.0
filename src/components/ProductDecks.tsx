import "./styles/ProductDecks.css";
import HoverLinks from "./HoverLinks";

const ProductDecks = () => {
  return (
    <div className="product-decks-section section-container" id="product-decks">
      <div className="product-decks-container">
        <h2>
          Product <span>Decks</span>
        </h2>
        <p className="product-decks-subtext">
          End-to-end product thinking — from problem discovery to solution design, metrics, and go-to-market. These decks showcase how I approach building products from first principles.
        </p>
        
        <div className="product-decks-grid">
          {/* Deck 1 */}
          <div className="product-deck-card">
            <div className="product-deck-content">
              <h3 style={{ color: 'var(--accentColor)' }}>Cortex Browser — AI-Powered Workflow Browser</h3>
              <span className="deck-tag">RISA Labs APM Case</span>
              <p className="deck-desc">
                A product strategy deck proposing an AI-native browser that thinks alongside finance analysts — automating research, retaining long-term context, and transforming fragmented workflows into intelligent, continuous decision-making.
              </p>
              <div className="deck-highlights">
                <span>Problem: Analysts waste 2.5–3.6 hrs/day re-finding info</span>
                <span>Solution: Context-aware browser with Memory Graph</span>
                <span>North Star Metric: Time-to-Insight Reduction (≥60%)</span>
              </div>
            </div>
            <a 
              href="https://drive.google.com/file/d/1udOuUbP7xXEP8ZEDW_-fxQmka5IVDpJz/view?usp=sharing" 
              target="_blank" 
              rel="noopener noreferrer"
              className="deck-btn"
            >
              <HoverLinks text="VIEW FULL DECK →" />
            </a>
          </div>

          {/* Deck 2 */}
          <div className="product-deck-card">
            <div className="product-deck-content">
              <h3 style={{ color: 'var(--accentColor)' }}>The Wandering Garden — Designing Boredom</h3>
              <span className="deck-tag">Flipkart Product Challenge</span>
              <p className="deck-desc">
                A product design deck tackling the attention economy crisis — proposing a biofeedback-driven VR experience where calmness is the control mechanic. The quieter the mind, the more alive the world becomes.
              </p>
              <div className="deck-highlights">
                <span>Problem: Boredom has been designed away. Attention spans ↓</span>
                <span>Solution: VR garden that rewards stillness via biofeedback</span>
                <span>North Star Metric: Minutes of Constructive Stillness (+25%)</span>
              </div>
            </div>
            <a 
              href="https://drive.google.com/file/d/17qyX9s1d4cbdpWcD1IYxqldWJQZdMBga/view?usp=sharing" 
              target="_blank" 
              rel="noopener noreferrer"
              className="deck-btn"
            >
              <HoverLinks text="VIEW FULL DECK →" />
            </a>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ProductDecks;
