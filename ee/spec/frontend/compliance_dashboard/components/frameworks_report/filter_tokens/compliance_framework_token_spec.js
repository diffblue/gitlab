import * as Sentry from '@sentry/browser';
import { GlFilteredSearchToken, GlFilteredSearchSuggestion, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createComplianceFrameworksTokenResponse } from 'ee_jest/compliance_dashboard/mock_data';

import { stubComponent } from 'helpers/stub_component';
import ComplianceFrameworksToken from 'ee/compliance_dashboard/components/frameworks_report/filter_tokens/compliance_framework_token.vue';
import getComplianceFrameworkQuery from 'ee/graphql_shared/queries/get_compliance_framework.query.graphql';

Vue.use(VueApollo);

describe('ComplianceFrameworks', () => {
  const config = {
    groupPath: 'my-group',
  };

  const value = {
    id: 1,
    name: 'Framework 1',
  };

  const complianceFrameworks = [
    {
      id: 1,
      name: 'Framework 1',
      description: 'This is the first framework',
      default: true,
    },
    {
      id: 2,
      name: 'Framework 2',
      description: 'This is the second framework',
      default: false,
    },
  ];

  function createMockApolloProvider(resolverMock) {
    return createMockApollo([[getComplianceFrameworkQuery, resolverMock]]);
  }

  const sentryError = new Error('GraphQL networkError');

  const mockGraphQlLoading = jest.fn().mockResolvedValue(new Promise(() => {}));
  const mockGraphQlSuccess = jest.fn().mockResolvedValue(createComplianceFrameworksTokenResponse());
  const mockGraphQlError = jest.fn().mockRejectedValue(sentryError);

  let wrapper;

  const findAllFilteredSearchSuggestions = () =>
    wrapper.findAllComponents(GlFilteredSearchSuggestion);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const createComponent = (resolverMock = mockGraphQlLoading) => {
    wrapper = extendedWrapper(
      shallowMount(ComplianceFrameworksToken, {
        apolloProvider: createMockApolloProvider(resolverMock),
        propsData: {
          config,
          value,
        },
        stubs: {
          GlFilteredSearchToken: stubComponent(GlFilteredSearchToken, {
            template: `<div><slot name="suggestions"></slot></div>`,
          }),
        },
      }),
    );
  };

  it('displays loading icon while compliance frameworks are loading', () => {
    createComponent();

    expect(findLoadingIcon().exists()).toBe(true);
    expect(findAllFilteredSearchSuggestions().exists()).toBe(false);
  });

  it('displays compliance frameworks when they are loaded', async () => {
    createComponent(mockGraphQlSuccess);

    await waitForPromises();

    expect(findLoadingIcon().exists()).toBe(false);
    expect(findAllFilteredSearchSuggestions().exists()).toBe(true);
    expect(findAllFilteredSearchSuggestions().length).toBe(complianceFrameworks.length + 1);
  });

  it('captures the error message', async () => {
    jest.spyOn(Sentry, 'captureException');
    createComponent(mockGraphQlError);

    await waitForPromises();

    expect(Sentry.captureException.mock.calls[0][0].networkError).toBe(sentryError);
  });
});
