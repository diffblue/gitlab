import * as getters from 'ee/audit_events/store/getters';
import createState from 'ee/audit_events/store/state';

describe('Audit Events getters', () => {
  describe('buildExportHref', () => {
    const exportUrl = 'https://example.com/audit_reports.csv';

    describe('with empty state', () => {
      it('returns the export href', () => {
        const state = createState();

        expect(getters.buildExportHref(state)(exportUrl)).toEqual(
          'https://example.com/audit_reports.csv',
        );
      });
    });

    describe('with filters and dates', () => {
      it('returns the export url', () => {
        const filterValue = [{ type: 'user', value: { data: '@root', operator: '=' } }];
        const startDate = new Date(2020, 1, 2);
        const endDate = new Date(2020, 1, 30);
        const state = { ...createState, ...{ filterValue, startDate, endDate } };

        expect(getters.buildExportHref(state)(exportUrl)).toEqual(
          'https://example.com/audit_reports.csv?' +
            'created_after=2020-02-02&created_before=2020-03-01' +
            '&entity_type=User&entity_username=root',
        );
      });
    });
  });
});
