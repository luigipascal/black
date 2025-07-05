/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('room_participants', (table) => {
    table.increments('id').primary();
    table.integer('room_id').unsigned().references('id').inTable('collaboration_rooms').onDelete('CASCADE');
    table.integer('user_id').unsigned().references('id').inTable('users').onDelete('CASCADE');
    table.enum('role', ['participant', 'moderator', 'owner']).defaultTo('participant');
    table.enum('status', ['active', 'invited', 'left', 'banned']).defaultTo('active');
    table.timestamp('joined_at').defaultTo(knex.fn.now());
    table.timestamp('last_active').defaultTo(knex.fn.now());
    table.json('permissions').nullable();
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    
    // Composite unique constraint - one user per room
    table.unique(['room_id', 'user_id']);
    
    // Indexes
    table.index(['room_id']);
    table.index(['user_id']);
    table.index(['role']);
    table.index(['status']);
    table.index(['joined_at']);
    table.index(['last_active']);
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTable('room_participants');
};