import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import IssueCardStatistics from 'ee/issues/list/components/issue_card_statistics.vue';
import BlockingIssuesCount from 'ee/issues/components/blocking_issues_count.vue';

describe('IssueCardStatistics EE component', () => {
  let wrapper;

  const findBlockingIssuesCount = () => wrapper.findComponent(BlockingIssuesCount);

  const mountComponent = ({ blockingCount = 1 } = {}) => {
    wrapper = shallowMountExtended(IssueCardStatistics, {
      propsData: {
        issue: {
          blockingCount,
        },
      },
    });
  };

  it('renders blocking issues count', () => {
    mountComponent();

    expect(findBlockingIssuesCount().props()).toEqual({
      blockingIssuesCount: 1,
      isListItem: true,
    });
  });
});
