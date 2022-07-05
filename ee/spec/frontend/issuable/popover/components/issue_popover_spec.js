import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import issueQuery from 'ee_else_ce/issuable/popover/queries/issue.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import IssuePopover from '~/issuable/popover/components/issue_popover.vue';
import IssueWeight from 'ee/boards/components/issue_card_weight.vue';

describe('Issue Popover', () => {
  let wrapper;

  Vue.use(VueApollo);

  const issueQueryResponse = {
    data: {
      project: {
        __typename: 'Project',
        id: '1',
        issue: {
          __typename: 'Issue',
          id: 'gid://gitlab/Issue/1',
          createdAt: '2020-07-01T04:08:01Z',
          state: 'opened',
          title: 'Issue title',
          confidential: true,
          dueDate: '2020-07-05',
          milestone: {
            __typename: 'Milestone',
            id: 'gid://gitlab/Milestone/1',
            title: '15.2',
            startDate: '2020-07-01',
            dueDate: '2020-07-30',
          },
          weight: 3,
        },
      },
    },
  };

  const mountComponent = ({
    queryResponse = jest.fn().mockResolvedValue(issueQueryResponse),
  } = {}) => {
    wrapper = shallowMount(IssuePopover, {
      apolloProvider: createMockApollo([[issueQuery, queryResponse]]),
      propsData: {
        target: document.createElement('a'),
        projectPath: 'foo/bar',
        iid: '1',
        cachedTitle: 'Cached title',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when loaded', () => {
    beforeEach(async () => {
      mountComponent();
      await waitForPromises();
    });

    it('shows weight', () => {
      const component = wrapper.findComponent(IssueWeight);

      expect(component.exists()).toBe(true);
      expect(component.props('weight')).toBe(3);
    });
  });
});
