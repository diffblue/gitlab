import * as getters from 'ee/geo_nodes/store/getters';
import createState from 'ee/geo_nodes/store/state';
import {
  MOCK_PRIMARY_VERSION,
  MOCK_REPLICABLE_TYPES,
  MOCK_NODES,
  MOCK_PRIMARY_VERIFICATION_INFO,
  MOCK_SECONDARY_VERIFICATION_INFO,
  MOCK_SECONDARY_SYNC_INFO,
  MOCK_FILTER_NODES,
} from '../mock_data';

describe('GeoNodes Store Getters', () => {
  let state;

  beforeEach(() => {
    state = createState({
      primaryVersion: MOCK_PRIMARY_VERSION.version,
      primaryRevision: MOCK_PRIMARY_VERSION.revision,
      replicableTypes: MOCK_REPLICABLE_TYPES,
    });
  });

  describe('verificationInfo', () => {
    beforeEach(() => {
      state.nodes = MOCK_NODES;
    });

    describe('on primary node', () => {
      it('returns only replicable types that have checksum data', () => {
        expect(getters.verificationInfo(state)(MOCK_NODES[0].id)).toStrictEqual(
          MOCK_PRIMARY_VERIFICATION_INFO,
        );
      });
    });

    describe('on secondary node', () => {
      it('returns only replicable types that have verification data', () => {
        expect(getters.verificationInfo(state)(MOCK_NODES[1].id)).toStrictEqual(
          MOCK_SECONDARY_VERIFICATION_INFO,
        );
      });
    });
  });

  describe('syncInfo', () => {
    beforeEach(() => {
      state.nodes = MOCK_NODES;
    });

    it('returns the nodes sync information', () => {
      expect(getters.syncInfo(state)(MOCK_NODES[1].id)).toStrictEqual(MOCK_SECONDARY_SYNC_INFO);
    });
  });

  describe.each`
    nodeToRemove     | nodes              | canRemove
    ${MOCK_NODES[0]} | ${[MOCK_NODES[0]]} | ${true}
    ${MOCK_NODES[0]} | ${MOCK_NODES}      | ${false}
    ${MOCK_NODES[1]} | ${[MOCK_NODES[1]]} | ${true}
    ${MOCK_NODES[1]} | ${MOCK_NODES}      | ${true}
  `(`canRemoveNode`, ({ nodeToRemove, nodes, canRemove }) => {
    describe(`when node.primary ${nodeToRemove.primary} and total nodes is ${nodes.length}`, () => {
      beforeEach(() => {
        state.nodes = nodes;
      });

      it(`should return ${canRemove}`, () => {
        expect(getters.canRemoveNode(state)(nodeToRemove.id)).toBe(canRemove);
      });
    });
  });

  describe.each`
    status         | search                                     | expectedNodes
    ${null}        | ${''}                                      | ${MOCK_FILTER_NODES}
    ${'healthy'}   | ${''}                                      | ${[MOCK_FILTER_NODES[0], MOCK_FILTER_NODES[1]]}
    ${'unhealthy'} | ${''}                                      | ${[MOCK_FILTER_NODES[2]]}
    ${'disabled'}  | ${''}                                      | ${[MOCK_FILTER_NODES[3]]}
    ${'offline'}   | ${''}                                      | ${[MOCK_FILTER_NODES[4]]}
    ${'unknown'}   | ${''}                                      | ${[MOCK_FILTER_NODES[5]]}
    ${null}        | ${MOCK_FILTER_NODES[1].name}               | ${[MOCK_FILTER_NODES[1]]}
    ${null}        | ${MOCK_FILTER_NODES[3].url}                | ${[MOCK_FILTER_NODES[3]]}
    ${'healthy'}   | ${MOCK_FILTER_NODES[0].name}               | ${[MOCK_FILTER_NODES[0]]}
    ${'healthy'}   | ${MOCK_FILTER_NODES[0].name.toUpperCase()} | ${[MOCK_FILTER_NODES[0]]}
    ${'unhealthy'} | ${MOCK_FILTER_NODES[2].url}                | ${[MOCK_FILTER_NODES[2]]}
    ${'unhealthy'} | ${MOCK_FILTER_NODES[2].url.toUpperCase()}  | ${[MOCK_FILTER_NODES[2]]}
    ${'offline'}   | ${'NOT A MATCH'}                           | ${[]}
  `('filteredNodes', ({ status, search, expectedNodes }) => {
    describe(`when status is ${status} and search is ${search}`, () => {
      beforeEach(() => {
        state.nodes = MOCK_FILTER_NODES;
        state.statusFilter = status;
        state.searchFilter = search;
      });

      it('should return the correct filtered array', () => {
        expect(getters.filteredNodes(state)).toStrictEqual(expectedNodes);
      });
    });
  });

  describe.each`
    status         | expectedCount
    ${'healthy'}   | ${2}
    ${'unhealthy'} | ${1}
    ${'offline'}   | ${1}
    ${'disabled'}  | ${1}
    ${'unknown'}   | ${1}
  `('countNodesForStatus', ({ status, expectedCount }) => {
    describe(`when status is ${status}`, () => {
      beforeEach(() => {
        state.nodes = MOCK_FILTER_NODES;
      });

      it(`should return ${expectedCount}`, () => {
        expect(getters.countNodesForStatus(state)(status)).toBe(expectedCount);
      });
    });
  });
});
