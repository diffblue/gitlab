export const REPORT_TYPES = {
  list: 'list',
  url: 'url',
  diff: 'diff',
  namedList: 'named-list',
  text: 'text',
  value: 'value',
  moduleLocation: 'module-location',
  fileLocation: 'file-location',
  table: 'table',
  code: 'code',
  markdown: 'markdown',
  commit: 'commit',
};

/*
 * Diff component
 */
const DIFF = 'diff';
const BEFORE = 'before';
const AFTER = 'after';

export const VIEW_TYPES = { DIFF, BEFORE, AFTER };

const NORMAL = 'normal';
const REMOVED = 'removed';
const ADDED = 'added';

export const LINE_TYPES = { NORMAL, REMOVED, ADDED };
