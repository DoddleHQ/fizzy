#!/usr/bin/env ruby
# frozen_string_literal: true

# Migration script: SQLite to MySQL using ActiveRecord
# This script provides a more robust migration using Rails/ActiveRecord
#
# Usage:
#   DATABASE_ADAPTER=mysql bundle exec rails runner scripts/migrate_sqlite_to_mysql.rb
#
# Environment variables:
#   SOURCE_SQLITE_PATH  - Path to source SQLite database (default: storage/production.sqlite3)
#   BATCH_SIZE          - Number of records to process per batch (default: 1000)
#   DRY_RUN             - Set to 'true' to preview without making changes

require "sqlite3"
require "json"

class SqliteToMysqlMigrator
  BATCH_SIZE = (ENV["BATCH_SIZE"] || 1000).to_i
  DRY_RUN = ENV["DRY_RUN"] == "true"
  SOURCE_PATH = ENV["SOURCE_SQLITE_PATH"] || "storage/production.sqlite3"

  # Tables to migrate in order (respecting foreign key dependencies)
  # Add or remove tables based on your specific needs
  TABLE_ORDER = %w[
    account_external_id_sequences
    accounts
    identities
    users
    account_join_codes
    account_cancellations
    boards
    columns
    tags
    cards
    card_tags
    comments
    events
    accesses
    attachments
    action_text_rich_texts
    active_storage_blobs
    active_storage_attachments
    notifications
    notification_identities
    search_records
    webhooks
    account_exports
    account_imports
  ].freeze

  # Tables to skip (e.g., schema tables, cache tables)
  SKIP_TABLES = %w[
    schema_migrations
    ar_internal_metadata
    solid_queue_jobs
    solid_queue_recurring_tasks
    solid_queue_scheduled_executions
    solid_queue_processes
    solid_queue_pauses
  ].freeze

  attr_reader :source_db, :stats

  def initialize
    @stats = Hash.new(0)
    validate_source_db!
  end

  def migrate!
    log "Starting migration from SQLite to MySQL..."
    log "Source: #{SOURCE_PATH}"
    log "Dry run: #{DRY_RUN}"
    log "=" * 60

    connect_source_db
    disable_mysql_constraints

    tables_to_migrate.each do |table_name|
      migrate_table(table_name)
    end

    enable_mysql_constraints
    print_summary
  rescue StandardError => e
    log_error "Migration failed: #{e.message}"
    log_error e.backtrace.first(10).join("\n")
    enable_mysql_constraints
    raise
  ensure
    disconnect_source_db
  end

  private

  def validate_source_db!
    unless File.exist?(SOURCE_PATH)
      raise "Source SQLite database not found at: #{SOURCE_PATH}"
    end
  end

  def connect_source_db
    @source_db = SQLite3::Database.new SOURCE_PATH
    @source_db.results_as_hash = true
    log "Connected to SQLite database"
  end

  def disconnect_source_db
    @source_db&.close
  end

  def tables_to_migrate
    all_tables = @source_db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").flatten
    
    # Filter out skipped tables and order by dependencies
    (TABLE_ORDER & all_tables) + (all_tables - TABLE_ORDER - SKIP_TABLES)
  end

  def migrate_table(table_name)
    log "\n--- Migrating table: #{table_name} ---"
    
    # Get row count
    count_result = @source_db.execute("SELECT COUNT(*) as count FROM #{table_name}").first
    total_rows = count_result["count"]
    
    if total_rows.zero?
      log "  Table is empty, skipping..."
      return
    end
    
    log "  Found #{total_rows} rows to migrate"
    
    # Get column names
    columns = get_columns(table_name)
    log "  Columns: #{columns.join(', ')}"
    
    if DRY_RUN
      log "  [DRY RUN] Would migrate #{total_rows} rows"
      @stats[table_name] = total_rows
      return
    end
    
    # Migrate in batches
    migrated = 0
    offset = 0
    
    while offset < total_rows
      batch = @source_db.execute("SELECT * FROM #{table_name} LIMIT #{BATCH_SIZE} OFFSET #{offset}")
      
      batch.each do |row|
        insert_record(table_name, columns, row)
        migrated += 1
      end
      
      offset += BATCH_SIZE
      progress = [(migrated.to_f / total_rows * 100).round(1), 100].min
      log "  Progress: #{migrated}/#{total_rows} (#{progress}%)"
    end
    
    @stats[table_name] = migrated
    log "  Migrated #{migrated} rows"
  end

  def get_columns(table_name)
    schema = @source_db.execute("SELECT sql FROM sqlite_master WHERE name='#{table_name}'").first["sql"]
    
    # Extract column names from CREATE TABLE statement
    match = schema.match(/\((.+)\)/m)
    return [] unless match
    
    match[1].split(",").map do |col_def|
      col_def.strip.split.first.gsub(/["']/, "")
    end.reject { |c| c =~ /^(PRIMARY|FOREIGN|UNIQUE|CHECK|CONSTRAINT)/i }
  end

  def insert_record(table_name, columns, row)
    # Convert SQLite row to MySQL-compatible values
    values = columns.map do |col|
      val = row[col]
      convert_value(val)
    end
    
    placeholders = columns.map { "?" }.join(", ")
    quoted_columns = columns.map { |c| "`#{c}`" }.join(", ")
    
    sql = "INSERT INTO #{table_name} (#{quoted_columns}) VALUES (#{placeholders})"
    
    begin
      ActiveRecord::Base.connection.execute(sql, values)
    rescue ActiveRecord::RecordNotUnique => e
      # Skip duplicate records (e.g., from failed previous migration)
      log "  Skipping duplicate record in #{table_name}"
    rescue StandardError => e
      log "  Error inserting record into #{table_name}: #{e.message}"
    end
  end

  def convert_value(value)
    return nil if value.nil?
    
    case value
    when String
      # Handle boolean strings
      return 1 if value.downcase == "true"
      return 0 if value.downcase == "false"
      value
    when Integer, Float
      value
    when Time, DateTime
      value.strftime("%Y-%m-%d %H:%M:%S")
    else
      value.to_s
    end
  end

  def disable_mysql_constraints
    return if DRY_RUN
    
    ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=0")
    ActiveRecord::Base.connection.execute("SET UNIQUE_CHECKS=0")
    ActiveRecord::Base.connection.execute("SET AUTOCOMMIT=0")
    log "Disabled MySQL constraints"
  end

  def enable_mysql_constraints
    return if DRY_RUN
    
    ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=1")
    ActiveRecord::Base.connection.execute("SET UNIQUE_CHECKS=1")
    ActiveRecord::Base.connection.execute("COMMIT")
    log "Re-enabled MySQL constraints"
  end

  def print_summary
    log "\n" + "=" * 60
    log "MIGRATION SUMMARY"
    log "=" * 60
    
    total = 0
    @stats.each do |table, count|
      log "  #{table}: #{count} records"
      total += count
    end
    
    log "-" * 60
    log "  Total records migrated: #{total}"
    log "=" * 60
    
    if DRY_RUN
      log "\nThis was a DRY RUN. No data was actually migrated."
      log "To perform the actual migration, run without DRY_RUN=true"
    end
  end

  def log(message)
    puts "[#{Time.current.strftime('%H:%M:%S')}] #{message}"
  end

  def log_error(message)
    puts "\e[31m[ERROR] #{message}\e[0m"
  end
end

# Run the migration
SqliteToMysqlMigrator.new.migrate!
