import React from 'react';
import { connect } from 'react-redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

class HelpContainer extends React.PureComponent {
  render() {
    return <main className="usa-grid">
      <AppSegment extraClassNames="cf-help-content" filledBackground>

        <h1 id="#top">Welcome to the eFolder Express Help Page!</h1>
        <p>Here you will find <Link href="#training-videos">Training Videos</Link> and answers to the&nbsp;
          <Link href="#faq">Frequently Asked Questions (FAQs)</Link> for eFolder Express, as well as links to the&nbsp;
          <Link href={this.props.trainingGuidePath} target="_blank">Training Guide</Link> and the&nbsp;
          <Link href={this.props.referenceGuidePath} target="_blank">Quick Reference Guide</Link>.
          These items are provided to assist you as you access and use eFolder Express.
          If you require further assistance after reviewing these items,
          please contact the Caseflow Product Support Team by calling (1-844-876-5548) or email&nbsp;
          <Link href="mailto: caseflow@va.gov">(caseflow@va.gov)</Link>.
          We look forward to assisting you.</p>
        <br />

        <h1 id="training-videos">Training Videos</h1>
        <div className="cf-help-divider"></div>
        <div className="usa-grid-full">
          <div className="usa-width-one-third">
            <iframe
              width="270"
              height="178.567"
              src="//www.youtube.com/embed/Tg13RotOJCg"
              frameBorder="0"
              allowFullScreen />
            <b>Access and Login</b><br />
            <small>Duration: 1:52</small>
            <p>Learn how to gain access and login to eFolder Express</p>
          </div>

          <div className="usa-width-one-third">
            <iframe
              width="270"
              height="178.567"
              src="//www.youtube.com/embed/rXhfMk1Edc4"
              frameBorder="0"
              allowFullScreen />
            <b>Navigating the Interface</b><br />
            <small>Duration: 1:59</small>
            <p>Learn how to use eFolder Express and improve your workflow.</p>
          </div>

          <div className="usa-width-one-third">
            <iframe
              width="270"
              height="178.567"
              src="//www.youtube.com/embed/zi35PN98hoE"
              frameBorder="0"
              allowFullScreen />
            <b>Find an eFolder</b><br />
            <small>Duration: 1:03</small>
            <p>Learn how to search for the full contents of a veteran's eFolder</p>
          </div>
        </div>
        <div className="usa-grid-full">
          <div className="usa-width-one-third">
            <iframe
              width="270"
              height="178.567"
              src="//www.youtube.com/embed/E6zAkrqoqX0"
              frameBorder="0"
              allowFullScreen />
            <b>Downloading the eFolder</b><br />
            <small>Duration: 2:16</small>
            <p>Learn how to download the files contained in a Veteran's eFolder.</p>
          </div>

          <div className="usa-width-one-third">
            <iframe
              width="270"
              height="178.567"
              src="//www.youtube.com/embed/e4X8RT6MF6w"
              frameBorder="0"
              allowFullScreen />
            <b>Managing Multiple Downloads</b><br />
            <small>Duration: 0:59</small>
            <p>Learn how to improve your workflow by downloading and managing multiple Veteran's eFolder at once.</p>
          </div>

          <div className="usa-width-one-third">
            <iframe
              width="270"
              height="178.567"
              src="//www.youtube.com/embed/R87KEbcwK08"
              frameBorder="0"
              allowFullScreen />
            <b>Providing Feedback</b><br />
            <small>Duration: 1:36</small>
            <p>Learn how to give feedback and seek help directly from the Digital Service support team.</p>
          </div>
        </div>

        <h1 id="faq">Frequently Asked Questions</h1>
        <div className="cf-help-divider"></div>
        <ul id="toc" className="usa-unstyled-list">
          <li><Link href="#what-is-efolder-express">1. What is eFolder Express?</Link></li>
          <li>
            <Link href="#How-efolder-was-developed">2. How was eFolder Express developed? Who was involved?</Link>
          </li>
          <li><Link href="#how-to-access">3. How do I get access to eFolder Express?</Link></li>
          <li><Link href="#browser-compatibility">4. Which browser can I use with eFolder Express?</Link></li>
          <li><Link href="#view-efolder">5. After searching for a case, I received the message
            "You don't have permission to view this efolder." What does this mean?</Link></li>
          <li><Link href="#virtual-va">6. Does eFolder Express downloads include Virtual VA documents?</Link></li>
          <li><Link href="#efolder-legacy">7. Does eFolder Express downloads include
            Legacy Content Manager documents?</Link></li>
          <li><Link href="#start-retrieving">8. What happens when I click "Start Retrieving eFolder"?</Link></li>
          <li><Link href="#retrieval-order">9. In what order does eFolder Express retrieve files from VBMS?</Link></li>
          <li><Link href="#cancel-retrieval">10. Can I cancel the file retrieval process after it starts? </Link></li>
          <li><Link href="#"selecting-documents>11.  What if I only need to download specific documents from an eFolder?
            Can I select the documents I want to download?</Link></li>
          <li><Link href="#errors-retrieving">12. Why am I getting errors while trying
            to retrieve documents from an efolder?</Link></li>
          <li><Link href="#download-efolder">13. What happens when I click "Download eFolder"?</Link></li>
          <li><Link href="#name-downloaded-efolder">14. How does eFolder Express name
            the downloaded efolder documents?</Link></li>
          <li><Link href="#history">15. What is History? How long does an efolder remain in my History?</Link></li>
          <li><Link href="#telecommuting">16. Does eFolder Express work while telecommuting?</Link></li>
          <li><Link href="#encounter-problems">17. What should I do if I encounter problems?</Link></li>
          <li><Link href="#share-feedback">18. How do I share my feedback for improving eFolder Express?</Link></li>
          <li><Link href="#need-help">19. What if I still need help?</Link></li>
        </ul>
        <br />

        <div className="cf-help-divider"></div>
        <h2 id="what-is-efolder-express">1. What is eFolder Express?</h2>
        <p>
          eFolder Express is a web-based application which allows authorized VA employees to bulk-download documents
          from a veteran's VBMS efolder, reducing the need to manually click and save these documents one by one.
          It was built by the Digital Service at VA (DSVA) and will create cost savings and process improvement for
          many areas of the VA such as the Office of General Council and the Records Management Center.
          Learn more: <Link href={this.props.trainingGuidePath} target="_blank">Training Guide</Link>.
        </p>

        <h2 id="How-efolder-was-developed">2. How was eFolder Express developed? Who was involved?</h2>
        <p>
          The Digital Service team worked closely with stakeholders across the VA to develop and test this software
          over several months. Using feedback from VA employees and human-centered design principles, we tweaked and
          improved the tool steadily. We will continue to improve the tool based on feedback and as we have more
          opportunities to make things simpler.
        </p>

        <h2 id="how-to-access">3. How do I get access to eFolder Express?</h2>
        <p>
          Due to PII and PHI considerations, eFolder Express is only accessible to authorized VA
          employees. To get access to eFolder Express, you must submit a request to your Information Security Officer
          (ISO) and/or Information Resources Management (IRM) team to adjust your Common Security Employee Manager
          (CSEM) permissions. To initiate the request, draft an email requesting your current permissions be updated
          as follows:
        </p>

        <p className="cf-help-image-wrapper">
          <img className="cf-help-image" alt="eFolder Access" src={this.props.efolderAccessImagePath} />
        </p>

        <p>
          Once the email is drafted, attach a copy of your latest “VA Privacy and Information Security Awareness and
          Rules of Behavior” training certificate and forward the email to your supervisor for approval. If approved,
          your supervisor should forward the request to your station’s IRM team and/or ISO for entry into CSEM.
          You will receive an email notice once access is granted.
        </p>

        <h2 id="browser-compatibility">4. Which browser can I use with eFolder Express? </h2>
        <p>
          eFolder Express is compatible with most modern browsers, such as Internet Explorer 9 (or later), Firefox,
          Chrome, and Safari.
        </p>

        <h2 id="view-efolder">5. After searching for a case, I received the message "You don't have permission to view
        this efolder." What does this mean?</h2>
        <p>
          This message is usually received when the requested efolder contains sensitive information or when you don't
          have the privileges required to access it.
        </p>

        <h2 id="virtual-va">6. Does eFolder Express downloads include Virtual VA documents?</h2>
        <p>
          Yes, eFolder Express downloads include both VBMS and Virtual VA documents. Virtual VA documents from the
          Legacy Content Manager (LCM) tab in VBMS are automatically included when an efolder is downloaded using
          eFolder Express.
        </p>

        <h2 id="efolder-legacy">7. Does eFolder Express downloads include Legacy Content Manager documents?</h2>
        <p>
          Yes, eFolder Express downloads include VBMS documents and Virtual VA documents from the
          Legacy Content Manager (LCM) tab.
        </p>

        <h2 id="start-retrieving">8. What happens when I click "Start Retrieving eFolder"?</h2>
        <p>
          eFolder Express begins gathering documents from the VBMS database as well as Virtual VA documents stored in
          the Legacy Content Manager . At this point, you can return to the eFolder Express home page to search for
          another Veteran ID. eFolder Express is able to retrieve multiple efolders at the same time. You can also
          close the browser window while the retrieval is in progress and eFolder Express will continue gathering the
          efolder documents in the background. It can take anywhere from a few minutes to a few hours to retrieve all
          the files from an efolder (depending on its size). Remember, you can return to the retrieval page from the
          History list on the eFolder Express home page by clicking the View Results link. Keep in mind, to actually
          open the efolder documents, you will need to download the efolder to your computer after the retrieval
          process completes.
        </p>

        <h2 id="retrieval-order">9. In what order does eFolder Express retrieve files from VBMS?</h2>
        <p>
          eFolder Express retrieves files in order of date received.
        </p>

        <h2 id="cancel-retrieval">10. Can I cancel the file retrieval process after it starts?</h2>
        <p>
          No. Once eFolder Express begins retrieving an efolder from VBMS and the Legacy Content Manager, you cannot
          cancel the retrieval. You can, however, choose not to download the efolder to your computer after it
          is retrieved.
        </p>

        <h2 id="selecting-documents">11. What if I only need to download specific documents from an eFolder?
        Can I select the documents I want to download?</h2>
        <p>
          Currently, eFolder Express only supports downloading an entire efolder. If you need to download a specific
          document, or set of documents, from a veteran's efolder, you can either download the entire efolder using
          eFolder Express and delete the documents you do not need, or you can download the specific document,
          or set of documents, manually from VBMS and from the Legacy Content Manager (for Virtual VA documents)
        </p>

        <h2 id="errors-retrieving">12. Why am I getting errors while trying to retrieve documents from an efolder?</h2>
        <p>
          If you are receiving errors while trying to retrieve documents from an efolder, it may be because VBMS is
          down. Since eFolder Express pulls information directly from the VBMS database, if VBMS is not running
          correctly, eFolder Express will not be able to connect to VBMS to retrieve the efolder. You can retry the
          entire efolder retrieval when VBMS is running again. You may also encounter errors if your internet
          connection cuts out temporarily. Again, you can retry retrieving the entire efolder again. In rare cases,
          there may be a problem with a document in VBMS. If this happens, you may need to download that specific
          document manually from VBMS.
        </p>

        <h2 id="download-efolder">13. What happens when I click "Download eFolder"?</h2>
        <p>
          Your browser will ask you to open the folder or to designate a folder where you would like to save the
          efolder. Due to PII/PHI sensitivity considerations, VA requires you to download the efolder files to a
          shared drive, rather than your local disk. The retrieved efolder will then be downloaded as a .ZIP file
          onto the shared drive in the following pattern; lastnamefirstname-lastfourdigitsoftheveteransid.zip
          (for example: doejohn-1234.zip). After you open the .ZIP file, you will see the list of downloaded
          documents in receipt date order. They will be located inside a folder labeled in the same manner as the
          .zip file
        </p>

        <h2 id="name-downloaded-efolder">14. How does eFolder Express name the downloaded efolder documents?</h2>
        <p>
          Individual documents within an efolder will be prefixed with a number but, otherwise, retain their VBMS
          document type name. Documents will be listed in receipt date order and will be saved in the following pattern;
          documentnumber-documenttype-receiptdate-documentID.zip, where the date is written 4-digit year, 2-digit month,
          2-digit day (for example: 0010-HearingRequest_2016018.zip).
        </p>

        <h2 id="history">15. What is History? How long does an efolder remain in my History?</h2>
        <p>
          The History section on the eFolder Express home page shows a record of efolders that you have recently
          retrieved, as well as efolders the application is currently retrieving from VBMS and the Legacy Content
          Manager. You will see a "View Results" link next to efolders that have been retrieved from VBMS and the
          Legacy Content Manager and are ready to download, and a "View Progress" link next to efolders currently
          being retrieved. If any errors occurred during the retrieval process, you will see a red warning icon next
          to documents with errors. The History list clears automatically after 3 days.
        </p>

        <h2 id="telecommuting">16. Does eFolder Express work while telecommuting?</h2>
        <p>
          Yes, you can use eFolder Express while connected to the VA network via VPN.
        </p>

        <h2 id="encounter-problems">17. What should I do if I encounter problems?</h2>
        <p>
          If you encounter any problems while using eFolder Express, you should ask your supervisor for assistance.
          If you and your supervisor are unable to resolve the issue, please reach out to the Caseflow Product Support
          Team by calling 1-844-876-5548 or emailing <Link href="mailto: caseflow@va.gov">caseflow@va.gov.</Link>
        </p>

        <h2 id="share-feedback">18. How do I share my feedback for improving eFolder Express?</h2>
        <p>
          You can use the "Send feedback" link located on the bottom right side of any eFolder Express page or in the
          dropdown menu next to your username to share your ideas for improving eFolder Express.
        </p>

        <h2 id="need-help">19. What if I still need help?</h2>
        <p>
          If you require further assistance after reviewing the <Link href="#faq">FAQs</Link>,&nbsp;
          <Link href={this.props.referenceGuidePath} target="_blank">Quick Reference Guide</Link>,&nbsp;
          or <Link href={this.props.trainingGuidePath} target="_blank">Training Guide</Link>,
          please contact the Caseflow Product Support Team by phone (1-844-876-5548)
          or email (<Link href="mailto: caseflow@va.gov">caseflow@va.gov</Link>). We look forward to assisting you.
        </p>

      </AppSegment>

      <AppSegment><Link href ="#top">Back To Top</Link></AppSegment>

    </main>;
  }
}

const mapStateToProps = (state) => ({
  trainingGuidePath: state.trainingGuidePath,
  referenceGuidePath: state.referenceGuidePath,
  efolderAccessImagePath: state.efolderAccessImagePath
});

export default connect(mapStateToProps)(HelpContainer);
