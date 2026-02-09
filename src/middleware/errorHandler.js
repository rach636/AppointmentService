// Centralized error handler middleware for Express
function errorHandler(err, req, res, next) {
  const statusCode = err.statusCode || 500;
  res.status(statusCode).json({
    message: err.message || 'Internal Server Error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
}

// 404 Not Found handler
function notFoundHandler(req, res, next) {
  res.status(404).json({ message: 'Not Found' });
}

module.exports = {
  errorHandler,
  notFoundHandler
};
