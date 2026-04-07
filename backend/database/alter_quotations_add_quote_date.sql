-- Add quote_date column to quotations table
ALTER TABLE quotations ADD COLUMN IF NOT EXISTS quote_date DATE;

-- Set quote_date to created_at date for existing records
UPDATE quotations SET quote_date = DATE(created_at) WHERE quote_date IS NULL;
