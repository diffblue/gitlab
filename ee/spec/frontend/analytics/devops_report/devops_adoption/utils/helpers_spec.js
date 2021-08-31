import { shouldPollTableData } from 'ee/analytics/devops_report/devops_adoption/utils/helpers';
import { devopsAdoptionNamespaceData } from '../mock_data';

describe('shouldPollTableData', () => {
  const { nodes: pendingData } = devopsAdoptionNamespaceData;
  const comepleteData = [pendingData[0]];

  it.each`
    scenario                                      | enabledNamespaces | openModal | expected
    ${'no namespaces data'}                       | ${[]}             | ${false}  | ${true}
    ${'open modal'}                               | ${comepleteData}  | ${true}   | ${false}
    ${'pending namespaces data, modal is closed'} | ${pendingData}    | ${false}  | ${true}
    ${'pending namespaces data, modal is open'}   | ${pendingData}    | ${true}   | ${false}
  `('returns $expected when $scenario', ({ enabledNamespaces, timestamp, openModal, expected }) => {
    expect(shouldPollTableData({ enabledNamespaces, timestamp, openModal })).toBe(expected);
  });
});
