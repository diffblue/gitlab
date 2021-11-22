import { mapResponse } from 'ee/compliance_dashboard/graphql/mappers';

describe('Mappers', () => {
  describe('mapResponse', () => {
    it('returns an empty array if it receives one', () => {
      expect(mapResponse([])).toStrictEqual([]);
    });

    it('returns the correct array if it receives data', () => {
      expect(mapResponse([{ mergeRequest: { mergedAt: '1970-01-01' } }])).toStrictEqual([
        { mergeRequest: { mergedAt: '1970-01-01' }, mergedAt: '1970-01-01' },
      ]);
    });
  });
});
