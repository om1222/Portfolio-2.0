import { MdArrowOutward, MdCopyright } from "react-icons/md";
import "./styles/Contact.css";

const Contact = () => {
  return (
    <div className="contact-section section-container" id="contact">
      <div className="contact-container">
        <h3 style={{ color: 'var(--accentColor)' }}>Let's Build Something Together</h3>
        <p className="contact-subtext" style={{ color: '#a0a0a0', marginBottom: '40px', maxWidth: '600px', fontSize: '18px' }}>
          Whether you're looking for a product thinker, an analyst who tells stories with data, or someone who ships — I'd love to connect.
        </p>
        <div className="contact-flex">
          <div className="contact-info-column" style={{ display: 'flex', flexDirection: 'column', gap: '30px', flex: '1', alignItems: 'flex-start' }}>
            <div className="contact-box">
              <h4>Email</h4>
              <p>
                <a href="mailto:omkumar.iitdelhi@gmail.com" data-cursor="pointer">
                  omkumar.iitdelhi@gmail.com
                </a>
              </p>
              <h4>Phone</h4>
              <p>
                <a href="tel:+917897626246" data-cursor="pointer">
                  +91 78976 26246
                </a>
              </p>
            </div>
            <div className="contact-box">
              <h4>Social</h4>
              <a
                href="https://www.linkedin.com/in/omkumar9/"
                target="_blank"
                rel="noopener noreferrer"
                data-cursor="pointer"
                className="contact-social"
              >
                LinkedIn <MdArrowOutward />
              </a>
            </div>
            <div className="contact-box">
              <h2>
                Designed and Developed <br /> by <span>Om Kumar</span>
              </h2>
              <h5>
                <MdCopyright /> {new Date().getFullYear()}
              </h5>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Contact;
