import Vue from 'vue';
import Vuex from 'vuex';

import approvalsModule, {
  APPROVALS,
  APPROVALS_MODAL,
} from 'ee/approvals/stores/modules/license_compliance';
import { LICENSE_MANAGEMENT } from 'ee/vue_shared/license_compliance/store/constants';
import { licenseManagementModule } from 'ee/vue_shared/license_compliance/store/index';
import modalModule from '~/vuex_shared/modules/modal';
import { LICENSE_LIST } from './constants';
import listModule from './modules/list';
import createState from './state';

Vue.use(Vuex);

export default (settings = {}) =>
  new Vuex.Store({
    state: createState(settings),
    modules: {
      [LICENSE_LIST]: listModule(),
      [LICENSE_MANAGEMENT]: licenseManagementModule(),
      [APPROVALS]: approvalsModule(),
      [APPROVALS_MODAL]: modalModule(),
    },
  });
