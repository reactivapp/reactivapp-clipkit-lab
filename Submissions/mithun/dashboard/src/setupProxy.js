const { createProxyMiddleware } = require('http-proxy-middleware');

module.exports = function (app) {
  app.use(
    '/api',
    createProxyMiddleware({
      target: 'https://app.backboard.io',
      changeOrigin: true,
      secure: true,
    })
  );
};
