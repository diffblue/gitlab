import { mapViolations } from 'ee/compliance_dashboard/graphql/mappers';
import resolvers from 'ee/compliance_dashboard/graphql/resolvers';

describe('mapViolations', () => {
  const mockViolations = resolvers.Query.group().mergeRequestViolations.nodes;

  it('returns the expected result', () => {
    const { mergeRequest } = mapViolations([{ ...mockViolations[0] }])[0];

    expect(mergeRequest).toMatchObject({
      reference: mergeRequest.ref,
      mergedBy: mergeRequest.mergeUser,
    });
  });
});
