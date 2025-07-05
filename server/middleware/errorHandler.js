const winston = require('winston');

// Create logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'blackthorn-manor-server' },
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

const errorHandler = (err, req, res, next) => {
  // Log error
  logger.error({
    message: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    userId: req.user?.id,
    timestamp: new Date().toISOString()
  });

  // Default error response
  let error = {
    message: 'Internal server error',
    status: 500
  };

  // Handle specific error types
  if (err.name === 'ValidationError') {
    error = {
      message: 'Validation error',
      status: 400,
      details: err.details || err.message
    };
  } else if (err.name === 'UnauthorizedError' || err.name === 'JsonWebTokenError') {
    error = {
      message: 'Unauthorized access',
      status: 401
    };
  } else if (err.name === 'ForbiddenError') {
    error = {
      message: 'Access forbidden',
      status: 403
    };
  } else if (err.name === 'NotFoundError') {
    error = {
      message: 'Resource not found',
      status: 404
    };
  } else if (err.name === 'ConflictError') {
    error = {
      message: 'Resource conflict',
      status: 409
    };
  } else if (err.code === 'SQLITE_CONSTRAINT') {
    error = {
      message: 'Database constraint violation',
      status: 409
    };
  } else if (err.code === 'LIMIT_FILE_SIZE') {
    error = {
      message: 'File size too large',
      status: 413
    };
  } else if (err.type === 'entity.parse.failed') {
    error = {
      message: 'Invalid JSON format',
      status: 400
    };
  }

  // Set custom error status if provided
  if (err.status) {
    error.status = err.status;
  }

  // Set custom error message if provided and not in production
  if (err.message && process.env.NODE_ENV !== 'production') {
    error.message = err.message;
  }

  // Send error response
  res.status(error.status).json({
    error: error.message,
    ...(error.details && { details: error.details }),
    ...(process.env.NODE_ENV === 'development' && { 
      stack: err.stack,
      originalError: err.message 
    }),
    timestamp: new Date().toISOString()
  });
};

module.exports = errorHandler;