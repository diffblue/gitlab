import * as actions from 'ee/vue_shared/security_reports/store/modules/secret_detection/actions';
import * as types from 'ee/vue_shared/security_reports/store/modules/secret_detection/mutation_types';
import createState from 'ee/vue_shared/security_reports/store/modules/secret_detection/state';
import testAction from 'helpers/vuex_action_helper';

const issue = {};
let state;

// See also the corresponding CE specs in
// spec/frontend/vue_shared/security_reports/store/modules/secret_detection/actions_spec.js
describe('EE secret detection report actions', () => {
  beforeEach(() => {
    state = createState();
  });

  describe('updateVulnerability', () => {
    it(`should commit ${types.UPDATE_VULNERABILITY} with the correct response`, async () => {
      await testAction(
        actions.updateVulnerability,
        issue,
        state,
        [
          {
            type: types.UPDATE_VULNERABILITY,
            payload: issue,
          },
        ],
        [],
      );
    });
  });
});
