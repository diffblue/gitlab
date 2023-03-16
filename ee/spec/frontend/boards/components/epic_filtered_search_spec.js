import { shallowMount } from '@vue/test-utils';
import { orderBy } from 'lodash';
import EpicFilteredSearch from 'ee/boards/components/epic_filtered_search.vue';
import BoardFilteredSearch from 'ee/boards/components/board_filtered_search.vue';
import issueBoardFilters from '~/boards/issue_board_filters';
import {
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_LABEL,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_LABEL,
} from '~/vue_shared/components/filtered_search_bar/constants';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';

describe('EpicFilteredSearch', () => {
  let wrapper;
  const { fetchUsers, fetchLabels } = issueBoardFilters({}, '', true);

  const findFilteredSearch = () => wrapper.findComponent(BoardFilteredSearch);

  const createComponent = ({ initialFilterParams = {} } = {}) => {
    wrapper = shallowMount(EpicFilteredSearch, {
      provide: { initialFilterParams, fullPath: '', boardType: '', isGroupBoard: true },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      window.gon = {
        current_user_id: '4',
        current_username: 'root',
        current_user_avatar_url: 'url',
        current_user_fullname: 'Admin',
      };
      createComponent();
    });

    it('finds BoardFilteredSearch', () => {
      expect(findFilteredSearch().exists()).toBe(true);
    });

    it('emits setFilters when setFilters is emitted', () => {
      findFilteredSearch().vm.$emit('setFilters');
      expect(wrapper.emitted('setFilters')).toHaveLength(1);
    });

    it('passes tokens to BoardFilteredSearch', () => {
      const tokens = [
        {
          icon: 'labels',
          title: TOKEN_TITLE_LABEL,
          type: TOKEN_TYPE_LABEL,
          operators: [
            { value: '=', description: 'is' },
            { value: '!=', description: 'is not' },
          ],
          token: LabelToken,
          unique: false,
          symbol: '~',
          fetchLabels,
        },
        {
          icon: 'pencil',
          title: TOKEN_TITLE_AUTHOR,
          type: TOKEN_TYPE_AUTHOR,
          operators: [
            { value: '=', description: 'is' },
            { value: '!=', description: 'is not' },
          ],
          symbol: '@',
          token: UserToken,
          unique: true,
          fetchUsers,
          preloadedUsers: [
            { id: 'gid://gitlab/User/4', name: 'Admin', username: 'root', avatarUrl: 'url' },
          ],
        },
      ];
      expect(findFilteredSearch().props('tokens').toString()).toBe(
        orderBy(tokens, ['title']).toString(),
      );
    });
  });
});
