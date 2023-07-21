import { MESSAGE_TYPES, SOURCE_TYPES } from 'ee/ai/tanuki_bot/constants';

export const MOCK_SOURCE_TYPES = {
  HANDBOOK: {
    title: 'GitLab Handbook',
    source_type: SOURCE_TYPES.HANDBOOK.value,
    source_url: 'https://about.gitlab.com/handbook/',
  },
  DOC: {
    stage: 'Mock Stage',
    group: 'Mock Group',
    source_type: SOURCE_TYPES.DOC.value,
    source_url: 'https://about.gitlab.com/company/team/',
  },
  BLOG: {
    date: '2023-04-21',
    author: 'Test User',
    source_type: SOURCE_TYPES.BLOG.value,
    source_url: 'https://about.gitlab.com/blog/',
  },
};

export const MOCK_SOURCES = Object.values(MOCK_SOURCE_TYPES);

export const MOCK_TANUKI_MESSAGE = {
  content: 'Tanuki Bot message',
  role: MESSAGE_TYPES.TANUKI,
  sources: MOCK_SOURCES,
};

export const MOCK_USER_MESSAGE = {
  content: 'User message',
  role: MESSAGE_TYPES.USER,
};

export const GENERATE_MOCK_TANUKI_RES = (body = JSON.stringify(MOCK_TANUKI_MESSAGE)) => {
  return {
    data: {
      aiCompletionResponse: {
        responseBody: body,
        errors: [],
      },
    },
  };
};

export const MOCK_TANUKI_SUCCESS_RES = GENERATE_MOCK_TANUKI_RES();

export const MOCK_TANUKI_ERROR_RES = (body = JSON.stringify(MOCK_TANUKI_MESSAGE)) => {
  return {
    data: {
      aiCompletionResponse: {
        responseBody: body,
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

export const MOCK_TANUKI_BOT_MUTATATION_RES = { data: { aiAction: { errors: [] } } };

export const MOCK_USER_ID = 'gid://gitlab/User/1';
export const MOCK_RESOURCE_ID = 'gid://gitlab/Issue/1';
