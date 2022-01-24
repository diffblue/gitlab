import { mount } from '@vue/test-utils';
import { cloneDeep } from 'lodash';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import getIssuesQuery from 'ee_else_ce/issues/list/queries/get_issues.query.graphql';
import getIssuesCountsQuery from 'ee_else_ce/issues/list/queries/get_issues_counts.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getIssuesCountsQueryResponse, getIssuesQueryResponse } from 'jest/issues/list/mock_data';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import {
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_EPIC,
  TOKEN_TYPE_ITERATION,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_TYPE,
  TOKEN_TYPE_WEIGHT,
} from '~/issues/list/constants';
import BlockingIssuesCount from 'ee/issues/components/blocking_issues_count.vue';
import IssuesListApp from 'ee/issues/list/components/issues_list_app.vue';

describe('EE IssuesListApp component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const defaultQueryResponse = cloneDeep(getIssuesQueryResponse);
  defaultQueryResponse.data.project.issues.nodes[0].blockingCount = 1;
  defaultQueryResponse.data.project.issues.nodes[0].healthStatus = null;
  defaultQueryResponse.data.project.issues.nodes[0].weight = 5;

  const findIssuableList = () => wrapper.findComponent(IssuableList);

  const mountComponent = ({
    provide = {},
    issuesQueryResponse = jest.fn().mockResolvedValue(defaultQueryResponse),
    issuesCountsQueryResponse = jest.fn().mockResolvedValue(getIssuesCountsQueryResponse),
  } = {}) => {
    const requestHandlers = [
      [getIssuesQuery, issuesQueryResponse],
      [getIssuesCountsQuery, issuesCountsQueryResponse],
    ];
    const apolloProvider = createMockApollo(requestHandlers);

    return mount(IssuesListApp, {
      apolloProvider,
      provide: {
        hasAnyIssues: true,
        hasIssuableHealthStatusFeature: true,
        isProject: true,
        ...provide,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    beforeEach(async () => {
      wrapper = mountComponent();
      jest.runOnlyPendingTimers();
      await waitForPromises();
    });

    it('shows blocking issues count', () => {
      expect(wrapper.findComponent(BlockingIssuesCount).props('blockingIssuesCount')).toBe(
        defaultQueryResponse.data.project.issues.nodes[0].blockingCount,
      );
    });
  });

  describe('tokens', () => {
    const mockCurrentUser = {
      id: 1,
      name: 'Administrator',
      username: 'root',
      avatar_url: 'avatar/url',
    };

    describe.each`
      feature         | property                    | tokenName      | type
      ${'iterations'} | ${'hasIterationsFeature'}   | ${'Iteration'} | ${TOKEN_TYPE_ITERATION}
      ${'epics'}      | ${'groupPath'}              | ${'Epic'}      | ${TOKEN_TYPE_EPIC}
      ${'weights'}    | ${'hasIssueWeightsFeature'} | ${'Weight'}    | ${TOKEN_TYPE_WEIGHT}
    `('when $feature are not available', ({ property, tokenName, type }) => {
      beforeEach(() => {
        wrapper = mountComponent({ provide: { [property]: '' } });
      });

      it(`does not render ${tokenName} token`, () => {
        expect(findIssuableList().props('searchTokens')).not.toMatchObject([{ type }]);
      });
    });

    describe('when all tokens are available', () => {
      const originalGon = window.gon;

      beforeEach(() => {
        window.gon = {
          ...originalGon,
          current_user_id: mockCurrentUser.id,
          current_user_fullname: mockCurrentUser.name,
          current_username: mockCurrentUser.username,
          current_user_avatar_url: mockCurrentUser.avatar_url,
        };

        wrapper = mountComponent({
          provide: {
            groupPath: 'group/path',
            hasIssueWeightsFeature: true,
            hasIterationsFeature: true,
            isSignedIn: true,
          },
        });
      });

      afterEach(() => {
        window.gon = originalGon;
      });

      it('renders all tokens alphabetically', () => {
        const preloadedAuthors = [
          { ...mockCurrentUser, id: convertToGraphQLId('User', mockCurrentUser.id) },
        ];

        expect(findIssuableList().props('searchTokens')).toMatchObject([
          { type: TOKEN_TYPE_ASSIGNEE, preloadedAuthors },
          { type: TOKEN_TYPE_AUTHOR, preloadedAuthors },
          { type: TOKEN_TYPE_CONFIDENTIAL },
          { type: TOKEN_TYPE_EPIC },
          { type: TOKEN_TYPE_ITERATION },
          { type: TOKEN_TYPE_LABEL },
          { type: TOKEN_TYPE_MILESTONE },
          { type: TOKEN_TYPE_MY_REACTION },
          { type: TOKEN_TYPE_RELEASE },
          { type: TOKEN_TYPE_TYPE },
          { type: TOKEN_TYPE_WEIGHT },
        ]);
      });
    });
  });
});
