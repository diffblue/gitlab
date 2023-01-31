import {
  shouldPollTableData,
  getAdoptedCountsByCols,
  getGroupAdoptionPath,
} from 'ee/analytics/devops_reports/devops_adoption/utils/helpers';
import { DEVOPS_ADOPTION_TABLE_CONFIGURATION } from 'ee/analytics/devops_reports/devops_adoption/constants';
import { devopsAdoptionNamespaceData, namespaceWithSnapotsData } from '../mock_data';

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

describe('getAdoptedCountsByCols', () => {
  const {
    snapshots: { nodes },
  } = namespaceWithSnapotsData.data.devopsAdoptionEnabledNamespaces.nodes[0];

  it.each`
    snapshots               | cols                                           | expected
    ${nodes}                | ${DEVOPS_ADOPTION_TABLE_CONFIGURATION[0].cols} | ${[1]}
    ${[...nodes, ...nodes]} | ${DEVOPS_ADOPTION_TABLE_CONFIGURATION[0].cols} | ${[1, 1]}
    ${nodes}                | ${DEVOPS_ADOPTION_TABLE_CONFIGURATION[1].cols} | ${[4]}
    ${[...nodes, ...nodes]} | ${DEVOPS_ADOPTION_TABLE_CONFIGURATION[1].cols} | ${[4, 4]}
    ${nodes}                | ${DEVOPS_ADOPTION_TABLE_CONFIGURATION[2].cols} | ${[2]}
    ${[...nodes, ...nodes]} | ${DEVOPS_ADOPTION_TABLE_CONFIGURATION[2].cols} | ${[2, 2]}
    ${[]}                   | ${DEVOPS_ADOPTION_TABLE_CONFIGURATION[1].cols} | ${[]}
    ${nodes}                | ${[]}                                          | ${[0]}
    ${[]}                   | ${[]}                                          | ${[]}
  `(
    'returns the correct data set based on the snapshots and cols',
    ({ snapshots, cols, expected }) => {
      expect(getAdoptedCountsByCols(snapshots, cols)).toStrictEqual(expected);
    },
  );
});

describe('getGroupAdoptionPath', () => {
  it.each`
    fullPath        | expected
    ${'gitlab-org'} | ${'/groups/gitlab-org/-/analytics/devops_adoption'}
    ${null}         | ${null}
  `('returns the correct value based on the group full path', ({ fullPath, expected }) => {
    expect(getGroupAdoptionPath(fullPath)).toBe(expected);
  });

  it('with a relative URL returns the correct path', () => {
    gon.relative_url_root = '/fake';

    expect(getGroupAdoptionPath('gitlab-org')).toBe(
      '/fake/groups/gitlab-org/-/analytics/devops_adoption',
    );
  });
});
