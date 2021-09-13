export const generateNote = ({ id = 1295 } = {}) => ({
  id: `gid://gitlab/DiscussionNote/${id}`,
  body: 'Created a note.',
  bodyHtml: '\u003cp\u003eCreated a note\u003c/p\u003e',
  updatedAt: '2021-08-25T16:21:18Z',
  system: false,
  systemNoteIconName: null,
  userPermissions: {
    adminNote: true,
  },
  author: {
    id: 'gid://gitlab/User/1',
    name: 'Administrator',
    username: 'root',
    webPath: '/root',
  },
});
