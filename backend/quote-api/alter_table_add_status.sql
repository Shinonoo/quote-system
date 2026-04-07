-- Add status column to existing quotations table if it doesn't exist
ALTER TABLE quotations 
ADD COLUMN IF NOT EXISTS status ENUM('pending', 'approved', 'rejected', 'expired') DEFAULT 'pending';
