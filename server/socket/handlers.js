const jwt = require('jsonwebtoken');
const db = require('../config/database');

// Store active users and rooms
const activeUsers = new Map();
const activeRooms = new Map();

// Authenticate socket connection
const authenticateSocket = async (socket, token) => {
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'blackthorn-manor-secret');
    const user = await db('users')
      .where('id', decoded.id)
      .where('is_active', true)
      .select('id', 'username', 'first_name', 'last_name', 'role')
      .first();
    
    if (!user) {
      throw new Error('User not found');
    }
    
    return user;
  } catch (error) {
    throw new Error('Authentication failed');
  }
};

// Initialize socket handlers
const initializeHandlers = (socket, io) => {
  // Authentication
  socket.on('authenticate', async (data) => {
    try {
      const { token } = data;
      const user = await authenticateSocket(socket, token);
      
      socket.userId = user.id;
      socket.user = user;
      
      // Add user to active users
      activeUsers.set(socket.id, {
        userId: user.id,
        username: user.username,
        socketId: socket.id,
        connectedAt: new Date()
      });
      
      socket.emit('authenticated', {
        success: true,
        user: {
          id: user.id,
          username: user.username,
          firstName: user.first_name,
          lastName: user.last_name,
          role: user.role
        }
      });
      
      console.log(`User ${user.username} authenticated on socket ${socket.id}`);
    } catch (error) {
      socket.emit('authentication_error', {
        error: error.message
      });
      socket.disconnect();
    }
  });
  
  // Join collaboration room
  socket.on('join_room', async (data) => {
    try {
      if (!socket.userId) {
        socket.emit('error', { message: 'Authentication required' });
        return;
      }
      
      const { roomCode } = data;
      
      // Find room
      const room = await db('collaboration_rooms')
        .where('room_code', roomCode)
        .where('is_active', true)
        .first();
      
      if (!room) {
        socket.emit('error', { message: 'Room not found' });
        return;
      }
      
      // Check if user is participant
      const participant = await db('room_participants')
        .where('room_id', room.id)
        .where('user_id', socket.userId)
        .where('status', 'active')
        .first();
      
      if (!participant && room.room_type === 'private') {
        socket.emit('error', { message: 'Access denied to private room' });
        return;
      }
      
      // Join socket room
      socket.join(`room_${room.id}`);
      socket.currentRoom = room.id;
      
      // Add to active rooms
      if (!activeRooms.has(room.id)) {
        activeRooms.set(room.id, new Set());
      }
      activeRooms.get(room.id).add(socket.id);
      
      // Update participant last active
      if (participant) {
        await db('room_participants')
          .where('id', participant.id)
          .update({ last_active: new Date() });
      }
      
      // Get room participants
      const participants = await db('room_participants')
        .join('users', 'room_participants.user_id', 'users.id')
        .where('room_participants.room_id', room.id)
        .where('room_participants.status', 'active')
        .select(
          'users.id',
          'users.username',
          'users.first_name',
          'users.last_name',
          'room_participants.role'
        );
      
      socket.emit('room_joined', {
        room: {
          id: room.id,
          name: room.name,
          description: room.description,
          roomCode: room.room_code,
          roomType: room.room_type
        },
        participants
      });
      
      // Notify other participants
      socket.to(`room_${room.id}`).emit('user_joined', {
        user: {
          id: socket.user.id,
          username: socket.user.username,
          firstName: socket.user.first_name,
          lastName: socket.user.last_name
        }
      });
      
      console.log(`User ${socket.user.username} joined room ${room.room_code}`);
    } catch (error) {
      console.error('Join room error:', error);
      socket.emit('error', { message: 'Failed to join room' });
    }
  });
  
  // Leave room
  socket.on('leave_room', () => {
    if (socket.currentRoom) {
      socket.leave(`room_${socket.currentRoom}`);
      
      // Remove from active rooms
      if (activeRooms.has(socket.currentRoom)) {
        activeRooms.get(socket.currentRoom).delete(socket.id);
        if (activeRooms.get(socket.currentRoom).size === 0) {
          activeRooms.delete(socket.currentRoom);
        }
      }
      
      // Notify other participants
      socket.to(`room_${socket.currentRoom}`).emit('user_left', {
        user: {
          id: socket.user?.id,
          username: socket.user?.username
        }
      });
      
      socket.currentRoom = null;
    }
  });
  
  // Real-time annotation creation
  socket.on('annotation_created', async (data) => {
    try {
      if (!socket.userId || !socket.currentRoom) {
        socket.emit('error', { message: 'Authentication and room required' });
        return;
      }
      
      const {
        pageIndex,
        content,
        contentType,
        selectedText,
        position,
        styling,
        isPublic
      } = data;
      
      // Create annotation in database
      const [annotationId] = await db('annotations').insert({
        user_id: socket.userId,
        page_index: pageIndex,
        content_type: contentType,
        content,
        selected_text: selectedText,
        position: JSON.stringify(position),
        styling: JSON.stringify(styling),
        is_public: isPublic,
        is_collaborative: true
      });
      
      // Get full annotation with user info
      const annotation = await db('annotations')
        .join('users', 'annotations.user_id', 'users.id')
        .where('annotations.id', annotationId)
        .select(
          'annotations.*',
          'users.username',
          'users.first_name',
          'users.last_name'
        )
        .first();
      
      const annotationData = {
        id: annotation.id,
        pageIndex: annotation.page_index,
        contentType: annotation.content_type,
        content: annotation.content,
        selectedText: annotation.selected_text,
        position: JSON.parse(annotation.position || '{}'),
        styling: JSON.parse(annotation.styling || '{}'),
        isPublic: annotation.is_public,
        isCollaborative: annotation.is_collaborative,
        createdAt: annotation.created_at,
        user: {
          id: annotation.user_id,
          username: annotation.username,
          firstName: annotation.first_name,
          lastName: annotation.last_name
        }
      };
      
      // Broadcast to room
      io.to(`room_${socket.currentRoom}`).emit('annotation_created', annotationData);
      
      console.log(`Annotation created by ${socket.user.username} in room ${socket.currentRoom}`);
    } catch (error) {
      console.error('Annotation creation error:', error);
      socket.emit('error', { message: 'Failed to create annotation' });
    }
  });
  
  // Real-time annotation update
  socket.on('annotation_updated', async (data) => {
    try {
      if (!socket.userId || !socket.currentRoom) {
        socket.emit('error', { message: 'Authentication and room required' });
        return;
      }
      
      const { annotationId, content, position, styling } = data;
      
      // Check if user owns the annotation or has permission
      const annotation = await db('annotations')
        .where('id', annotationId)
        .first();
      
      if (!annotation || (annotation.user_id !== socket.userId && socket.user.role !== 'admin')) {
        socket.emit('error', { message: 'Permission denied' });
        return;
      }
      
      // Update annotation
      const updateData = {
        updated_at: new Date()
      };
      
      if (content !== undefined) updateData.content = content;
      if (position !== undefined) updateData.position = JSON.stringify(position);
      if (styling !== undefined) updateData.styling = JSON.stringify(styling);
      
      await db('annotations')
        .where('id', annotationId)
        .update(updateData);
      
      // Broadcast update to room
      socket.to(`room_${socket.currentRoom}`).emit('annotation_updated', {
        annotationId,
        content,
        position,
        styling,
        updatedAt: updateData.updated_at
      });
      
      console.log(`Annotation ${annotationId} updated by ${socket.user.username}`);
    } catch (error) {
      console.error('Annotation update error:', error);
      socket.emit('error', { message: 'Failed to update annotation' });
    }
  });
  
  // Real-time annotation deletion
  socket.on('annotation_deleted', async (data) => {
    try {
      if (!socket.userId || !socket.currentRoom) {
        socket.emit('error', { message: 'Authentication and room required' });
        return;
      }
      
      const { annotationId } = data;
      
      // Check if user owns the annotation or has permission
      const annotation = await db('annotations')
        .where('id', annotationId)
        .first();
      
      if (!annotation || (annotation.user_id !== socket.userId && socket.user.role !== 'admin')) {
        socket.emit('error', { message: 'Permission denied' });
        return;
      }
      
      // Delete annotation
      await db('annotations')
        .where('id', annotationId)
        .del();
      
      // Broadcast deletion to room
      io.to(`room_${socket.currentRoom}`).emit('annotation_deleted', { annotationId });
      
      console.log(`Annotation ${annotationId} deleted by ${socket.user.username}`);
    } catch (error) {
      console.error('Annotation deletion error:', error);
      socket.emit('error', { message: 'Failed to delete annotation' });
    }
  });
  
  // Real-time page navigation
  socket.on('page_changed', (data) => {
    if (!socket.currentRoom) return;
    
    const { pageIndex, timestamp } = data;
    
    // Broadcast page change to room
    socket.to(`room_${socket.currentRoom}`).emit('user_page_changed', {
      user: {
        id: socket.user?.id,
        username: socket.user?.username
      },
      pageIndex,
      timestamp
    });
  });
  
  // Typing indicators for annotations
  socket.on('typing_start', (data) => {
    if (!socket.currentRoom) return;
    
    const { pageIndex, annotationId } = data;
    
    socket.to(`room_${socket.currentRoom}`).emit('user_typing', {
      user: {
        id: socket.user?.id,
        username: socket.user?.username
      },
      pageIndex,
      annotationId,
      typing: true
    });
  });
  
  socket.on('typing_stop', (data) => {
    if (!socket.currentRoom) return;
    
    const { pageIndex, annotationId } = data;
    
    socket.to(`room_${socket.currentRoom}`).emit('user_typing', {
      user: {
        id: socket.user?.id,
        username: socket.user?.username
      },
      pageIndex,
      annotationId,
      typing: false
    });
  });
  
  // Chat messages in collaboration rooms
  socket.on('chat_message', async (data) => {
    try {
      if (!socket.userId || !socket.currentRoom) {
        socket.emit('error', { message: 'Authentication and room required' });
        return;
      }
      
      const { message, messageType = 'text' } = data;
      
      const chatMessage = {
        id: Date.now(), // Simple ID for real-time messages
        user: {
          id: socket.user.id,
          username: socket.user.username,
          firstName: socket.user.first_name,
          lastName: socket.user.last_name
        },
        message,
        messageType,
        timestamp: new Date().toISOString()
      };
      
      // Broadcast to room
      io.to(`room_${socket.currentRoom}`).emit('chat_message', chatMessage);
      
      console.log(`Chat message from ${socket.user.username} in room ${socket.currentRoom}`);
    } catch (error) {
      console.error('Chat message error:', error);
      socket.emit('error', { message: 'Failed to send message' });
    }
  });
  
  // Get room status
  socket.on('get_room_status', () => {
    if (!socket.currentRoom) {
      socket.emit('room_status', { participants: [] });
      return;
    }
    
    const roomParticipants = [];
    const activeSocketsInRoom = activeRooms.get(socket.currentRoom) || new Set();
    
    for (const socketId of activeSocketsInRoom) {
      const user = activeUsers.get(socketId);
      if (user) {
        roomParticipants.push({
          userId: user.userId,
          username: user.username,
          connectedAt: user.connectedAt
        });
      }
    }
    
    socket.emit('room_status', {
      participants: roomParticipants,
      totalActive: roomParticipants.length
    });
  });
  
  // Handle disconnection
  socket.on('disconnect', () => {
    // Remove from active users
    activeUsers.delete(socket.id);
    
    // Remove from active rooms
    if (socket.currentRoom && activeRooms.has(socket.currentRoom)) {
      activeRooms.get(socket.currentRoom).delete(socket.id);
      if (activeRooms.get(socket.currentRoom).size === 0) {
        activeRooms.delete(socket.currentRoom);
      }
      
      // Notify room participants
      socket.to(`room_${socket.currentRoom}`).emit('user_left', {
        user: {
          id: socket.user?.id,
          username: socket.user?.username
        }
      });
    }
    
    console.log(`User ${socket.user?.username || 'unknown'} disconnected from socket ${socket.id}`);
  });
};

module.exports = {
  initializeHandlers,
  activeUsers,
  activeRooms
};