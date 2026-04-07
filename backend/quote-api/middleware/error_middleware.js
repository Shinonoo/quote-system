// middleware/error_middleware.js
const errorMiddleware = (err, req, res, next) => {
  err.statusCode = err.statusCode || 500;
  err.message = err.message || 'Internal Server Error';

  if (err.code === 'ER_DUP_ENTRY') {
    return res.status(409).json({ success: false, message: 'Duplicate entry found.' });
  }

  if (err.isOperational) {
    return res.status(err.statusCode).json({ success: false, message: err.message });
  }

  console.error('UNHANDLED ERROR:', err);
  return res.status(500).json({ success: false, message: 'Something went wrong.' });
};

module.exports = errorMiddleware; // ← must be a function
