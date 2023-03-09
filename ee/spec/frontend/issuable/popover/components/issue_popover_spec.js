import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import issueQueryResponse from 'test_fixtures/ee/graphql/issuable/popover/queries/issue.query.graphql.json';
import issueQuery from 'ee_else_ce/issuable/popover/queries/issue.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import IssuePopover from '~/issuable/popover/components/issue_popover.vue';
import IssueWeight from 'ee/boards/components/issue_card_weight.vue';

describe('Issue Popover', () => {
  let wrapper;

  Vue.use(VueApollo);

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
