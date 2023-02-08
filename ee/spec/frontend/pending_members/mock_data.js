import {
  HEADER_TOTAL_ENTRIES,
  HEADER_PAGE_NUMBER,
  HEADER_ITEMS_PER_PAGE,
} from 'ee/pending_members/constants';

export const mockDataMembers = {
  data: [
    {
      id: 177,
      name: '334050-1 334050-1',
      username: '334050-1',
      email: '334050-1@gitlab.com',
      web_url: 'http://127.0.0.1:3000/334050-1',
      avatar_url:
        'https://www.gravatar.com/avatar/9987bae8f71451bb2d422d0596367b25?s=80&d=identicon',
      approved: false,
      invited: false,
    },
    {
      id: 178,
      email: 'first-invite@gitlab.com',
      avatar_url:
        'https://www.gravatar.com/avatar/8bad6be3d5070e7f7865d91a50f44f1f?s=80&d=identicon',
      approved: false,
      invited: true,
    },
  ],
  headers: {
    [HEADER_TOTAL_ENTRIES]: '3',
    [HEADER_PAGE_NUMBER]: '1',
    [HEADER_ITEMS_PER_PAGE]: '1',
  },
};

export const mockDataNoMembers = {
  data: [],
  headers: {
    [HEADER_TOTAL_ENTRIES]: '0',
    [HEADER_PAGE_NUMBER]: '1',
    [HEADER_ITEMS_PER_PAGE]: '1',
  },
};

export const mockInvitedApprovedMember = {
  id: 179,
  email: 'second-invite@gitlab.com',
  avatar_url: 'https://www.gravatar.com/avatar/c96806e80ab8c4ea4c668d795fcfed0f?s=80&d=identicon',
  approved: true,
  invited: true,
};
