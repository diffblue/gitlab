import { humanizedBranchExceptions } from 'ee/security_orchestration/components/policy_drawer/utils';

describe('humanizedBranchExceptions', () => {
  it.each`
    exceptions                                                                                       | expectedResult
    ${undefined}                                                                                     | ${[]}
    ${[undefined, null]}                                                                             | ${[]}
    ${['test', 'test1']}                                                                             | ${['test', 'test1']}
    ${['test']}                                                                                      | ${['test']}
    ${['test', undefined]}                                                                           | ${['test']}
    ${[{ name: 'test', full_path: 'gitlab/group' }]}                                                 | ${['test (in %{codeStart}gitlab/group%{codeEnd})']}
    ${[{ name: 'test', full_path: 'gitlab/group' }, { name: 'test1', full_path: 'gitlab/project' }]} | ${['test (in %{codeStart}gitlab/group%{codeEnd})', 'test1 (in %{codeStart}gitlab/project%{codeEnd})']}
  `('should humanize branch exceptions', ({ exceptions, expectedResult }) => {
    expect(humanizedBranchExceptions(exceptions)).toEqual(expectedResult);
  });
});
