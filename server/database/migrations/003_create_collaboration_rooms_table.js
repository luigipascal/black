/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('collaboration_rooms', (table) => {
    table.increments('id').primary();
    table.string('name').notNullable();
    table.text('description').nullable();
    table.string('room_code').unique().notNullable(); // 6-character code for joining
    table.integer('owner_id').unsigned().references('id').inTable('users').onDelete('CASCADE');
    table.enum('room_type', ['public', 'private', 'invitation_only']).defaultTo('private');
    table.integer('max_participants').defaultTo(10);
    table.boolean('is_active').defaultTo(true);
    table.json('settings').nullable(); // room-specific settings
    table.json('investigation_focus').nullable(); // specific characters or mysteries
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    
    // Indexes
    table.index(['owner_id']);
    table.index(['room_code']);
    table.index(['room_type']);
    table.index(['is_active']);
    table.index(['created_at']);
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTable('collaboration_rooms');
};