import { GlSprintf } from '@gitlab/ui';
import MergeRequestNote from 'ee/vue_shared/security_reports/components/merge_request_note_graphql.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EventItem from 'ee/vue_shared/security_reports/components/event_item.vue';

const TEST_MERGE_REQUEST = {
  iid: 2,
  createdAt: '2022-10-16T22:42:02.975Z',
  webUrl: 'http://gdk.test:3000/secure-ex/security-reports/-/merge_requests/2',
  author: {
    __typename: 'UserCore',
    id: 'gid://gitlab/User/1',
    username: 'admin',
    name: 'Administrator',
    webUrl: 'http://gdk.test:3000/root',
  },
};

const TEST_PROJECT = {
  webUrl: 'http://gdk.test:3000/secure-ex/security-reports',
  nameWithNamespace: 'Secure Ex / Security Reports',
};

describe('MergeRequestNoteGraphQL', () => {
  let wrapper;

  const createWrapper = ({ propsData } = {}) => {
    wrapper = shallowMountExtended(MergeRequestNote, {
      stubs: { GlSprintf },
      propsData,
    });
  };

  const findEventItem = () => wrapper.findComponent(EventItem);
  const findMergeRequestLink = () => wrapper.findByTestId('merge-request-link');
  const findProjectLink = () => wrapper.findByTestId('project-link');

  it('should not render if no merge request', () => {
    createWrapper({ propsData: { mergeRequest: null } });

    expect(wrapper.html()).toBe('');
  });

  describe('with no attached project', () => {
    beforeEach(() => {
      createWrapper({ propsData: { mergeRequest: TEST_MERGE_REQUEST } });
    });

    it('should pass the author to the event item', () => {
      expect(findEventItem().props('author')).toBe(TEST_MERGE_REQUEST.author);
    });

    it('should pass the created date to the event item', () => {
      expect(findEventItem().props('createdAt')).toBe(TEST_MERGE_REQUEST.createdAt);
    });

    it('should return the event text with no project data', () => {
      expect(wrapper.text()).toMatchInterpolatedText(
        `Created merge request #${TEST_MERGE_REQUEST.iid}`,
      );
    });
  });

  describe('with an attached project', () => {
    beforeEach(() => {
      createWrapper({ propsData: { mergeRequest: TEST_MERGE_REQUEST, project: TEST_PROJECT } });
    });

    it('should return the event text with project data', () => {
      expect(wrapper.text()).toMatchInterpolatedText(
        `Created merge request #${TEST_MERGE_REQUEST.iid} at ${TEST_PROJECT.nameWithNamespace}`,
      );
    });
  });

  describe('links', () => {
    describe.each`
      type               | component               | href                         | text
      ${'merge request'} | ${findMergeRequestLink} | ${TEST_MERGE_REQUEST.webUrl} | ${`#${TEST_MERGE_REQUEST.iid}`}
      ${'project'}       | ${findProjectLink}      | ${TEST_PROJECT.webUrl}       | ${TEST_PROJECT.nameWithNamespace}
    `('for $type', ({ type, component, href, text }) => {
      beforeEach(() => {
        createWrapper({
          propsData: {
            mergeRequest: TEST_MERGE_REQUEST,
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
      createWrapper({ propsData: { mergeRequest: TEST_MERGE_REQUEST, project: unsafeProject } });
    });

    it('should escape the project name', () => {
      expect(wrapper.text()).toContain(unsafeProject.nameWithNamespace);
    });
  });
});
