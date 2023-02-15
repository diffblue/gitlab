import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EventItem from 'ee/vue_shared/security_reports/components/event_item.vue';
import MergeRequestNote from 'ee/vue_shared/security_reports/components/merge_request_note.vue';

const author = { name: 'Tanuki', username: 'gitlab' };

const FEEDBACK = {
  author,
  merge_request_path: '/path-to-the-mr',
  merge_request_iid: 1,
  created_at: '2022-02-22T22:22:22.222Z',
};

const FEEDBACK_CAMEL_CASE = {
  author,
  mergeRequestPath: '/path-to-the-mr',
  mergeRequestIid: 1,
  createdAt: '2022-02-22T22:22:22.222Z',
};

const PROJECT = {
  value: 'Project one',
  url: '/path-to-the-project',
};

describe('Merge request note', () => {
  let wrapper;

  const createWrapper = ({ feedback = FEEDBACK, project = PROJECT } = {}) => {
    wrapper = shallowMountExtended(MergeRequestNote, {
      stubs: { GlSprintf },
      propsData: { feedback, project },
    });
  };

  const findEventItem = () => wrapper.findComponent(EventItem);
  const findMergeRequestLink = () => wrapper.findByTestId('mergeRequestLink');
  const findProjectLink = () => wrapper.findByTestId('projectLink');

  describe('with no attached project', () => {
    beforeEach(() => createWrapper({ project: null }));

    it('should pass the expected data to the event item', () => {
      expect(findEventItem().props()).toMatchObject({
        author: FEEDBACK.author,
        createdAt: FEEDBACK.created_at,
      });
    });

    it('should return the event text with no project data', () => {
      expect(wrapper.text()).toMatchInterpolatedText(
        `Created merge request !${FEEDBACK.merge_request_iid}`,
      );
    });

    it('should have the correct url for the merge request link', () => {
      expect(findMergeRequestLink().attributes('href')).toBe(FEEDBACK.merge_request_path);
    });

    it('should not show the project link', () => {
      expect(findProjectLink().exists()).toBe(false);
    });
  });

  describe('with an attached project', () => {
    beforeEach(createWrapper);

    it('should return the event text with project data', () => {
      expect(wrapper.text()).toMatchInterpolatedText(
        `Created merge request !${FEEDBACK.merge_request_iid} at ${PROJECT.value}`,
      );
    });

    it('should have the correct url for the project link', () => {
      expect(findProjectLink().attributes('href')).toBe(PROJECT.url);
    });
  });

  describe('with unsafe data', () => {
    const unsafeProject = {
      ...PROJECT,
      value: 'Foo <script>alert("XSS")</script>',
    };

    beforeEach(() => createWrapper({ project: unsafeProject }));

    it('should escape the project name', () => {
      // Test that the XSS text has been rendered literally as safe text.
      expect(wrapper.text()).toContain(unsafeProject.value);
    });
  });

  describe('merge request from vulnerability details page', () => {
    beforeEach(() => createWrapper({ feedback: FEEDBACK_CAMEL_CASE }));

    it('should pass expected data to the event item', () => {
      expect(findEventItem().props()).toMatchObject({
        author: FEEDBACK_CAMEL_CASE.author,
        createdAt: FEEDBACK_CAMEL_CASE.createdAt,
      });
    });

    it('should show the event text with project data', () => {
      expect(wrapper.text()).toMatchInterpolatedText(
        `Created merge request !${FEEDBACK_CAMEL_CASE.mergeRequestIid} at ${PROJECT.value}`,
      );
    });

    it('should have the correct url for the merge request link', () => {
      expect(findMergeRequestLink().attributes('href')).toBe(FEEDBACK_CAMEL_CASE.mergeRequestPath);
    });
  });
});
