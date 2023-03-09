import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EventItem from 'ee/vue_shared/security_reports/components/event_item.vue';
import IssueNote from 'ee/vue_shared/security_reports/components/issue_note_graphql.vue';

const TEST_ISSUE = {
  iid: 2,
  webUrl: 'http://gdk.test:3000/secure-ex/security-reports/-/issues/2',
  createdAt: '2023-01-25T21:41:34Z',
  author: {
    id: 'gid://gitlab/User/1',
    name: 'Administrator',
    username: 'root',
    webUrl: 'http://gdk.test:3000/root',
  },
};

const TEST_ISSUE_LINKS = [
  {
    linkType: 'CREATED',
    issue: TEST_ISSUE,
  },
];

const TEST_PROJECT = {
  webUrl: 'http://gdk.test:3000/secure-ex/security-reports',
  nameWithNamespace: 'Secure Ex / Security Reports',
};

describe('IssueNoteGraphql GraphQL', () => {
  let wrapper;

  const createWrapper = ({ propsData } = {}) => {
    wrapper = shallowMountExtended(IssueNote, {
      stubs: { GlSprintf },
      propsData,
    });
  };

  const findEventItem = () => wrapper.findComponent(EventItem);
  const findIssueLink = () => wrapper.findByTestId('issue-link');
  const findProjectLink = () => wrapper.findByTestId('project-link');

  it('should not render if no issueLinks', () => {
    createWrapper({ propsData: { issueLinks: [] } });

    expect(wrapper.html()).toBe('');
  });

  describe('with no attached project', () => {
    beforeEach(() => {
      createWrapper({ propsData: { issueLinks: TEST_ISSUE_LINKS } });
    });

    it('should pass the author to the event item', () => {
      expect(findEventItem().props('author')).toBe(TEST_ISSUE.author);
    });

    it('should pass the created date to the event item', () => {
      expect(findEventItem().props('createdAt')).toBe(TEST_ISSUE.createdAt);
    });

    it('should return the event text with no project data', () => {
      expect(wrapper.text()).toMatchInterpolatedText(`Created issue #${TEST_ISSUE.iid}`);
    });
  });

  describe('with an attached project', () => {
    beforeEach(() => {
      createWrapper({ propsData: { issueLinks: TEST_ISSUE_LINKS, project: TEST_PROJECT } });
    });

    it('should return the event text with project data', () => {
      expect(wrapper.text()).toMatchInterpolatedText(
        `Created issue #${TEST_ISSUE.iid} at ${TEST_PROJECT.nameWithNamespace}`,
      );
    });
  });

  describe('links', () => {
    describe.each`
      type         | component          | href                   | text
      ${'issue'}   | ${findIssueLink}   | ${TEST_ISSUE.webUrl}   | ${`#${TEST_ISSUE.iid}`}
      ${'project'} | ${findProjectLink} | ${TEST_PROJECT.webUrl} | ${TEST_PROJECT.nameWithNamespace}
    `('for $type', ({ type, component, href, text }) => {
      beforeEach(() => {
        createWrapper({
          propsData: {
            issueLinks: TEST_ISSUE_LINKS,
            ...(type === 'project' && { project: TEST_PROJECT }),
          },
        });
      });

      it(`should render a link to the ${type}`, () => {
        expect(component().attributes('href')).toBe(href);
      });

      it(`should render the ${type} path as the text`, () => {
        expect(component().text()).toBe(text);
      });
    });
  });

  describe('with unsafe data', () => {
    const unsafeProject = {
      ...TEST_PROJECT,
      nameWithNamespace: 'Foo <script>alert("XSS")</script>',
    };

    beforeEach(() => {
      createWrapper({ propsData: { issueLinks: TEST_ISSUE_LINKS, project: unsafeProject } });
    });

    it('should escape and display the safe text for the project text', () => {
      expect(wrapper.text()).toContain(unsafeProject.nameWithNamespace);
    });
  });
});
