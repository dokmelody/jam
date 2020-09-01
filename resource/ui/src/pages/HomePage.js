import React, { useEffect } from "react";
import "../App.css";

export default function HomePage() {
  useEffect(() => {
    var elements = document.getElementsByClassName("tc-card"); // get all card elements
    var cardShown = -1; // initially selected element is undefined hence -1

    // find the element that has been clicked
    var showSection = function () {
      var id = this.getAttribute("id");
      id = id.split("-")[1] || 0;
      if (cardShown !== id) {
        if (cardShown !== -1) {
          var currentSectionId = "section" + cardShown;
          var currentSection = document.getElementById(currentSectionId);
          currentSection.classList.add("hide-section");
        }
        cardShown = id;
        var upcomingSectionId = "section" + id;
        var upcomingSection = document.getElementById(upcomingSectionId);
        upcomingSection.classList.remove("hide-section");
      }
    };

    // add click listener to  all cards
    for (var i = 0; i < elements.length; i++) {
      elements[i].addEventListener("click", showSection, false);
    }
  }, []);
  return (
    <>
      <section className="tc-story-river">
        <section className="story-backdrop"></section>
        <div className="tc-tiddler-frame">
          <div className="tc-tiddler-title">
            <div className="tc-titlebar">
              <span>
                <span className="tc-tiddler-title-icon"></span>
                <h2 className="tc-title">Dok Programming Language</h2>
              </span>
            </div>
            <div
              className="tc-tiddler-info tc-popup-handle tc-reveal"
              hidden="true"
            ></div>
          </div>
          <div className="tc-reveal" hidden="true"></div>
          <div className="tc-reveal">
            <div className="tc-tags-wrapper">
              <span className="tc-tag-list-item">
                <span className="tc-drop-down tc-reveal" hidden="true"></span>
              </span>
            </div>
          </div>

          <div className="tc-tiddler-body tc-reveal">
            <p>
              <strong>
                Have you ever had the feeling that your head is not quite big
                enough to hold everything you need to remember?
              </strong>
            </p>
          </div>
          <p>
            Unlike conventional online services,
            <a
              className="tc-tiddlylink tc-tiddlylink-resolves"
              href="static/TiddlyWiki.html"
            >
              TiddlyWiki
            </a>
            lets you choose where to keep your data, guaranteeing that in the
            decades to come you will
            <a
              className="tc-tiddlylink tc-tiddlylink-resolves"
              href="static/Future%2520Proof.html"
            >
              still be able to use
            </a>
            the notes you take today.
          </p>

          <div className="content">
            <div
              className="tc-card"
              id="card-1"
              style={{ borderTop: "5px solid #ff8a65" }}
            >
              <a className="tc-tiddlylink tc-tiddlylink-resolves">
                <div className="tc-card-title">Section 1</div>
                <div className="tc-card-author">by ihm4u</div>
                <p>Single File Tiddlywiki5 executable</p>
              </a>
            </div>

            <div
              className="tc-card"
              id="card-2"
              style={{ borderTop: "5px solid #ff8a65" }}
            >
              <a className="tc-tiddlylink tc-tiddlylink-resolves">
                <div className="tc-card-title">Section 2</div>
                <div className="tc-card-author">by donmor</div>
                <p>Android app for saving changes locally to device storage</p>
              </a>
            </div>

            <div
              className="tc-card"
              id="card-3"
              style={{ borderTop: "5px solid #ff8a65" }}
            >
              <a className="tc-tiddlylink tc-tiddlylink-resolves">
                <div className="tc-card-title">Section 3</div>
                <div className="tc-card-author"></div>
                <p>Powerful new browser for Mac, Windows and Linux</p>
              </a>
            </div>

            <div
              className="tc-card"
              id="card-4"
              style={{ borderTop: "5px solid #ff8a65" }}
            >
              <a className="tc-tiddlylink tc-tiddlylink-resolves">
                <div className="tc-card-title">Section 4</div>
                <div className="tc-card-author">by Jeremy Ruston</div>
                <p>Custom desktop application for working with TiddlyWiki</p>
              </a>
            </div>

            <div
              className="tc-card"
              id="card-5"
              style={{ borderTop: "5px solid #ff8a65" }}
            >
              <a className="tc-tiddlylink tc-tiddlylink-resolves">
                <div className="tc-card-title">Section 5</div>
                <div className="tc-card-author">by Chris Hunt</div>
                <p>iPad/iPhone app for working with TiddlyWiki</p>
              </a>
            </div>

            <div
              className="tc-card"
              id="card-6"
              style={{ borderTop: "5px solid #f06292" }}
            >
              <a className="tc-tiddlylink tc-tiddlylink-resolves">
                <div className="tc-card-title">Section 6</div>
                <div className="tc-card-author"></div>
                <p>Using Node.js to serve/create flatfile wikis</p>
              </a>
            </div>

            <div
              className="tc-card"
              id="card-7"
              style={{ borderTop: "5px solid #4db6ac" }}
            >
              <a className="tc-tiddlylink tc-tiddlylink-resolves">
                <div className="tc-card-title">Section 7</div>
                <div className="tc-card-author">by Mario Pietsch</div>
                <p>Browser extension for Firefox</p>
              </a>
            </div>
          </div>
        </div>
      </section>

      <section className="tc-story-river hide-section" id="section1">
        <div className="tc-tiddler-frame">
          <div className="tc-tiddler-title">
            <h3>Section 1</h3>
          </div>
          <div className="tc-tiddler-body tc-reveal">
            <p>
              <strong>
                Have you ever had the feeling that your head is not quite big
                enough to hold everything you need to remember?
              </strong>
              Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
              eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut
              enim ad minim veniam, quis nostrud exercitation ullamco laboris
              nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in
              reprehenderit in voluptate velit esse cillum dolore eu fugiat
              nulla pariatur. Excepteur sint occaecat cupidatat non proident,
              sunt in culpa qui officia deserunt mollit anim id est laborum.
            </p>
          </div>
        </div>
      </section>

      <section className="tc-story-river hide-section" id="section2">
        <div className="tc-tiddler-frame">
          <div className="tc-tiddler-title">
            <h3>Section 2</h3>
          </div>
          <div className="tc-tiddler-body tc-reveal">
            <p>
              <strong>
                Have you ever had the feeling that your head is not quite big
                enough to hold everything you need to remember?
              </strong>
              Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
              eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut
              enim ad minim veniam, quis nostrud exercitation ullamco laboris
              nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in
              reprehenderit in voluptate velit esse cillum dolore eu fugiat
              nulla pariatur. Excepteur sint occaecat cupidatat non proident,
              sunt in culpa qui officia deserunt mollit anim id est laborum.
            </p>
          </div>
        </div>
      </section>

      <section className="tc-story-river hide-section" id="section3">
        <div className="tc-tiddler-frame">
          <div className="tc-tiddler-title">
            <h3>Section 3</h3>
          </div>
          <div className="tc-tiddler-body tc-reveal">
            <p>
              <strong>
                Have you ever had the feeling that your head is not quite big
                enough to hold everything you need to remember?
              </strong>
              Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
              eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut
              enim ad minim veniam, quis nostrud exercitation ullamco laboris
              nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in
              reprehenderit in voluptate velit esse cillum dolore eu fugiat
              nulla pariatur. Excepteur sint occaecat cupidatat non proident,
              sunt in culpa qui officia deserunt mollit anim id est laborum.
            </p>
          </div>
        </div>
      </section>

      <section className="tc-story-river hide-section" id="section4">
        <div className="tc-tiddler-frame">
          <div className="tc-tiddler-title">
            <h3>Section 4</h3>
          </div>
          <div className="tc-tiddler-body tc-reveal">
            <p>
              <strong>
                Have you ever had the feeling that your head is not quite big
                enough to hold everything you need to remember?
              </strong>
              Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
              eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut
              enim ad minim veniam, quis nostrud exercitation ullamco laboris
              nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in
              reprehenderit in voluptate velit esse cillum dolore eu fugiat
              nulla pariatur. Excepteur sint occaecat cupidatat non proident,
              sunt in culpa qui officia deserunt mollit anim id est laborum.
            </p>
          </div>
        </div>
      </section>

      <section className="tc-story-river hide-section" id="section5">
        <div className="tc-tiddler-frame">
          <div className="tc-tiddler-title">
            <h3>Section 5</h3>
          </div>
          <div className="tc-tiddler-body tc-reveal">
            <p>
              <strong>
                Have you ever had the feeling that your head is not quite big
                enough to hold everything you need to remember?
              </strong>
              Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
              eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut
              enim ad minim veniam, quis nostrud exercitation ullamco laboris
              nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in
              reprehenderit in voluptate velit esse cillum dolore eu fugiat
              nulla pariatur. Excepteur sint occaecat cupidatat non proident,
              sunt in culpa qui officia deserunt mollit anim id est laborum.
            </p>
          </div>
        </div>
      </section>

      <section className="tc-story-river hide-section" id="section6">
        <div className="tc-tiddler-frame">
          <div className="tc-tiddler-title">
            <h3>Section 6</h3>
          </div>
          <div className="tc-tiddler-body tc-reveal">
            <p>
              <strong>
                Have you ever had the feeling that your head is not quite big
                enough to hold everything you need to remember?
              </strong>
              Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
              eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut
              enim ad minim veniam, quis nostrud exercitation ullamco laboris
              nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in
              reprehenderit in voluptate velit esse cillum dolore eu fugiat
              nulla pariatur. Excepteur sint occaecat cupidatat non proident,
              sunt in culpa qui officia deserunt mollit anim id est laborum.
            </p>
          </div>
        </div>
      </section>

      <section className="tc-story-river hide-section" id="section7">
        <div className="tc-tiddler-frame">
          <div className="tc-tiddler-title">
            <h3>Section 7</h3>
          </div>
          <div className="tc-tiddler-body tc-reveal">
            <p>
              <strong>
                Have you ever had the feeling that your head is not quite big
                enough to hold everything you need to remember?
              </strong>
              Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
              eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut
              enim ad minim veniam, quis nostrud exercitation ullamco laboris
              nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in
              reprehenderit in voluptate velit esse cillum dolore eu fugiat
              nulla pariatur. Excepteur sint occaecat cupidatat non proident,
              sunt in culpa qui officia deserunt mollit anim id est laborum.
            </p>
          </div>
        </div>
      </section>
    </>
  );
}
