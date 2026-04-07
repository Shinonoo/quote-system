-- Add prefix column to users table for reference number generation
ALTER TABLE users ADD COLUMN IF NOT EXISTS prefix VARCHAR(10) DEFAULT 'GT';

-- Update existing users to have default prefix
UPDATE users SET prefix = 'GT' WHERE prefix IS NULL;
