import { GlAlert, GlLoadingIcon, GlTable, GlLink } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import * as Sentry from '@sentry/browser';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ComplianceReport from 'ee/compliance_dashboard/components/report.vue';
import MergeRequestDrawer from 'ee/compliance_dashboard/components/drawer.vue';
import MergeCommitsExportButton from 'ee/compliance_dashboard/components/merge_requests/merge_commits_export_button.vue';
import ViolationReason from 'ee/compliance_dashboard/components/violations/reason.vue';
import ViolationFilter from 'ee/compliance_dashboard/components/violations/filter.vue';
import resolvers from 'ee/compliance_dashboard/graphql/resolvers';
import { mapViolations } from 'ee/compliance_dashboard/graphql/mappers';
import { stripTypenames } from 'helpers/graphql_helpers';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import { stubComponent } from 'helpers/stub_component';
import { parseViolationsQueryFilter } from 'ee/compliance_dashboard/utils';

Vue.use(VueApollo);

describe('ComplianceReport component', () => {
  let wrapper;
  let mockResolver;

  const mergeCommitsCsvExportPath = '/csv';
  const groupPath = 'group-path';
  const createdAfter = '2021-11-16';
  const createdBefore = '2021-12-15';
  const defaultQuery = {
    projectIds: ['20'],
    createdAfter,
    createdBefore,
  };
  const mockGraphQlError = new Error('GraphQL networkError');

  const findSubheading = () => wrapper.findByTestId('subheading');
  const findErrorMessage = () => wrapper.findComponent(GlAlert);
  const findViolationsTable = () => wrapper.findComponent(GlTable);
  const findTableLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findMergeRequestDrawer = () => wrapper.findComponent(MergeRequestDrawer);
  const findMergeCommitsExportButton = () => wrapper.findComponent(MergeCommitsExportButton);
  const findViolationReason = () => wrapper.findComponent(ViolationReason);
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);
  const findViolationFilter = () => wrapper.findComponent(ViolationFilter);
  const findUrlSync = () => wrapper.findComponent(UrlSync);

  const findTableHeaders = () => findViolationsTable().findAll('th');
  const findTablesFirstRowData = () =>
    findViolationsTable().findAll('tbody > tr').at(0).findAll('td');
  const findSelectedRows = () => findViolationsTable().findAll('tr.b-table-row-selected');

  const selectRow = async (idx) => {
    await findViolationsTable().findAll('tbody > tr').at(idx).trigger('click');
    await nextTick();
  };

  const expectApolloVariables = (variables) => [
    {},
    variables,
    expect.anything(),
    expect.anything(),
  ];

  function createMockApolloProvider() {
    return createMockApollo([], { Query: { group: mockResolver } });
  }

  const createComponent = (mountFn = shallowMount, props = {}) => {
    return extendedWrapper(
      mountFn(ComplianceReport, {
        apolloProvider: createMockApolloProvider(),
        propsData: {
          mergeCommitsCsvExportPath,
          groupPath,
          defaultQuery,
          ...props,
        },
        stubs: {
          GlLink,
          GlTable: false,
          ViolationFilter: stubComponent(ViolationFilter),
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
    mockResolver = null;
  });

  describe('default behavior', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the subheading with a help link', () => {
      const helpLink = findSubheading().findComponent(GlLink);

      expect(findSubheading().text()).toContain(
        'The compliance report shows the merge request violations merged in protected environments.',
      );
      expect(helpLink.text()).toBe('Learn more.');
      expect(helpLink.attributes('href')).toBe(
        '/help/user/compliance/compliance_report/index.md#approval-status-and-separation-of-duties',
      );
    });

    it('renders the merge commit export button', () => {
      expect(findMergeCommitsExportButton().exists()).toBe(true);
    });

    it('does not render an error message', () => {
      expect(findErrorMessage().exists()).toBe(false);
    });
  });

  describe('when initializing', () => {
    beforeEach(() => {
      mockResolver = jest.fn();
      wrapper = createComponent(mount);
    });

    it('renders the table loading icon', () => {
      expect(findViolationsTable().exists()).toBe(true);
      expect(findTableLoadingIcon().exists()).toBe(true);
    });

    it('fetches the list of merge request violations with the filter query', async () => {
      expect(mockResolver).toHaveBeenCalledTimes(1);
      expect(mockResolver).toHaveBeenCalledWith(
        ...expectApolloVariables({
          fullPath: groupPath,
          filter: parseViolationsQueryFilter(defaultQuery),
        }),
      );
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

      expect(findErrorMessage().exists()).toBe(true);
      expect(findErrorMessage().text()).toBe(
        'Retrieving the compliance report failed. Refresh the page and try again.',
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

    it('does not render the table loading icon', () => {
      expect(findTableLoadingIcon().exists()).toBe(false);
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

    describe('violation filter', () => {
      beforeEach(() => {
        mockResolver = jest.fn().mockReturnValue(resolvers.Query.group());
        wrapper = createComponent(mount);

        return waitForPromises();
      });

      it('configures the filter', () => {
        expect(findViolationFilter().props()).toMatchObject({
          groupPath,
          defaultQuery,
        });
      });

      describe('when the filters changed', () => {
        const query = { createdAfter, createdBefore, projectIds: [1, 2, 3] };

        beforeEach(() => {
          return findViolationFilter().vm.$emit('filters-changed', query);
        });

        it('updates the URL query', () => {
          expect(findUrlSync().props('query')).toMatchObject(query);
        });

        it('shows the table loading icon', () => {
          expect(findTableLoadingIcon().exists()).toBe(true);
        });

        it('clears the project URL query param if the project array is empty', async () => {
          await findViolationFilter().vm.$emit('filters-changed', { ...query, projectIds: [] });

          expect(findUrlSync().props('query')).toMatchObject({ ...query, projectIds: null });
        });

        it('fetches the filtered violations', async () => {
          expect(mockResolver).toHaveBeenCalledTimes(2);
          expect(mockResolver).toHaveBeenNthCalledWith(
            2,
            ...expectApolloVariables({
              fullPath: groupPath,
              filter: parseViolationsQueryFilter(query),
            }),
          );
        });
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
      wrapper = createComponent(mount);

      return waitForPromises();
    });

    it('renders the empty table message', () => {
      expect(findViolationsTable().text()).toContain('No violations found');
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
