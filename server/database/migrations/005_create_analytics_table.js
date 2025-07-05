/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('analytics', (table) => {
    table.increments('id').primary();
    table.integer('user_id').unsigned().references('id').inTable('users').onDelete('CASCADE');
    table.string('session_id').notNullable();
    table.string('event_type').notNullable(); // 'page_view', 'annotation_create', 'search', 'bookmark', etc.
    table.json('event_data').nullable(); // flexible data storage
    table.integer('page_index').nullable();
    table.string('character_initials').nullable();
    table.integer('revelation_level').nullable();
    table.integer('duration_seconds').nullable();
    table.timestamp('timestamp').defaultTo(knex.fn.now());
    table.string('ip_address').nullable();
    table.string('user_agent').nullable();
    table.json('metadata').nullable();
    
    // Indexes
    table.index(['user_id']);
    table.index(['session_id']);
    table.index(['event_type']);
    table.index(['page_index']);
    table.index(['character_initials']);
    table.index(['revelation_level']);
    table.index(['timestamp']);
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTable('analytics');
};