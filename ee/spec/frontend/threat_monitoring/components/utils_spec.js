import { getSourceUrl, isPolicyInherited } from 'ee/threat_monitoring/components/utils';
import { TEST_HOST } from 'helpers/test_constants';

describe(getSourceUrl, () => {
  it.each`
    input     | output
    ${''}     | ${`${TEST_HOST}/groups/-/security/policies`}
    ${'test'} | ${`${TEST_HOST}/groups/test/-/security/policies`}
  `('returns `$output` when passed `$input`', ({ input, output }) => {
    expect(getSourceUrl(input)).toBe(output);
  });
});

describe(isPolicyInherited, () => {
  it.each`
    input                   | output
    ${undefined}            | ${false}
    ${{}}                   | ${false}
    ${{ inherited: false }} | ${false}
    ${{ inherited: true }}  | ${true}
  `('returns `$output` when passed `$input`', ({ input, output }) => {
    expect(isPolicyInherited(input)).toBe(output);
  });
});
