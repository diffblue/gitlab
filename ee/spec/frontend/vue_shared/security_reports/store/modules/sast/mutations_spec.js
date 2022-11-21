import * as types from 'ee/vue_shared/security_reports/store/modules/sast/mutation_types';
import mutations from 'ee/vue_shared/security_reports/store/modules/sast/mutations';
import createState from 'ee/vue_shared/security_reports/store/modules/sast/state';

const createIssue = ({ ...config }) => ({ changed: false, ...config });

// See also the corresponding CE specs in
// spec/frontend/vue_shared/security_reports/store/modules/sast/mutations_spec.js
describe('EE sast module mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe(types.UPDATE_VULNERABILITY, () => {
    let newIssue;
    let resolvedIssue;
    let allIssue;

    beforeEach(() => {
      newIssue = createIssue({ uuid: 'new' });
      resolvedIssue = createIssue({ uuid: 'resolved' });
      allIssue = createIssue({ uuid: 'all' });

      state.newIssues.push(newIssue);
      state.resolvedIssues.push(resolvedIssue);
      state.allIssues.push(allIssue);
    });

    describe('with a `new` issue', () => {
      beforeEach(() => {
        mutations[types.UPDATE_VULNERABILITY](state, { ...newIssue, changed: true });
      });

      it('should update the correct issue', () => {
        expect(state.newIssues[0].changed).toBe(true);
      });
    });

    describe('with a `resolved` issue', () => {
      beforeEach(() => {
        mutations[types.UPDATE_VULNERABILITY](state, { ...resolvedIssue, changed: true });
      });

      it('should update the correct issue', () => {
        expect(state.resolvedIssues[0].changed).toBe(true);
      });
    });

    describe('with an `all` issue', () => {
      beforeEach(() => {
        mutations[types.UPDATE_VULNERABILITY](state, { ...allIssue, changed: true });
      });

      it('should update the correct issue', () => {
        expect(state.allIssues[0].changed).toBe(true);
      });
    });

    describe('with an invalid issue', () => {
      beforeEach(() => {
        mutations[types.UPDATE_VULNERABILITY](
          state,
          createIssue({ uuid: 'invalid', changed: true }),
        );
      });

      it('should ignore the issue', () => {
        expect(state.newIssues[0].changed).toBe(false);
        expect(state.resolvedIssues[0].changed).toBe(false);
        expect(state.allIssues[0].changed).toBe(false);
      });
    });
  });
});
