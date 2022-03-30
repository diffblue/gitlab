import { mapViolations } from 'ee/compliance_dashboard/graphql/mappers';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import { createComplianceViolation } from '../mock_data';

describe('mapViolations', () => {
  it('returns the expected result', () => {
    const violation = createComplianceViolation();
    const { mergeRequest } = mapViolations([violation])[0];

    expect(mergeRequest).toMatchObject({
      committers: [],
      approvedByUsers: [],
      participants: violation.mergeRequest.participants.nodes,
      reference: mergeRequest.ref,
      mergedBy: convertObjectPropsToSnakeCase(mergeRequest.mergeUser),
      project: {
        ...violation.project,
        complianceFramework: violation.mergeRequest.project?.complianceFrameworks?.nodes[0],
      },
    });
  });
});
