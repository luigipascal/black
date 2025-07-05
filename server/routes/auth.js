const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const passport = require('passport');
const { body, validationResult } = require('express-validator');
const rateLimit = require('express-rate-limit');
const uuid = require('uuid');

const db = require('../config/database');
const auth = require('../middleware/auth');

const router = express.Router();

// Rate limiting for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // limit each IP to 5 requests per windowMs
  message: 'Too many authentication attempts, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});

// Register validation rules
const registerValidation = [
  body('email').isEmail().normalizeEmail(),
  body('username').isLength({ min: 3, max: 20 }).matches(/^[a-zA-Z0-9_]+$/),
  body('password').isLength({ min: 6 }).matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/),
  body('firstName').isLength({ min: 1, max: 50 }).trim(),
  body('lastName').isLength({ min: 1, max: 50 }).trim(),
];

// Login validation rules
const loginValidation = [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 1 }),
];

// JWT token generation
const generateToken = (user) => {
  return jwt.sign(
    { 
      id: user.id, 
      email: user.email, 
      username: user.username,
      role: user.role 
    },
    process.env.JWT_SECRET || 'blackthorn-manor-secret',
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
};

// Register endpoint
router.post('/register', authLimiter, registerValidation, async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { email, username, password, firstName, lastName } = req.body;

    // Check if user already exists
    const existingUser = await db('users')
      .where('email', email)
      .orWhere('username', username)
      .first();

    if (existingUser) {
      return res.status(409).json({
        error: 'User already exists',
        message: 'Email or username is already taken'
      });
    }

    // Hash password
    const saltRounds = 12;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Create user
    const [userId] = await db('users').insert({
      email,
      username,
      password_hash: passwordHash,
      first_name: firstName,
      last_name: lastName,
      preferences: JSON.stringify({
        theme: 'light',
        notifications: true,
        privacy: 'private'
      }),
      reading_progress: JSON.stringify({
        current_page: 0,
        revelation_level: 1,
        characters_discovered: [],
        bookmarks: []
      })
    });

    // Fetch created user
    const user = await db('users').where('id', userId).first();

    // Generate JWT token
    const token = generateToken(user);

    res.status(201).json({
      message: 'User registered successfully',
      token,
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        firstName: user.first_name,
        lastName: user.last_name,
        role: user.role,
        createdAt: user.created_at
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      error: 'Registration failed',
      message: 'An error occurred during registration'
    });
  }
});

// Login endpoint
router.post('/login', authLimiter, loginValidation, async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { email, password } = req.body;

    // Find user
    const user = await db('users')
      .where('email', email)
      .where('is_active', true)
      .first();

    if (!user) {
      return res.status(401).json({
        error: 'Authentication failed',
        message: 'Invalid email or password'
      });
    }

    // Check password
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({
        error: 'Authentication failed',
        message: 'Invalid email or password'
      });
    }

    // Update last login
    await db('users')
      .where('id', user.id)
      .update({ last_login: new Date() });

    // Generate JWT token
    const token = generateToken(user);

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        firstName: user.first_name,
        lastName: user.last_name,
        role: user.role,
        preferences: JSON.parse(user.preferences || '{}'),
        readingProgress: JSON.parse(user.reading_progress || '{}')
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      error: 'Login failed',
      message: 'An error occurred during login'
    });
  }
});

// Get current user profile
router.get('/profile', auth, async (req, res) => {
  try {
    const user = await db('users')
      .where('id', req.user.id)
      .select('id', 'email', 'username', 'first_name', 'last_name', 'avatar_url', 'role', 'preferences', 'reading_progress', 'created_at')
      .first();

    if (!user) {
      return res.status(404).json({
        error: 'User not found'
      });
    }

    res.json({
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        firstName: user.first_name,
        lastName: user.last_name,
        avatarUrl: user.avatar_url,
        role: user.role,
        preferences: JSON.parse(user.preferences || '{}'),
        readingProgress: JSON.parse(user.reading_progress || '{}'),
        createdAt: user.created_at
      }
    });
  } catch (error) {
    console.error('Profile fetch error:', error);
    res.status(500).json({
      error: 'Failed to fetch profile'
    });
  }
});

// Update user profile
router.put('/profile', auth, [
  body('firstName').optional().isLength({ min: 1, max: 50 }).trim(),
  body('lastName').optional().isLength({ min: 1, max: 50 }).trim(),
  body('preferences').optional().isObject(),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { firstName, lastName, preferences } = req.body;
    const updateData = {};

    if (firstName !== undefined) updateData.first_name = firstName;
    if (lastName !== undefined) updateData.last_name = lastName;
    if (preferences !== undefined) updateData.preferences = JSON.stringify(preferences);

    updateData.updated_at = new Date();

    await db('users')
      .where('id', req.user.id)
      .update(updateData);

    res.json({
      message: 'Profile updated successfully'
    });
  } catch (error) {
    console.error('Profile update error:', error);
    res.status(500).json({
      error: 'Failed to update profile'
    });
  }
});

// Update reading progress
router.put('/reading-progress', auth, [
  body('currentPage').optional().isInt({ min: 0 }),
  body('revelationLevel').optional().isInt({ min: 1, max: 5 }),
  body('charactersDiscovered').optional().isArray(),
  body('bookmarks').optional().isArray(),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { currentPage, revelationLevel, charactersDiscovered, bookmarks } = req.body;

    // Get current reading progress
    const user = await db('users')
      .where('id', req.user.id)
      .select('reading_progress')
      .first();

    const currentProgress = JSON.parse(user.reading_progress || '{}');

    // Update progress
    const updatedProgress = {
      ...currentProgress,
      ...(currentPage !== undefined && { current_page: currentPage }),
      ...(revelationLevel !== undefined && { revelation_level: revelationLevel }),
      ...(charactersDiscovered !== undefined && { characters_discovered: charactersDiscovered }),
      ...(bookmarks !== undefined && { bookmarks: bookmarks }),
      last_updated: new Date().toISOString()
    };

    await db('users')
      .where('id', req.user.id)
      .update({
        reading_progress: JSON.stringify(updatedProgress),
        updated_at: new Date()
      });

    res.json({
      message: 'Reading progress updated successfully',
      progress: updatedProgress
    });
  } catch (error) {
    console.error('Reading progress update error:', error);
    res.status(500).json({
      error: 'Failed to update reading progress'
    });
  }
});

// Change password
router.put('/change-password', auth, [
  body('currentPassword').isLength({ min: 1 }),
  body('newPassword').isLength({ min: 6 }).matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { currentPassword, newPassword } = req.body;

    // Get current user
    const user = await db('users')
      .where('id', req.user.id)
      .select('password_hash')
      .first();

    // Verify current password
    const isValidPassword = await bcrypt.compare(currentPassword, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({
        error: 'Invalid current password'
      });
    }

    // Hash new password
    const saltRounds = 12;
    const newPasswordHash = await bcrypt.hash(newPassword, saltRounds);

    // Update password
    await db('users')
      .where('id', req.user.id)
      .update({
        password_hash: newPasswordHash,
        updated_at: new Date()
      });

    res.json({
      message: 'Password changed successfully'
    });
  } catch (error) {
    console.error('Password change error:', error);
    res.status(500).json({
      error: 'Failed to change password'
    });
  }
});

// Refresh token
router.post('/refresh', auth, async (req, res) => {
  try {
    const user = await db('users')
      .where('id', req.user.id)
      .where('is_active', true)
      .first();

    if (!user) {
      return res.status(401).json({
        error: 'User not found or inactive'
      });
    }

    const token = generateToken(user);

    res.json({
      message: 'Token refreshed successfully',
      token
    });
  } catch (error) {
    console.error('Token refresh error:', error);
    res.status(500).json({
      error: 'Failed to refresh token'
    });
  }
});

// Logout (client-side token removal)
router.post('/logout', auth, (req, res) => {
  // In a JWT-based system, logout is primarily handled client-side
  // This endpoint can be used for logging purposes
  res.json({
    message: 'Logout successful'
  });
});

module.exports = router;