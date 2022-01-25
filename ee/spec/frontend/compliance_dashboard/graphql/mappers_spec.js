import { mapViolations } from 'ee/compliance_dashboard/graphql/mappers';
import resolvers from 'ee/compliance_dashboard/graphql/resolvers';
import { MERGE_REQUEST_VIOLATION_SEVERITY_LEVELS } from 'ee/compliance_dashboard/constants';

describe('mapViolations', () => {
  const mockViolations = resolvers.Query.group().mergeRequestViolations.nodes;
  const severityLevels = Object.keys(MERGE_REQUEST_VIOLATION_SEVERITY_LEVELS).map(Number);

  it.each(severityLevels)(
    'maps to the expected severity level when the violation severity number is %s',
    (severity) => {
      const { severity: severityLevel } = mapViolations([{ ...mockViolations[0], severity }])[0];

      expect(severityLevel).toBe(MERGE_REQUEST_VIOLATION_SEVERITY_LEVELS[severity]);
    },
  );
});
