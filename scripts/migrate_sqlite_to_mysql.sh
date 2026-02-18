#!/bin/bash
# Migration script: SQLite to MySQL
# This script exports data from SQLite and imports it into MySQL
#
# Usage:
#   ./scripts/migrate_sqlite_to_mysql.sh [options]
#
# Options:
#   -s, --sqlite-db PATH    Path to SQLite database (default: storage/production.sqlite3)
#   -h, --mysql-host HOST   MySQL host (default: 127.0.0.1)
#   -P, --mysql-port PORT   MySQL port (default: 3306)
#   -u, --mysql-user USER   MySQL user (default: root)
#   -p, --mysql-pass PASS   MySQL password (required)
#   -d, --mysql-db DB       MySQL database name (default: fizzy_production)
#   --dry-run               Show what would be done without executing
#   --help                  Show this help message

set -e

# Default values
SQLITE_DB="storage/production.sqlite3"
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="3306"
MYSQL_USER="root"
MYSQL_PASS=""
MYSQL_DB="fizzy_production"
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -s|--sqlite-db)
      SQLITE_DB="$2"
      shift 2
      ;;
    -h|--mysql-host)
      MYSQL_HOST="$2"
      shift 2
      ;;
    -P|--mysql-port)
      MYSQL_PORT="$2"
      shift 2
      ;;
    -u|--mysql-user)
      MYSQL_USER="$2"
      shift 2
      ;;
    -p|--mysql-pass)
      MYSQL_PASS="$2"
      shift 2
      ;;
    -d|--mysql-db)
      MYSQL_DB="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help)
      head -30 "$0" | tail -28 | sed 's/^# //'
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [[ -z "$MYSQL_PASS" ]]; then
  echo "Error: MySQL password is required. Use -p or --mysql-pass"
  exit 1
fi

if [[ ! -f "$SQLITE_DB" ]]; then
  echo "Error: SQLite database not found at $SQLITE_DB"
  exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# MySQL connection command
MYSQL_CMD="mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASS"

# Check MySQL connection
log_info "Testing MySQL connection..."
if ! $MYSQL_CMD -e "SELECT 1;" &>/dev/null; then
  log_error "Failed to connect to MySQL. Please check your credentials."
  exit 1
fi
log_info "MySQL connection successful."

# Get list of tables from SQLite
log_info "Getting table list from SQLite..."
TABLES=$(sqlite3 "$SQLITE_DB" "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'schema_%' AND name NOT LIKE 'ar_%';")
log_info "Found tables: $TABLES"

if $DRY_RUN; then
  log_warn "DRY RUN MODE - No changes will be made"
fi

# Export and import each table
for TABLE in $TABLES; do
  log_info "Processing table: $TABLE"
  
  # Get column names
  COLUMNS=$(sqlite3 -csv "$SQLITE_DB" ".schema $TABLE" | grep -oP '(?<=\().*(?=\))' | head -1 | tr -d '\n')
  
  # Export data from SQLite to CSV
  TEMP_CSV="/tmp/${TABLE}_export.csv"
  sqlite3 -csv -header "$SQLITE_DB" "SELECT * FROM $TABLE;" > "$TEMP_CSV"
  
  ROW_COUNT=$(wc -l < "$TEMP_CSV")
  log_info "Exported $((ROW_COUNT - 1)) rows from $TABLE"
  
  if [[ $ROW_COUNT -le 1 ]]; then
    log_info "Table $TABLE is empty, skipping..."
    rm -f "$TEMP_CSV"
    continue
  fi
  
  if $DRY_RUN; then
    log_info "[DRY RUN] Would import $((ROW_COUNT - 1)) rows into $TABLE"
    rm -f "$TEMP_CSV"
    continue
  fi
  
  # Disable foreign key checks temporarily
  $MYSQL_CMD "$MYSQL_DB" -e "SET FOREIGN_KEY_CHECKS=0; SET UNIQUE_CHECKS=0; SET AUTOCOMMIT=0;"
  
  # Import data into MySQL
  # Note: This uses LOAD DATA LOCAL INFILE which requires mysql client to have local-infile enabled
  $MYSQL_CMD --local-infile=1 "$MYSQL_DB" <<EOF
SET FOREIGN_KEY_CHECKS=0;
SET UNIQUE_CHECKS=0;
SET AUTOCOMMIT=0;
LOAD DATA LOCAL INFILE '$TEMP_CSV'
INTO TABLE $TABLE
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
COMMIT;
SET FOREIGN_KEY_CHECKS=1;
SET UNIQUE_CHECKS=1;
EOF
  
  if [[ $? -eq 0 ]]; then
    log_info "Successfully imported data into $TABLE"
  else
    log_error "Failed to import data into $TABLE"
  fi
  
  rm -f "$TEMP_CSV"
done

# Re-enable foreign key checks
if ! $DRY_RUN; then
  $MYSQL_CMD "$MYSQL_DB" -e "SET FOREIGN_KEY_CHECKS=1; SET UNIQUE_CHECKS=1;"
fi

log_info "Migration completed!"
log_info "Please verify your data before using the MySQL database in production."
