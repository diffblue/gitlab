import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CiResourceAbout from 'ee/ci/catalog/components/details/ci_resource_about.vue';
import { formatDate } from '~/lib/utils/datetime_utility';

describe('CiResourceAbout', () => {
  let wrapper;

  const defaultProps = {
    openIssuesCount: 4,
    openMergeRequestsCount: 9,
    versions: [{ id: 1, tagName: 'v1.0.0', releasedAt: '2022-08-23T17:19:09Z' }],
    webPath: 'path/to/project',
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(CiResourceAbout, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findProjectLink = () => wrapper.findByText('Go to the project');
  const findIssueCount = () => wrapper.findByText(`${defaultProps.openIssuesCount} issues`);
  const findMergeRequestCount = () =>
    wrapper.findByText(`${defaultProps.openMergeRequestsCount} merge requests`);
  const findLastRelease = () =>
    wrapper.findByText(
      `Last release at ${formatDate(defaultProps.versions[0].releasedAt, 'yyyy-mm-dd')}`,
    );

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders project link', () => {
      expect(findProjectLink().exists()).toBe(true);
    });

    it('renders the number of issues opened', () => {
      expect(findIssueCount().exists()).toBe(true);
    });

    it('renders the number of merge requests opened', () => {
      expect(findMergeRequestCount().exists()).toBe(true);
    });

    it('renders the last release date', () => {
      expect(findLastRelease().exists()).toBe(true);
    });

    describe('links', () => {
      it('has the correct project link', () => {
        expect(findProjectLink().attributes('href')).toBe(defaultProps.webPath);
      });

      it('has the correct issues link', () => {
        expect(findIssueCount().attributes('href')).toBe(`${defaultProps.webPath}/issues`);
      });

      it('has the correct merge request link', () => {
        expect(findMergeRequestCount().attributes('href')).toBe(
          `${defaultProps.webPath}/merge_requests`,
        );
      });

      it('has no link for release data', () => {
        expect(findLastRelease().attributes('href')).toBe(undefined);
      });
    });
  });
});
