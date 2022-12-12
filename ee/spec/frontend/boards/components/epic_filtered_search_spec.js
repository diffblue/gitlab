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
  const { fetchUsers, fetchLabels } = issueBoardFilters({}, '', 'group');

  const createComponent = ({ initialFilterParams = {} } = {}) => {
    wrapper = shallowMount(EpicFilteredSearch, {
      provide: { initialFilterParams, fullPath: '', boardType: '' },
    });
  };

  window.gon = {
    current_user_id: '4',
    current_username: 'root',
    current_user_avatar_url: 'url',
    current_user_fullname: 'Admin',
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('finds BoardFilteredSearch', () => {
      expect(wrapper.findComponent(BoardFilteredSearch).exists()).toBe(true);
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
      expect(wrapper.findComponent(BoardFilteredSearch).props('tokens').toString()).toBe(
        orderBy(tokens, ['title']).toString(),
      );
    });
  });
});
