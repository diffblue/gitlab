import { GlAlert, GlLoadingIcon, GlTable, GlLink, GlKeysetPagination } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import * as Sentry from '@sentry/browser';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ComplianceStandardsAdherenceTable from 'ee/compliance_dashboard/components/standards_adherence_report/standards_adherence_table.vue';
import FixSuggestionsSidebar from 'ee/compliance_dashboard/components/standards_adherence_report/fix_suggestions_sidebar.vue';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import getProjectComplianceStandardsAdherence from 'ee/compliance_dashboard/graphql/compliance_standards_adherence.query.graphql';
import { createComplianceAdherencesResponse } from '../../mock_data';

Vue.use(VueApollo);

describe('ComplianceStandardsAdherenceTable component', () => {
  let wrapper;

  const defaultAdherencesResponse = createComplianceAdherencesResponse();
  const sentryError = new Error('GraphQL networkError');
  const mockGraphQlSuccess = jest.fn().mockResolvedValue(defaultAdherencesResponse);
  const mockGraphQlLoading = jest.fn().mockResolvedValue(new Promise(() => {}));
  const mockGraphQlError = jest.fn().mockRejectedValue(sentryError);
  const createMockApolloProvider = (resolverMock) => {
    return createMockApollo([[getProjectComplianceStandardsAdherence, resolverMock]]);
  };

  const findErrorMessage = () => wrapper.findComponent(GlAlert);
  const findStandardsAdherenceTable = () => wrapper.findComponent(GlTable);
  const findFixSuggestionSidebar = () => wrapper.findComponent(FixSuggestionsSidebar);
  const findTableLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTableHeaders = () => findStandardsAdherenceTable().findAll('th');
  const findTableRows = () => findStandardsAdherenceTable().findAll('tr');
  const findFirstTableRow = () => findTableRows().at(1);
  const findFirstTableRowData = () => findFirstTableRow().findAll('td');
  const findViewDetails = () => wrapper.findComponent(GlLink);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);

  const openSidebar = async () => {
    await findViewDetails().trigger('click');
    await nextTick();
  };

  const createComponent = ({ propsData = {}, resolverMock = mockGraphQlLoading } = {}) => {
    wrapper = extendedWrapper(
      mount(ComplianceStandardsAdherenceTable, {
        apolloProvider: createMockApolloProvider(resolverMock),
        propsData: {
          groupPath: 'example-group',
          ...propsData,
        },
      }),
    );
  };

  describe('default behavior', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render an error message', () => {
      expect(findErrorMessage().exists()).toBe(false);
    });

    it('has the correct table headers', () => {
      const headerTexts = findTableHeaders().wrappers.map((h) => h.text());

      expect(headerTexts).toStrictEqual([
        'Status',
        'Project',
        'Checks',
        'Standard',
        'Last Scanned',
        'Fix Suggestions',
      ]);
    });
  });

  describe('when the adherence query fails', () => {
    beforeEach(() => {
      jest.spyOn(Sentry, 'captureException');
      createComponent({ resolverMock: mockGraphQlError });
    });

    it('renders the error message', async () => {
      await waitForPromises();

      expect(findErrorMessage().text()).toBe(
        'Unable to load the standards adherence report. Refresh the page and try again.',
      );
      expect(Sentry.captureException.mock.calls[0][0].networkError).toBe(sentryError);
    });
  });

  describe('when there are standards adherence checks available', () => {
    beforeEach(() => {
      createComponent({ resolverMock: mockGraphQlSuccess });

      return waitForPromises();
    });

    it('does not render the table loading icon', () => {
      expect(mockGraphQlSuccess).toHaveBeenCalledTimes(1);

      expect(findTableLoadingIcon().exists()).toBe(false);
    });

    describe('when check is `PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR`', () => {
      it('renders the table row properly', () => {
        const rowText = findFirstTableRowData().wrappers.map((e) => e.text());

        expect(rowText).toStrictEqual([
          'Success',
          'Example Project',
          'Prevent authors as approvers Have a valid rule that prevents author approved merge requests',
          'GitLab',
          'Jul 1, 2023',
          'View details',
        ]);
      });
    });

    describe('when check is `PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITTERS`', () => {
      beforeEach(() => {
        const preventApprovalbyMRCommitersAdherencesResponse = createComplianceAdherencesResponse({
          checkName: 'PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITTERS',
        });
        const mockResolver = jest
          .fn()
          .mockResolvedValue(preventApprovalbyMRCommitersAdherencesResponse);

        createComponent({ resolverMock: mockResolver });

        return waitForPromises();
      });

      it('renders the table row properly', () => {
        const rowText = findFirstTableRowData().wrappers.map((e) => e.text());

        expect(rowText).toStrictEqual([
          'Success',
          'Example Project',
          'Prevent committers as approvers Have a valid rule that prevents merge requests approved by committers',
          'GitLab',
          'Jul 1, 2023',
          'View details',
        ]);
      });
    });

    describe('when check is `AT_LEAST_TWO_APPROVALS`', () => {
      beforeEach(() => {
        const atLeastTwoApprovalsAdherencesResponse = createComplianceAdherencesResponse({
          checkName: 'AT_LEAST_TWO_APPROVALS',
        });
        const mockResolver = jest.fn().mockResolvedValue(atLeastTwoApprovalsAdherencesResponse);

        createComponent({ resolverMock: mockResolver });

        return waitForPromises();
      });

      it('renders the table row properly', () => {
        const rowText = findFirstTableRowData().wrappers.map((e) => e.text());

        expect(rowText).toStrictEqual([
          'Success',
          'Example Project',
          'At least two approvals Have a valid rule that requires any merge request to have more than two approvals',
          'GitLab',
          'Jul 1, 2023',
          'View details',
        ]);
      });
    });

    describe('pagination', () => {
      describe('when there is more than one page of standards adherence checks available', () => {
        it('shows the pagination button', () => {
          expect(findPagination().exists()).toBe(true);
        });

        describe('when the next page has been selected', () => {
          beforeEach(async () => {
            findPagination().vm.$emit('next', 'next-value');

            await nextTick();
          });

          it('updates and calls the graphql query', () => {
            expect(mockGraphQlSuccess).toHaveBeenCalledTimes(2);
            expect(mockGraphQlSuccess).toHaveBeenCalledWith({
              after: 'next-value',
              before: null,
              first: 20,
              fullPath: 'example-group',
            });
          });
        });

        describe('when the prev page has been selected', () => {
          beforeEach(() => {
            findPagination().vm.$emit('prev', 'prev-value');
          });

          it('updates and calls the graphql query', () => {
            expect(mockGraphQlSuccess).toHaveBeenCalledWith({
              after: null,
              before: 'prev-value',
              last: 20,
              fullPath: 'example-group',
            });
          });
        });
      });

      describe('when there is only one page of standards adherence checks available', () => {
        beforeEach(() => {
          const response = createComplianceAdherencesResponse({
            pageInfo: {
              hasNextPage: false,
              hasPreviousPage: false,
            },
          });
          const mockResolver = jest.fn().mockResolvedValue(response);

          createComponent({ resolverMock: mockResolver });
          return waitForPromises();
        });

        it('does not show the pagination', () => {
          expect(findPagination().exists()).toBe(false);
        });
      });
    });
  });

  describe('when there are no standards adherence checks available', () => {
    beforeEach(() => {
      const noAdherencesResponse = createComplianceAdherencesResponse({ count: 0 });
      const mockResolver = jest.fn().mockResolvedValue(noAdherencesResponse);

      createComponent({ resolverMock: mockResolver });

      return waitForPromises();
    });

    it('renders the empty table message', () => {
      expect(findStandardsAdherenceTable().text()).toContain(
        ComplianceStandardsAdherenceTable.noStandardsAdherencesFound,
      );
    });
  });

  describe('fixSuggestionSidebar', () => {
    beforeEach(() => {
      createComponent({ resolverMock: mockGraphQlSuccess });

      return waitForPromises();
    });

    describe('closing the sidebar', () => {
      it('has the correct props when closed', async () => {
        await openSidebar();

        await findFixSuggestionSidebar().vm.$emit('close');

        expect(findFixSuggestionSidebar().props('groupPath')).toBe('example-group');
        expect(findFixSuggestionSidebar().props('showDrawer')).toBe(false);
        expect(findFixSuggestionSidebar().props('adherence')).toStrictEqual({});
      });
    });

    describe('opening the sidebar', () => {
      it('has the correct props when opened', async () => {
        await openSidebar();

        expect(findFixSuggestionSidebar().props('groupPath')).toBe('example-group');
        expect(findFixSuggestionSidebar().props('showDrawer')).toBe(true);
        expect(findFixSuggestionSidebar().props('adherence')).toStrictEqual(
          wrapper.vm.adherences.list[0],
        );
      });
    });
  });
});
