import { updateFindingState } from 'ee/security_dashboard/graphql/cache_updates';

describe('ee/app/assets/javascripts/security_dashboard/graphql/cache_updates.js', () => {
  describe('updateFindingState', () => {
    const store = {
      readQuery: jest.fn(() => ({
        project: {
          pipeline: {
            securityReportFinding: {
              state: 'DETECTED',
            },
          },
        },
      })),
      writeQuery: jest.fn(),
    };
    const query = 'query {}';
    const variables = '{ "foo": "bar" }';

    it('updates the cached finding to the given state', () => {
      const newState = 'DISMISSED';

      expect(store.writeQuery).not.toHaveBeenCalled();

      updateFindingState({
        state: newState,
        store,
        query,
        variables,
      });

      expect(store.writeQuery).toHaveBeenCalledWith({
        query,
        variables,
        data: {
          project: {
            pipeline: {
              securityReportFinding: {
                state: newState,
              },
            },
          },
        },
      });
    });
  });
});
