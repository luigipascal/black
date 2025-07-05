/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.createTable('annotations', (table) => {
    table.increments('id').primary();
    table.integer('user_id').unsigned().references('id').inTable('users').onDelete('CASCADE');
    table.integer('page_index').notNullable();
    table.string('content_type').notNullable(); // 'text', 'highlight', 'note', 'bookmark'
    table.text('content').notNullable();
    table.text('selected_text').nullable();
    table.json('position').nullable(); // x, y coordinates and dimensions
    table.json('styling').nullable(); // color, font, size, etc.
    table.string('character_initials').nullable(); // MB, JR, EW, etc.
    table.enum('annotation_type', ['fixed', 'draggable']).defaultTo('draggable');
    table.integer('revelation_level').defaultTo(1);
    table.boolean('is_public').defaultTo(false);
    table.boolean('is_collaborative').defaultTo(false);
    table.json('metadata').nullable();
    table.integer('parent_id').unsigned().references('id').inTable('annotations').onDelete('CASCADE');
    table.integer('thread_id').unsigned().nullable();
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    
    // Indexes
    table.index(['user_id']);
    table.index(['page_index']);
    table.index(['content_type']);
    table.index(['character_initials']);
    table.index(['annotation_type']);
    table.index(['revelation_level']);
    table.index(['is_public']);
    table.index(['is_collaborative']);
    table.index(['parent_id']);
    table.index(['thread_id']);
    table.index(['created_at']);
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTable('annotations');
};