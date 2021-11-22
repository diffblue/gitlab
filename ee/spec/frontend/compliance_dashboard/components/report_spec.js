import { GlAlert, GlLoadingIcon, GlTable } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import * as Sentry from '@sentry/browser';
import ComplianceReport from 'ee/compliance_dashboard/components/report.vue';
import EmptyState from 'ee/compliance_dashboard/components/empty_state.vue';
import MergeRequestDrawer from 'ee/compliance_dashboard/components/drawer.vue';
import MergeCommitsExportButton from 'ee/compliance_dashboard/components/merge_requests/merge_commits_export_button.vue';
import ViolationReason from 'ee/compliance_dashboard/components/violations/reason.vue';
import resolvers from 'ee/compliance_dashboard/graphql/resolvers';
import { mapViolations } from 'ee/compliance_dashboard/graphql/mappers';
import { stripTypenames } from 'helpers/graphql_helpers';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

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
  const findMergeRequestDrawer = () => wrapper.findComponent(MergeRequestDrawer);
  const findEmptyState = () => wrapper.findComponent(EmptyState);
  const findMergeCommitsExportButton = () => wrapper.findComponent(MergeCommitsExportButton);
  const findViolationReason = () => wrapper.findComponent(ViolationReason);
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);

  const findTableHeaders = () => findViolationsTable().findAll('th');
  const findTablesFirstRowData = () =>
    findViolationsTable().findAll('tbody > tr').at(0).findAll('td');
  const findSelectedRows = () => findViolationsTable().findAll('tr.b-table-row-selected');

  const selectRow = async (idx) => {
    await findViolationsTable().findAll('tbody > tr').at(idx).trigger('click');
    await nextTick();
  };

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
    it('has the correct first row data', () => {
      const headerTexts = findTablesFirstRowData().wrappers.map((d) => d.text());

      expect(headerTexts).toEqual([
        '1',
        'Approved by committer',
        'Officiis architecto voluptas ut sit qui qui quisquam sequi consectetur porro.',
        'in 1 year',
      ]);
    });

    it('renders the violation reason', () => {
      const {
        violatingUser: { __typename, ...user },
        reason,
      } = mockResolver().mergeRequestViolations.nodes[0];

      expect(findViolationReason().props()).toMatchObject({
        reason,
        user,
      });
    });

    it('renders the time ago tooltip', () => {
      const {
        mergeRequest: { mergedAt },
      } = mockResolver().mergeRequestViolations.nodes[0];

      expect(findTimeAgoTooltip().props('time')).toBe(mergedAt);
    });

    describe('with the merge request drawer', () => {
      it('opens the drawer', async () => {
        const drawerData = mapViolations(mockResolver().mergeRequestViolations.nodes)[0];

        await selectRow(0);

        expect(findMergeRequestDrawer().props('showDrawer')).toBe(true);
        expect(findMergeRequestDrawer().props('mergeRequest')).toStrictEqual(
          stripTypenames(drawerData.mergeRequest),
        );
        expect(findMergeRequestDrawer().props('project')).toStrictEqual(
          stripTypenames(drawerData.project),
        );
      });

      it('closes the drawer via the drawer close event', async () => {
        await selectRow(0);
        expect(findSelectedRows()).toHaveLength(1);

        await findMergeRequestDrawer().vm.$emit('close');

        expect(findMergeRequestDrawer().props('showDrawer')).toBe(false);
        expect(findSelectedRows()).toHaveLength(0);
        expect(findMergeRequestDrawer().props('mergeRequest')).toStrictEqual({});
        expect(findMergeRequestDrawer().props('project')).toStrictEqual({});
      });

      it('closes the drawer via the row-selected event', async () => {
        await selectRow(0);

        expect(findSelectedRows()).toHaveLength(1);

        await selectRow(0);

        expect(findMergeRequestDrawer().props('showDrawer')).toBe(false);
        expect(findMergeRequestDrawer().props('mergeRequest')).toStrictEqual({});
        expect(findMergeRequestDrawer().props('project')).toStrictEqual({});
      });

      it('swaps the drawer when a new row is selected', async () => {
        const drawerData = mapViolations(mockResolver().mergeRequestViolations.nodes)[1];

        await selectRow(0);
        await selectRow(1);

        expect(findMergeRequestDrawer().props('showDrawer')).toBe(true);
        expect(findMergeRequestDrawer().props('mergeRequest')).toStrictEqual(
          stripTypenames(drawerData.mergeRequest),
        );
        expect(findMergeRequestDrawer().props('project')).toStrictEqual(
          stripTypenames(drawerData.project),
        );
      });
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
