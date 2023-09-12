import { MESSAGE_TYPES, SOURCE_TYPES } from 'ee/ai/tanuki_bot/constants';
import { PROMO_URL } from 'jh_else_ce/lib/utils/url_utility';

export const MOCK_SOURCE_TYPES = {
  HANDBOOK: {
    title: 'GitLab Handbook',
    source_type: SOURCE_TYPES.HANDBOOK.value,
    source_url: `${PROMO_URL}/handbook/`,
  },
  DOC: {
    stage: 'Mock Stage',
    group: 'Mock Group',
    source_type: SOURCE_TYPES.DOC.value,
    source_url: `${PROMO_URL}/company/team/`,
  },
  BLOG: {
    date: '2023-04-21',
    author: 'Test User',
    source_type: SOURCE_TYPES.BLOG.value,
    source_url: `${PROMO_URL}/blog/`,
  },
};

export const MOCK_SOURCES = Object.values(MOCK_SOURCE_TYPES);

export const MOCK_TANUKI_MESSAGE = {
  id: '123',
  content: 'Tanuki Bot message',
  contentHtml: '<p>Tanuki Bot message</p>',
  role: MESSAGE_TYPES.TANUKI,
  extras: {
    sources: MOCK_SOURCES,
  },
  requestId: '987',
  errors: [],
  timestamp: '2021-04-21T12:00:00.000Z',
};

export const MOCK_USER_MESSAGE = {
  id: '456',
  content: 'User message',
  contentHtml: '<p>User message</p>',
  role: MESSAGE_TYPES.USER,
  requestId: '987',
  errors: [],
  timestamp: '2021-04-21T12:00:00.000Z',
  extras: null,
};

export const MOCK_CHUNK_MESSAGE = {
  chunkId: 1,
  content: 'chunk',
  role: MESSAGE_TYPES.TANUKI,
  requestId: '987',
  errors: [],
  timestamp: '2021-04-21T12:00:00.000Z',
};

export const GENERATE_MOCK_TANUKI_RES = (body = JSON.stringify(MOCK_TANUKI_MESSAGE)) => {
  return {
    data: {
      aiCompletionResponse: {
        id: '123',
        content: body,
        contentHtml: `<p>${body}</p>`,
        errors: [],
        requestId: '987',
        role: MOCK_TANUKI_MESSAGE.role,
        timestamp: '2021-04-21T12:00:00.000Z',
        type: null,
        chunkId: null,
        extras: null,
      },
    },
  };
};

export const MOCK_TANUKI_SUCCESS_RES = GENERATE_MOCK_TANUKI_RES();

export const MOCK_TANUKI_ERROR_RES = (body = JSON.stringify(MOCK_TANUKI_MESSAGE)) => {
  return {
    data: {
      aiCompletionResponse: {
        id: '123',
        content: body,
        contentHtml: body,
        errors: ['error'],
      },
    },
  };
};

export const MOCK_CHAT_CACHED_MESSAGES_RES = {
  data: {
    aiMessages: {
      nodes: [MOCK_USER_MESSAGE, MOCK_TANUKI_MESSAGE],
    },
  },
};

export const MOCK_TANUKI_BOT_MUTATATION_RES = {
  data: { aiAction: { errors: [], requestId: '123' } },
};

export const MOCK_USER_ID = 'gid://gitlab/User/1';
export const MOCK_RESOURCE_ID = 'gid://gitlab/Issue/1';
