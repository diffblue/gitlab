import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import setWindowLocation from 'helpers/set_window_location_helper';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import { __ } from '~/locale';
import MembersFilteredSearchBar from '~/members/components/filter_sort/members_filtered_search_bar.vue';
import { MEMBER_TYPES } from '~/members/constants';
import { FILTERED_SEARCH_TOKEN_ENTERPRISE, FILTERED_SEARCH_USER_TYPE } from 'ee/members/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

jest.mock('~/lib/utils/url_utility', () => {
  const urlUtility = jest.requireActual('~/lib/utils/url_utility');

  return {
    __esModule: true,
    ...urlUtility,
    redirectTo: jest.fn(),
  };
});

Vue.use(Vuex);

describe('MembersFilteredSearchBar', () => {
  let wrapper;

  const createComponent = ({ state = {}, provide = {} } = {}) => {
    const store = new Vuex.Store({
      modules: {
        [MEMBER_TYPES.user]: {
          namespaced: true,
          state: {
            filteredSearchBar: {
              show: true,
              tokens: ['enterprise', 'user_type'],
              searchParam: 'search',
              placeholder: 'Filter members',
              recentSearchesStorageKey: 'group_members',
            },
            ...state,
          },
        },
      },
    });

    wrapper = shallowMount(MembersFilteredSearchBar, {
      provide: {
        sourceId: 1,
        canManageMembers: true,
        canFilterByEnterprise: true,
        namespace: MEMBER_TYPES.user,
        ...provide,
      },
      store,
    });
  };

  const findFilteredSearchBar = () => wrapper.findComponent(FilteredSearchBar);

  describe('when `canFilterByEnterprise` is `true`', () => {
    it('includes `enterprise` token in `filteredSearchBar.tokens`', () => {
      createComponent();

      expect(findFilteredSearchBar().props('tokens')).toContain(FILTERED_SEARCH_TOKEN_ENTERPRISE);
    });
  });

  describe('when `canFilterByEnterprise` is `false`', () => {
    it('does not include `enterprise` token in `filteredSearchBar.tokens`', () => {
      createComponent({ provide: { canFilterByEnterprise: false } });

      expect(findFilteredSearchBar().props('tokens')).not.toContain(
        FILTERED_SEARCH_TOKEN_ENTERPRISE,
      );
    });
  });

  describe('when filtered search bar is submitted with `enterprise = true` filter', () => {
    beforeEach(() => {
      setWindowLocation('https://localhost');
    });

    it('adds correct `?enterprise=true` query param', () => {
      createComponent();

      findFilteredSearchBar().vm.$emit('onFilter', [
        { type: FILTERED_SEARCH_TOKEN_ENTERPRISE.type, value: { data: true, operator: '=' } },
      ]);

      expect(redirectTo).toHaveBeenCalledWith('https://localhost/?enterprise=true'); // eslint-disable-line import/no-deprecated
    });
  });

  describe('when `service_accounts` feature flag is enabled', () => {
    beforeEach(() => {
      gon.features = { serviceAccountsCrud: true };
    });

    describe('when `canManageMembers` is `true`', () => {
      it('includes `user_type` token in `filteredSearchBar.tokens`', () => {
        createComponent();

        expect(findFilteredSearchBar().props('tokens')).toContain(FILTERED_SEARCH_USER_TYPE);
      });

      describe('when filtered search bar is submitted with `user_type=service_account` filter', () => {
        beforeEach(() => {
          setWindowLocation('https://localhost');
        });

        it('adds correct `?user_type=service_account` query param', () => {
          createComponent();

          findFilteredSearchBar().vm.$emit('onFilter', [
            {
              type: FILTERED_SEARCH_USER_TYPE.type,
              // Remove the internationalized string after this issue is closed: https://gitlab.com/gitlab-org/gitlab-ui/-/issues/2159
              value: { data: __('Service account'), operator: '=' },
            },
          ]);

          expect(redirectTo).toHaveBeenCalledWith('https://localhost/?user_type=service_account'); // eslint-disable-line import/no-deprecated
        });
      });
    });

    describe('when `canManageMembers` is `false`', () => {
      it('does not include `user_type` token in `filteredSearchBar.tokens`', () => {
        createComponent({ provide: { canManageMembers: false } });

        expect(findFilteredSearchBar().props('tokens')).not.toContain(FILTERED_SEARCH_USER_TYPE);
      });
    });
  });

  describe('when `service_accounts` feature flag is disabled', () => {
    it('does not include `user_type` token in `filteredSearchBar.tokens`', () => {
      createComponent();

      expect(findFilteredSearchBar().props('tokens')).not.toContain(FILTERED_SEARCH_USER_TYPE);
    });
  });
});
