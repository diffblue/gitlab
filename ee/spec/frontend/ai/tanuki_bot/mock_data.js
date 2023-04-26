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
  msg: 'Tanuki Bot message',
  type: MESSAGE_TYPES.TANUKI,
  sources: MOCK_SOURCES,
};

export const MOCK_USER_MESSAGE = {
  msg: 'User message',
  type: MESSAGE_TYPES.USER,
};
