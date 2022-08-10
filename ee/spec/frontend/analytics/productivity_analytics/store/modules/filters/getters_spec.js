import { chartKeys } from 'ee/analytics/productivity_analytics/constants';
import * as getters from 'ee/analytics/productivity_analytics/store/modules/filters/getters';
import createState from 'ee/analytics/productivity_analytics/store/modules/filters/state';
import { mockFilters } from '../../../mock_data';

describe('Productivity analytics filter getters', () => {
  let state;
  const groupNamespace = 'gitlab-org';
  const projectPath = 'gitlab-org/gitlab-test';

  beforeEach(() => {
    state = createState();
  });

  describe('getCommonFilterParams', () => {
    const startDate = new Date('2019-09-01');
    const endDate = new Date('2019-09-07');
    const expectedFilters = {
      author_username: mockFilters.authorUsername,
      'not[author_username]': mockFilters.notAuthorUsername,
      milestone_title: mockFilters.milestoneTitle,
      'not[milestone_title]': mockFilters.notMilestoneTitle,
      label_name: mockFilters.labelName,
      'not[label_name]': mockFilters.notLabelName,
    };

    beforeEach(() => {
      state = {
        groupNamespace,
        projectPath,
        startDate,
        endDate,
        ...mockFilters,
      };
    });

    describe('when chart is not scatterplot', () => {
      it('returns an object with common filter params', () => {
        const expected = {
          group_id: 'gitlab-org',
          merged_after: '2019-09-01T00:00:00Z',
          merged_before: '2019-09-07T23:59:59Z',
          project_id: 'gitlab-org/gitlab-test',
          ...expectedFilters,
        };

        const result = getters.getCommonFilterParams(state)(chartKeys.main);

        expect(result).toEqual(expected);
      });
    });

    describe('when chart is scatterplot', () => {
      it('returns an object with common filter params and subtracts 30 days from the merged_after date', () => {
        const mergedAfter = '2019-08-02';
        const expected = {
          group_id: 'gitlab-org',
          merged_after: `${mergedAfter}T00:00:00Z`,
          merged_before: '2019-09-07T23:59:59Z',
          project_id: 'gitlab-org/gitlab-test',
          ...expectedFilters,
        };

        const mockGetters = {
          scatterplotStartDate: new Date(mergedAfter),
        };

        const result = getters.getCommonFilterParams(state, mockGetters)(chartKeys.scatterplot);

        expect(result).toEqual(expected);
      });
    });
  });

  describe('scatterplotStartDate', () => {
    beforeEach(() => {
      state = {
        groupNamespace,
        projectPath,
        startDate: new Date('2019-09-01'),
        endDate: new Date('2019-09-10'),
      };
    });

    describe('when a minDate exists', () => {
      it('returns the minDate when the startDate (minus 30 days) is before to the minDate', () => {
        const minDate = new Date('2019-08-15');
        state.minDate = minDate;

        const result = getters.scatterplotStartDate(state);

        expect(result).toBe(minDate);
      });

      it('returns a computed date when the startDate (minus 30 days) is after to the minDate', () => {
        const minDate = new Date('2019-07-01');
        state.minDate = minDate;

        const result = getters.scatterplotStartDate(state);

        expect(result).toEqual(new Date('2019-08-02'));
      });
    });

    describe('when no minDate exists', () => {
      it('returns the computed date, i.e., startDate minus 30 days', () => {
        const result = getters.scatterplotStartDate(state);

        expect(result).toEqual(new Date('2019-08-02'));
      });
    });
  });
});
