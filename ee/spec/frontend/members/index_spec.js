import { dataAttribute } from 'jest/members/mock_data';
import { MEMBER_TYPES } from '~/members/constants';
import { initMembersApp } from '~/members/index';

describe('initMembersApp', () => {
  let el;
  let vm;

  const createVm = () => {
    vm = initMembersApp(el, {
      [MEMBER_TYPES.user]: {},
    });
  };

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('data-members-data', dataAttribute);
  });

  afterEach(() => {
    el = null;
  });

  it('sets `ldapOverridePath` in Vuex store', () => {
    createVm();

    expect(vm.$store.state[MEMBER_TYPES.user].ldapOverridePath).toBe(
      '/groups/ldap-group/-/group_members/:id/override',
    );
  });
});
