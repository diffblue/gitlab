import { mapViolations } from 'ee/compliance_dashboard/graphql/mappers';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import { createComplianceViolation } from '../mock_data';

describe('mapViolations', () => {
  it('returns the expected result', () => {
    const { mergeRequest } = mapViolations([createComplianceViolation()])[0];

    expect(mergeRequest).toMatchObject({
      reference: mergeRequest.ref,
      mergedBy: convertObjectPropsToSnakeCase(mergeRequest.mergeUser),
    });
  });
});
