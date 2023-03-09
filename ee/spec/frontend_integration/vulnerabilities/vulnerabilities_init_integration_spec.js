import { screen, within } from '@testing-library/dom';
import initVulnerabilities from 'ee/vulnerabilities/vulnerabilities_init';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { waitForText } from 'helpers/wait_for_text';
import { VULNERABILITY_STATES } from 'ee/vulnerabilities/constants';
import { mockIssueLink } from '../test_helpers/mock_data/vulnerabilities_mock_data';
import { mockVulnerability } from './mock_data';

describe('Vulnerability Report', () => {
  let vm;
  let container;

  const createComponent = () => {
    const el = document.createElement('div');
    const elDataSet = {
      vulnerability: JSON.stringify(mockVulnerability),
      projectFullPath: 'namespace/project',
    };

    Object.assign(el.dataset, {
      ...elDataSet,
    });

    container.appendChild(el);

    return initVulnerabilities(el);
  };

  beforeEach(() => {
    setHTMLFixture('<div class="vulnerability-details"></div>');

    container = document.querySelector('.vulnerability-details');
    vm = createComponent(container);
  });

  afterEach(() => {
    vm.$destroy();
    container = null;
    resetHTMLFixture();
  });

  it("displays the vulnerability's status", () => {
    const headerBody = screen.getByTestId('vulnerability-detail-body');
    const stateName = VULNERABILITY_STATES[mockVulnerability.state];

    expect(within(headerBody).getByText(stateName)).toBeInstanceOf(HTMLElement);
  });

  it("displays the vulnerability's severity", () => {
    const severitySection = screen.getByTestId('severity');
    const severityValue = within(severitySection).getByTestId('value');

    expect(severityValue.textContent.toLowerCase()).toContain(
      mockVulnerability.severity.toLowerCase(),
    );
  });

  it("displays a heading containing the vulnerability's title", () => {
    expect(screen.getByRole('heading', { name: mockVulnerability.title })).toBeInstanceOf(
      HTMLElement,
    );
  });

  it("displays the vulnerability's description", () => {
    const section = screen.getByTestId('description');

    expect(section).toBeInstanceOf(HTMLElement);
    expect(section.innerHTML).toBe(mockVulnerability.descriptionHtml);
  });

  it('displays related issues', async () => {
    const relatedIssueTitle = await waitForText(mockIssueLink.title);

    expect(relatedIssueTitle).toBeInstanceOf(HTMLElement);
  });
});
