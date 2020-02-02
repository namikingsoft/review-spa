const responseOf302Found = ({
  status,
  redirectUrl,
  setCookie: {
    name,
    value = '',
    maxAge,
  } = {},
}) => ({
  status: 302,
  statusDescription: 'Found',
  headers: {
    location: [{
      key: 'Location',
      value: redirectUrl,
    }],
    ...(name ? {
      'set-cookie': [{
        key: 'Set-Cookie',
        value: `${name}=${value}; path=/; ${maxAge == null ? '' : `Max-Age=${maxAge}; `}SameSite=Lax; Secure; HttpOnly`,
      }],
    } : {}),
  },
});

const responseOf401Unauthorized = () => ({
  status: '401',
  statusDescription: 'Unauthorized',
  body: '401 Unauthorized',
});

module.exports = {
  responseOf302Found,
  responseOf401Unauthorized,
};
