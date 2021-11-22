import { GlAlert, GlLoadingIcon, GlTable } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import * as Sentry from '@sentry/browser';
import ComplianceReport from 'ee/compliance_dashboard/components/report.vue';
import EmptyState from 'ee/compliance_dashboard/components/empty_state.vue';
import MergeCommitsExportButton from 'ee/compliance_dashboard/components/merge_requests/merge_commits_export_button.vue';
import resolvers from 'ee/compliance_dashboard/graphql/resolvers';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';

Vue.use(VueApollo);

describe('ComplianceReport component', () => {
  let wrapper;
  let mockResolver;

  const mergeCommitsCsvExportPath = '/csv';
  const emptyStateSvgPath = 'empty.svg';
  const mockGraphQlError = new Error('GraphQL networkError');

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findErrorMessage = () => wrapper.findComponent(GlAlert);
  const findViolationsTable = () => wrapper.findComponent(GlTable);
  const findEmptyState = () => wrapper.findComponent(EmptyState);
  const findMergeCommitsExportButton = () => wrapper.findComponent(MergeCommitsExportButton);

  const findTableHeaders = () => findViolationsTable().findAll('th');
  const findTablesFirstRowData = () =>
    findViolationsTable().findAll('tbody > tr').at(0).findAll('td');

  function createMockApolloProvider() {
    return createMockApollo([], { Query: { group: mockResolver } });
  }

  const createComponent = (mountFn = shallowMount, props = {}) => {
    return mountFn(ComplianceReport, {
      apolloProvider: createMockApolloProvider(),
      propsData: {
        mergeCommitsCsvExportPath,
        emptyStateSvgPath,
        ...props,
      },
      stubs: {
        GlTable: false,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    mockResolver = null;
  });

  describe('loading', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findErrorMessage().exists()).toBe(false);
      expect(findViolationsTable().exists()).toBe(false);
    });
  });

  describe('when the query fails', () => {
    beforeEach(() => {
      jest.spyOn(Sentry, 'captureException');
      mockResolver = jest.fn().mockRejectedValue(mockGraphQlError);
      wrapper = createComponent();
    });

    it('renders the error message', async () => {
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findErrorMessage().exists()).toBe(true);
      expect(findErrorMessage().props('title')).toBe(
        'Retrieving the compliance report failed. Please refresh the page and try again.',
      );
      expect(Sentry.captureException.mock.calls[0][0].networkError).toBe(mockGraphQlError);
    });
  });

  describe('when there are violations', () => {
    beforeEach(() => {
      mockResolver = resolvers.Query.group;
      wrapper = createComponent(mount);

      return waitForPromises();
    });

    it('renders the merge commit export button', () => {
      expect(findMergeCommitsExportButton().exists()).toBe(true);
    });

    it('renders the violations table', async () => {
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findErrorMessage().exists()).toBe(false);
      expect(findViolationsTable().exists()).toBe(true);
    });

    it('has the correct table headers', () => {
      const headerTexts = findTableHeaders().wrappers.map((h) => h.text());

      expect(headerTexts).toStrictEqual(['Severity', 'Violation', 'Merge request', 'Date merged']);
    });

    // Note: This should be refactored as each table component is created
    // Severity: https://gitlab.com/gitlab-org/gitlab/-/issues/342900
    // Violation: https://gitlab.com/gitlab-org/gitlab/-/issues/342901
    // Merge request and date merged: https://gitlab.com/gitlab-org/gitlab/-/issues/342902
    it('has the correct first row data', () => {
      const headerTexts = findTablesFirstRowData().wrappers.map((d) => d.text());

      expect(headerTexts).toEqual(['1', '1', expect.anything(), '2021-11-25T11:56:52.215Z']);
    });
  });

  describe('when there are no violations', () => {
    beforeEach(() => {
      mockResolver = () => ({
        __typename: 'Group',
        id: 1,
        mergeRequestViolations: {
          __typename: 'MergeRequestViolations',
          nodes: [],
        },
      });
      wrapper = createComponent();

      return waitForPromises();
    });

    it('does not render the violations table', () => {
      expect(findViolationsTable().exists()).toBe(false);
    });

    it('renders the empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
      expect(findEmptyState().props('imagePath')).toBe(emptyStateSvgPath);
    });
  });

  describe('when the merge commit export link is not present', () => {
    beforeEach(() => {
      wrapper = createComponent(shallowMount, { mergeCommitsCsvExportPath: '' });
    });

    it('does not render the merge commit export button', () => {
      expect(findMergeCommitsExportButton().exists()).toBe(false);
    });
  });
});
